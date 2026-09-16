import 'dart:async';
import 'package:cit_app/core/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('requested release configuration is active', () {
    const mode = String.fromEnvironment('EXPECTED_LOG_MODE');
    if (mode == 'release') expect(kReleaseMode, isTrue);
  });
  final token = '${'a' * 22}:${'b' * 150}';
  test('logs redact email, raw FCM tokens, authorization and URL queries', () {
    final text = SecureLogger.sanitize(
      'user@example.org token=$token raw $token '
      'Bearer secret-auth https://example.org/file?token=secret-url',
    );
    for (final secret in [
      'user@example.org',
      token,
      'secret-auth',
      'secret-url',
    ]) {
      expect(text, isNot(contains(secret)));
    }
  });
  test(
    'diagnostic logs contain no secrets in debug and are absent in release',
    () {
      final output = <String>[];
      runZoned(
        () {
          SecureLogger.debug(
            'user@example.org token=$token',
            context: 'user@example.org',
          );
          SecureLogger.info('token=$token');
          SecureLogger.warning('token=$token');
        },
        zoneSpecification: ZoneSpecification(
          print: (_, __, ___, line) => output.add(line),
        ),
      );
      if (kDebugMode) {
        expect(output, hasLength(3));
        expect(output.join(), isNot(contains(token)));
        expect(output.join(), isNot(contains('user@example.org')));
      } else {
        expect(output, isEmpty);
      }
    },
  );
  test('error context and exception text are sanitized too', () {
    final output = <String>[];
    runZoned(
      () {
        SecureLogger.error(
          'token=$token',
          context: 'user@example.org',
          error: StateError('token=$token'),
        );
        SecureLogger.security('Bearer secret-auth');
      },
      zoneSpecification: ZoneSpecification(
        print: (_, __, ___, line) => output.add(line),
      ),
    );
    expect(output.join(), isNot(contains(token)));
    expect(output.join(), isNot(contains('user@example.org')));
    expect(output.join(), isNot(contains('secret-auth')));
  });
}
