import 'dart:async';
import 'dart:convert';

import 'package:cit_app/core/services/app_update_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const packageName = 'jp.ac.chibakoudai.citapp';
const installed = InstalledAppVersion('2.3.2', '83', packageName);

String policy({
  String version = '2.3.3',
  String build = '84',
  bool enabled = true,
  String url = 'https://play.google.com/store/apps/details?id=$packageName',
}) => jsonEncode({
  'enabled': enabled,
  'version': version,
  'buildNumber': build,
  'storeUrl': url,
});

void main() {
  AppUpdateInfo? check(
    String configuration, {
    InstalledAppVersion current = installed,
    TargetPlatform platform = TargetPlatform.android,
  }) => availableAppUpdate(
    configuration: configuration,
    installed: current,
    platform: platform,
  );

  test('newer published version and build offer the matching store', () {
    final result = check(policy())!;
    expect(result.latestVersion, '2.3.3');
    expect(result.currentVersion, '2.3.2');
    expect(result.storeUrl.queryParameters['id'], packageName);
  });

  test('same and older releases do not prompt or suggest a downgrade', () {
    expect(check(policy(version: '2.3.2', build: '83')), isNull);
    expect(check(policy(version: '2.3.1', build: '82')), isNull);
    expect(check(policy(version: '2.3.1', build: '84')), isNull);
    expect(check(policy(version: '2.3.3', build: '82')), isNull);
  });

  test('a rebuilt release with the same version can prompt', () {
    expect(check(policy(version: '2.3.2', build: '84')), isNotNull);
  });

  test('version comparison is numeric, including two digit segments', () {
    expect(
      check(
        policy(version: '2.10.0'),
        current: const InstalledAppVersion('2.9.9', '83', packageName),
      ),
      isNotNull,
    );
    expect(
      check(
        policy(version: '2.9.9'),
        current: const InstalledAppVersion('2.10.0', '83', packageName),
      ),
      isNull,
    );
  });

  test('disabled, missing and malformed configurations fail open', () {
    for (final configuration in [
      '',
      'null',
      '[]',
      '{}',
      '{bad',
      policy(enabled: false),
      policy(version: 'latest'),
      policy(version: '2.4'),
      policy(version: '2.4.0-beta'),
      policy(build: 'unknown'),
      '{"enabled":true,"version":2,"buildNumber":84}',
    ]) {
      expect(check(configuration), isNull, reason: configuration);
    }
    expect(
      check(
        policy(),
        current: const InstalledAppVersion('dev', '83', packageName),
      ),
      isNull,
    );
  });

  test('rejects a wrong app, wrong store and unsafe destination', () {
    for (final url in [
      'https://play.google.com/store/apps/details?id=another.app',
      'https://play.google.com.evil.test/store/apps/details?id=$packageName',
      'http://play.google.com/store/apps/details?id=$packageName',
      'https://user@play.google.com/store/apps/details?id=$packageName',
      'https://play.google.com:8443/store/apps/details?id=$packageName',
      'javascript:alert(1)',
      'https://apps.apple.com/jp/app/id123456789',
    ]) {
      expect(check(policy(url: url)), isNull, reason: url);
    }
  });

  test(
    'iOS requires App Store URL and permits a build reset for new versions',
    () {
      expect(
        check(
          policy(url: 'https://apps.apple.com/jp/app/id123456789', build: '1'),
          platform: TargetPlatform.iOS,
        ),
        isNotNull,
      );
      expect(check(policy(), platform: TargetPlatform.iOS), isNull);
      expect(
        check(
          policy(url: 'https://apps.apple.com/'),
          platform: TargetPlatform.iOS,
        ),
        isNull,
      );
    },
  );

  test(
    'iOS public release can compare version without an unpublished build number',
    () {
      final configuration = jsonEncode({
        'enabled': true,
        'version': '2.0.0',
        'storeUrl': 'https://apps.apple.com/jp/app/cit-app/id6752514796',
      });
      expect(
        check(
          configuration,
          current: const InstalledAppVersion(
            '1.7.10',
            '50',
            'com.masatomurai.citapp',
          ),
          platform: TargetPlatform.iOS,
        ),
        isNotNull,
      );
      expect(
        check(
          configuration,
          current: const InstalledAppVersion(
            '2.0.0',
            '60',
            'com.masatomurai.citapp',
          ),
          platform: TargetPlatform.iOS,
        ),
        isNull,
      );
      expect(
        check(
          configuration,
          current: const InstalledAppVersion(
            '2.3.2',
            '83',
            'com.masatomurai.citapp',
          ),
          platform: TargetPlatform.iOS,
        ),
        isNull,
      );
    },
  );

  test('Android still requires a known published build', () {
    final configuration = jsonDecode(policy()) as Map<String, dynamic>;
    configuration.remove('buildNumber');
    expect(check(jsonEncode(configuration)), isNull);
  });

  test(
    'unsupported platforms do not access Firebase or package information',
    () async {
      final service = AppUpdateService(
        platform: TargetPlatform.windows,
        loadConfiguration: () => throw StateError('must not load'),
        loadInstalledVersion: () => throw StateError('must not load'),
      );
      expect(await service.check(), isNull);
    },
  );

  test('service uses installed binary metadata', () async {
    final service = AppUpdateService(
      platform: TargetPlatform.android,
      loadConfiguration: () async => policy(version: '2.3.2'),
      loadInstalledVersion: () async => installed,
    );
    expect((await service.check())?.latestVersion, '2.3.2');
  });

  test('network and platform failures never block startup', () async {
    final networkFailure = AppUpdateService(
      platform: TargetPlatform.android,
      loadConfiguration: () => Future.error(StateError('offline')),
      loadInstalledVersion: () async => installed,
    );
    expect(await networkFailure.check(), isNull);
    final packageFailure = AppUpdateService(
      platform: TargetPlatform.android,
      loadConfiguration: () async => policy(),
      loadInstalledVersion: () => Future.error(StateError('platform')),
    );
    expect(await packageFailure.check(), isNull);
  });

  test('hanging request times out without returning a late prompt', () async {
    final pending = Completer<String>();
    final service = AppUpdateService(
      platform: TargetPlatform.android,
      loadConfiguration: () => pending.future,
      loadInstalledVersion: () async => installed,
      timeout: const Duration(milliseconds: 5),
    );
    expect(await service.check(), isNull);
    pending.complete(policy());
  });
}
