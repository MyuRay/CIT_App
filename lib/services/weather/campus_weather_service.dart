import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/weather/campus_weather.dart';

class CampusWeatherService {
  CampusWeatherService({http.Client? client, DateTime Function()? now})
    : _client = client,
      _now = now ?? DateTime.now;
  final http.Client? _client;
  final DateTime Function() _now;

  Future<CampusWeather> fetch(String campusKey) async {
    final campus = WeatherCampus.locations[campusKey];
    if (campus == null) throw ArgumentError.value(campusKey, 'campusKey');
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '${campus.latitude}', 'longitude': '${campus.longitude}',
      // Best Match also supplies ensemble-based precipitation probability.
      'current':
          'temperature_2m,apparent_temperature,relative_humidity_2m,'
          'is_day,weather_code,precipitation,wind_speed_10m',
      'hourly':
          'temperature_2m,weather_code,precipitation,'
          'precipitation_probability,is_day',
      'daily': 'temperature_2m_max,temperature_2m_min',
      'timezone': 'Asia/Tokyo', 'timeformat': 'unixtime',
      'wind_speed_unit': 'ms', 'forecast_days': '3',
    });
    final response = await (_client?.get(uri) ?? http.get(uri)).timeout(
      const Duration(seconds: 10),
    );
    if (response.statusCode != 200) {
      throw http.ClientException('Weather HTTP ${response.statusCode}', uri);
    }
    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid weather response');
    }
    return CampusWeather.fromJson(json, _now().toUtc());
  }
}
