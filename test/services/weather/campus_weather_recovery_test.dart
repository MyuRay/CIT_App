import 'dart:async';
import 'dart:convert';

import 'package:cit_app/services/weather/campus_weather_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response forecast(DateTime now, {int temperature = 24}) => http.Response(
  jsonEncode({
    'current': {
      'time': now.millisecondsSinceEpoch ~/ 1000,
      'temperature_2m': temperature,
    },
    'hourly': {'time': []},
  }),
  200,
);

class TrackedClient extends MockClient {
  TrackedClient(super.handler);
  bool closed = false;
  @override
  void close() {
    closed = true;
    super.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 11, 14, 10);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final failure in ['timeout', 'network', 'server']) {
    test(
      'recovers from one $failure without showing a failed update',
      () async {
        var calls = 0;
        final service = CampusWeatherService(
          now: () => now,
          retryDelay: Duration.zero,
          client: MockClient((request) async {
            if (calls++ == 0) {
              if (failure == 'timeout') throw TimeoutException('slow network');
              if (failure == 'network') {
                throw http.ClientException('connection reset');
              }
              return http.Response('{}', 503);
            }
            return forecast(now);
          }),
        );
        final weather = await service.fetch('tsudanuma');
        expect(calls, 2);
        expect(weather.temperature, 24);
        expect(weather.fetchedAt, now);
      },
    );
  }

  test('a persistent timeout stops after two attempts', () async {
    var calls = 0;
    final service = CampusWeatherService(
      retryDelay: Duration.zero,
      client: MockClient((_) async {
        calls++;
        throw TimeoutException('offline');
      }),
    );
    await expectLater(
      service.fetch('tsudanuma'),
      throwsA(isA<TimeoutException>()),
    );
    expect(calls, 2);
  });

  test(
    'timed-out owned clients close; late data cannot overwrite recovered weather',
    () async {
      final first = Completer<http.Response>();
      final clients = <TrackedClient>[];
      await http.runWithClient(
        () async {
          final service = CampusWeatherService(
            now: () => now,
            requestTimeout: const Duration(milliseconds: 20),
            retryDelay: Duration.zero,
          );
          final weather = await service.fetch('tsudanuma');
          expect(weather.temperature, 24);
          expect(clients, hasLength(2));
          expect(clients.every((client) => client.closed), isTrue);
          first.complete(forecast(now, temperature: 99));
          await Future<void>.delayed(Duration.zero);
          expect((await service.readCached('tsudanuma'))?.temperature, 24);
        },
        () {
          final client = TrackedClient(
            (_) =>
                clients.length == 1
                    ? first.future
                    : Future.value(forecast(now)),
          );
          clients.add(client);
          return client;
        },
      );
    },
  );

  test('a caller-owned client remains usable after fetching weather', () async {
    final client = TrackedClient((_) async => forecast(now));
    await CampusWeatherService(client: client).fetch('tsudanuma');
    expect(client.closed, isFalse);
    client.close();
  });

  test(
    'rate limits are not retried until Retry-After, including the other campus',
    () async {
      var clock = now;
      var calls = 0;
      final service = CampusWeatherService(
        now: () => clock,
        retryDelay: Duration.zero,
        client: MockClient(
          (_) async =>
              ++calls == 1
                  ? http.Response('{}', 429, headers: {'retry-after': '120'})
                  : forecast(clock),
        ),
      );
      final rateLimited = isA<WeatherHttpException>()
          .having((error) => error.statusCode, 'status', 429)
          .having(
            (error) => error.retryAfter,
            'retry delay',
            const Duration(seconds: 120),
          );
      await expectLater(service.fetch('tsudanuma'), throwsA(rateLimited));
      await expectLater(service.fetch('narashino'), throwsA(rateLimited));
      expect(calls, 1);
      clock = clock.add(const Duration(seconds: 120));
      expect((await service.fetch('narashino')).temperature, 24);
      expect(calls, 2);
    },
  );

  test('invalid requests fail once instead of repeating the request', () async {
    var calls = 0;
    final service = CampusWeatherService(
      client: MockClient((_) async {
        calls++;
        return http.Response('{"error":true}', 400);
      }),
    );
    await expectLater(
      service.fetch('tsudanuma'),
      throwsA(
        isA<WeatherHttpException>().having(
          (error) => error.statusCode,
          'status',
          400,
        ),
      ),
    );
    expect(calls, 1);
  });

  for (final body in ['not JSON', '[]', '{"current":{}}']) {
    test('malformed response $body is not retried or cached', () async {
      var calls = 0;
      final service = CampusWeatherService(
        client: MockClient((_) async {
          calls++;
          return http.Response(body, 200);
        }),
      );
      await expectLater(service.fetch('tsudanuma'), throwsFormatException);
      expect(calls, 1);
      expect(await service.readCached('tsudanuma'), isNull);
    });
  }

  test(
    'exhausted retries preserve the last successful forecast and its age',
    () async {
      var clock = now;
      var fail = false;
      final service = CampusWeatherService(
        now: () => clock,
        retryDelay: Duration.zero,
        client: MockClient((_) async {
          if (fail) throw TimeoutException('offline');
          return forecast(clock);
        }),
      );
      await service.fetch('tsudanuma');
      await Future<void>.delayed(Duration.zero);
      fail = true;
      clock = clock.add(const Duration(hours: 1));
      await expectLater(
        service.fetch('tsudanuma'),
        throwsA(isA<TimeoutException>()),
      );
      final cached = await service.readCached('tsudanuma');
      expect(cached?.temperature, 24);
      expect(cached?.fetchedAt, now);
      expect(cached?.isStale(clock), isTrue);
    },
  );
}
