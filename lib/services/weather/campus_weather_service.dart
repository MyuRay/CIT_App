import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/weather/campus_weather.dart';
import '../../core/utils/logger.dart';

class WeatherHttpException extends http.ClientException {
  WeatherHttpException(this.statusCode, Uri uri, {this.retryAfter})
    : super('Weather HTTP $statusCode', uri);

  final int statusCode;
  final Duration? retryAfter;
  bool get isTransient =>
      statusCode == 408 || (statusCode >= 500 && statusCode < 600);
}

class CampusWeatherService {
  CampusWeatherService({
    http.Client? client,
    DateTime Function()? now,
    Duration requestTimeout = const Duration(seconds: 15),
    Duration retryDelay = const Duration(seconds: 1),
  }) : _client = client,
       _now = now ?? DateTime.now,
       _requestTimeout = requestTimeout,
       _retryDelay = retryDelay;
  final http.Client? _client;
  final DateTime Function() _now;
  final Duration _requestTimeout;
  final Duration _retryDelay;
  DateTime? _rateLimitUntil;
  WeatherHttpException? _rateLimitError;

  Future<CampusWeather> fetch(String campusKey) async {
    final campus = WeatherCampus.locations[campusKey];
    if (campus == null) throw ArgumentError.value(campusKey, 'campusKey');
    final blockedUntil = _rateLimitUntil;
    if (blockedUntil != null && _now().toUtc().isBefore(blockedUntil)) {
      throw _rateLimitError!;
    }
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '${campus.latitude}', 'longitude': '${campus.longitude}',
      // Best Match also supplies ensemble-based precipitation probability.
      'current':
          'temperature_2m,apparent_temperature,relative_humidity_2m,'
          'is_day,weather_code,precipitation,wind_speed_10m',
      'hourly':
          'temperature_2m,weather_code,precipitation,'
          'precipitation_probability,is_day,wind_speed_10m',
      'daily': 'temperature_2m_max,temperature_2m_min',
      'timezone': 'Asia/Tokyo', 'timeformat': 'unixtime',
      'wind_speed_unit': 'ms', 'forecast_days': '3',
    });
    // Retry one transient failure. Never repeat invalid requests, bad data or a
    // rate-limited request. Each owned client is closed even after a timeout,
    // so an abandoned DNS/TLS connection cannot accumulate across refreshes.
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await _fetchAttempt(campusKey, uri);
      } on WeatherHttpException catch (error) {
        if (error.statusCode == 429) {
          _rateLimitError = error;
          _rateLimitUntil = _now().toUtc().add(error.retryAfter!);
        }
        if (!error.isTransient || attempt == 1) rethrow;
      } on TimeoutException {
        if (attempt == 1) rethrow;
      } on http.ClientException {
        if (attempt == 1) rethrow;
      }
      await Future<void>.delayed(_retryDelay);
      SecureLogger.debug(
        'Weather retry ($campusKey): attempt ${attempt + 2}/2',
      );
    }
    throw StateError('Weather retry loop ended without a result');
  }

  Future<CampusWeather> _fetchAttempt(String campusKey, Uri uri) async {
    final client = _client ?? http.Client();
    late http.Response response;
    try {
      response = await client.get(uri).timeout(_requestTimeout);
    } finally {
      if (_client == null) client.close();
    }
    if (response.statusCode != 200) {
      final retrySeconds = int.tryParse(response.headers['retry-after'] ?? '');
      throw WeatherHttpException(
        response.statusCode,
        uri,
        retryAfter:
            response.statusCode == 429
                ? Duration(
                  seconds:
                      retrySeconds != null && retrySeconds > 0
                          ? retrySeconds
                          : 60,
                )
                : null,
      );
    }
    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid weather response');
    }
    final fetchedAt = _now().toUtc();
    final weather = CampusWeather.fromJson(json, fetchedAt);
    unawaited(_saveCache(campusKey, json, fetchedAt));
    SecureLogger.debug('Weather updated ($campusKey)');
    return weather;
  }

  String _cacheKey(String campusKey) => 'campus_weather_v2_$campusKey';

  Future<void> _saveCache(
    String campusKey,
    Map<String, dynamic> json,
    DateTime fetchedAt,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey(campusKey),
        jsonEncode({
          'forecast': json,
          'fetchedAt': fetchedAt.toIso8601String(),
        }),
      );
    } catch (_) {
      /* A cache failure must not discard a valid forecast. */
    }
  }

  Future<CampusWeather?> readCached(String campusKey) async {
    if (!WeatherCampus.locations.containsKey(campusKey)) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey(campusKey));
      if (raw == null) return null;
      final cached = jsonDecode(raw);
      if (cached is! Map ||
          cached['forecast'] is! Map<String, dynamic> ||
          cached['fetchedAt'] is! String) {
        return null;
      }
      final fetchedAt = DateTime.parse(cached['fetchedAt']).toUtc();
      final age = _now().toUtc().difference(fetchedAt);
      if (age.isNegative || age > const Duration(hours: 24)) return null;
      return CampusWeather.fromJson(cached['forecast'], fetchedAt);
    } catch (_) {
      return null;
    }
  }
}
