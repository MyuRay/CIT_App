import 'dart:convert';
import 'package:cit_app/models/weather/campus_weather.dart';
import 'package:cit_app/services/weather/campus_weather_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Japan time is UTC + 9, regardless of the device's timezone.
DateTime japan(int hour, [int minute = 0]) =>
    DateTime.utc(2026, 9, 12, hour - 9, minute);

CampusWeather forecast({
  WeatherCondition current = WeatherCondition.rain,
  List<double?> amounts = const [1, 1, 0, 0, 2, 0],
  DateTime? now,
  int? probability,
}) {
  now ??= japan(12, 15);
  final firstEnd = DateTime.utc(now.year, now.month, now.day, now.hour + 1);
  return CampusWeather(
    asOf: now,
    fetchedAt: now,
    condition: current,
    temperature: 24,
    hours: [
      for (var i = 0; i < amounts.length; i++)
        WeatherHour(
          endsAt: firstEnd.add(Duration(hours: i)),
          precipitation: amounts[i],
          probability: probability,
          code:
              amounts[i] == null
                  ? null
                  : amounts[i]! > 0
                  ? 63
                  : 3,
        ),
    ],
  );
}

void main() {
  test('rain ends at the start of the first dry interval, and can restart', () {
    final result = RainOutlook.forWeather(forecast(), japan(12, 15));
    expect(result.headline, '14時ごろに雨がやむ見込み');
    expect(result.detail, contains('16時ごろから再び雨'));
  });

  test('rain starts at interval start, not one hour late', () {
    final result = RainOutlook.forWeather(
      forecast(current: WeatherCondition.cloudy, amounts: [0, 0, 1, 1, 0]),
      japan(12, 15),
    );
    expect(result.headline, '14時ごろから雨の見込み');
    expect(result.detail, contains('16時ごろにやむ'));
  });

  test('a transition within the current hour does not promise a past time', () {
    final result = RainOutlook.forWeather(
      forecast(amounts: [0, 0]),
      japan(12, 15),
    );
    expect(result.headline, 'まもなく雨がやむ見込み');
  });

  test('forecast continues across midnight with tomorrow labels', () {
    final result = RainOutlook.forWeather(
      forecast(
        current: WeatherCondition.clear,
        now: japan(23, 30),
        amounts: [0, 1, 0],
      ),
      japan(23, 30),
    );
    expect(result.headline, '明日0時ごろから雨の見込み');
    expect(result.detail, contains('明日1時ごろにやむ'));
  });

  test(
    'no rain is bounded by available data, not asserted for the whole day',
    () {
      final result = RainOutlook.forWeather(
        forecast(current: WeatherCondition.clear, amounts: [0, 0, 0]),
        japan(12, 15),
      );
      expect(result.headline, '15時ごろまで雨の予報なし');
      expect(result.bringUmbrella, isFalse);
    },
  );

  test('continuous rain never invents an end beyond available data', () {
    final result = RainOutlook.forWeather(
      forecast(amounts: [1, 1, 1]),
      japan(12, 15),
    );
    expect(result.headline, '15時ごろまで雨が続く見込み');
    expect(result.detail, contains('まだ分かりません'));
  });

  test('missing rain values do not become zero or predict a stop', () {
    final result = RainOutlook.forWeather(
      forecast(amounts: [1, null, 0]),
      japan(12, 15),
    );
    expect(result.headline, '13時ごろまで雨が続く見込み');
    expect(result.detail, contains('まだ分かりません'));
    expect(WeatherHour(endsAt: japan(13), code: 3).isWet, isNull);
  });

  test(
    'probability alone warns of a chance, without claiming rain is certain',
    () {
      final result = RainOutlook.forWeather(
        forecast(
          current: WeatherCondition.cloudy,
          amounts: [0, 0, 0],
          probability: 60,
        ),
        japan(12, 15),
      );
      expect(result.headline, contains('可能性'));
      expect(result.detail, contains('60%'));
      expect(result.bringUmbrella, isTrue);
    },
  );

  test(
    'drizzle is not lost to the former 0.3 mm threshold; snow is distinct',
    () {
      expect(weatherCondition(51, 0.01), WeatherCondition.drizzle);
      expect(weatherCondition(3, 0.05).isWet, isTrue);
      expect(weatherCondition(85, 1), WeatherCondition.snow);
      expect(weatherCondition(99, 1), WeatherCondition.thunderstorm);
      expect(weatherCondition(null, null), WeatherCondition.unknown);
    },
  );

  test('old current data does not claim to describe now', () {
    final result = RainOutlook.forWeather(forecast(), japan(13, 15));
    expect(result.headline, '最新の雨の状況を確認してください');
    expect(result.detail, contains('古い予報'));
  });

  test('missing hours do not allow a dry conclusion across a gap', () {
    final source = forecast(
      amounts: [0, 0, 1],
      current: WeatherCondition.clear,
    );
    final weather = CampusWeather(
      asOf: source.asOf,
      fetchedAt: source.fetchedAt,
      condition: source.condition,
      temperature: 24,
      hours: [source.hours[0], source.hours[2]],
    );
    expect(
      RainOutlook.forWeather(weather, japan(12, 15)).headline,
      '13時ごろまで雨の予報なし',
    );
  });

  test(
    'API uses UTC timestamps, three days, probability, and safe partial arrays',
    () async {
      final now = japan(12, 15);
      final client = MockClient((request) async {
        expect(request.url.queryParameters['forecast_days'], '3');
        expect(request.url.queryParameters['timeformat'], 'unixtime');
        expect(request.url.queryParameters['wind_speed_unit'], 'ms');
        expect(
          request.url.queryParameters['hourly'],
          contains('precipitation_probability'),
        );
        expect(request.url.queryParameters['latitude'], '35.669');
        return http.Response(
          jsonEncode({
            'current': {
              'time': now.millisecondsSinceEpoch ~/ 1000,
              'temperature_2m': 24,
              'weather_code': 51,
              'precipitation': 0.01,
              'relative_humidity_2m': 80,
              'wind_speed_10m': 2,
            },
            'hourly': {
              'time': [
                japan(13).millisecondsSinceEpoch ~/ 1000,
                japan(14).millisecondsSinceEpoch ~/ 1000,
              ],
              'precipitation': [0.2],
              'precipitation_probability': [null, 60],
              'weather_code': [51],
            },
            'daily': {
              'time': [],
              'temperature_2m_max': [],
              'temperature_2m_min': [],
            },
          }),
          200,
        );
      });
      final result = await CampusWeatherService(
        client: client,
        now: () => now,
      ).fetch('narashino');
      expect(result.condition, WeatherCondition.drizzle);
      expect(result.asOf, now);
      expect(result.hours[0].startsAt, japan(12));
      expect(result.hours[0].probability, isNull);
      expect(result.hours[1].precipitation, isNull);
      expect(result.maxTemp, isNull);
      expect(
        weatherTimeLabel(
          now,
          DateTime.parse('2026-09-12T04:00:00Z'),
          minutes: true,
        ),
        '12:15',
      );
    },
  );

  test('endpoint weather code does not shift the precipitation interval', () {
    expect(
      WeatherHour(endsAt: japan(13), code: 61, precipitation: 0).isWet,
      isFalse,
    );
    expect(WeatherHour(endsAt: japan(13), code: 61).isWet, isNull);
  });

  test(
    'empty current data and failed HTTP requests are surfaced for retry',
    () async {
      final client = MockClient((_) async => http.Response('{}', 503));
      await expectLater(
        CampusWeatherService(client: client).fetch('tsudanuma'),
        throwsA(isA<http.ClientException>()),
      );
      expect(
        () => CampusWeather.fromJson({'current': {}}, japan(12)),
        throwsFormatException,
      );
    },
  );
}
