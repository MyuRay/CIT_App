import 'dart:async';

import 'package:cit_app/core/providers/analytics_provider.dart';
import 'package:cit_app/core/providers/settings_provider.dart';
import 'package:cit_app/core/providers/simple_auth_provider.dart';
import 'package:cit_app/core/providers/theme_provider.dart';
import 'package:cit_app/core/services/analytics_service.dart';
import 'package:cit_app/models/ads/in_app_ad_model.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

AnalyticsUserContext context({
  AnalyticsAccountState account = AnalyticsAccountState.verified,
  String campus = 'tsudanuma',
  DateTime? created,
}) => AnalyticsUserContext(
  accountState: account,
  campus: campus,
  themeMode: ThemeMode.dark,
  fontSize: AppFontSizeOption.large,
  lectureReminders: true,
  releaseBuild: false,
  accountCreatedAt: created ?? DateTime.utc(2026, 8, 31, 16),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'root listener respects opt-out, then follows Auth and settings live',
    () async {
      SharedPreferences.setMockInitialValues({
        analyticsCollectionPreferenceKey: false,
      });
      final prefs = await SharedPreferences.getInstance();
      final auth = StreamController<User?>();
      final sdk = RecordingAnalytics();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          analyticsServiceProvider.overrideWithValue(AnalyticsService(sdk)),
          simpleAuthStateProvider.overrideWith((ref) => auth.stream),
        ],
      );
      final subscription = container.listen(
        analyticsSessionSyncProvider,
        (_, __) {},
      );
      await Future<void>.delayed(Duration.zero);
      auth.add(_AnalyticsUser());
      await Future<void>.delayed(Duration.zero);
      expect(sdk.enabled, isFalse);
      expect(sdk.events, isEmpty);
      await container
          .read(analyticsCollectionEnabledProvider.notifier)
          .setEnabled(true);
      await Future<void>.delayed(Duration.zero);
      expect(sdk.enabled, isTrue);
      expect(sdk.properties['account_state'], 'verified');
      expect(sdk.properties['signup_month'], '2025_04');
      expect(sdk.events.map((e) => e.name), ['app_open']);
      await container
          .read(settingsProvider.notifier)
          .setPreferredBusCampus('narashino');
      await container.read(themeModeProvider.notifier).setDarkMode();
      await Future<void>.delayed(Duration.zero);
      expect(sdk.properties['main_campus'], 'narashino');
      expect(sdk.properties['theme_preference'], 'dark');
      auth.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(sdk.properties['account_state'], 'signed_out');
      expect(sdk.properties['signup_month'], isNull);
      expect(sdk.events, hasLength(1));
      subscription.close();
      container.dispose();
      await auth.close();
    },
  );

  test(
    'only seven bounded properties; JST month has no account identifier',
    () {
      final properties = context(campus: 'someone@example.com').properties;
      expect(
        properties.keys,
        unorderedEquals(AnalyticsUserContext.propertyNames),
      );
      expect(properties['main_campus'], 'unknown');
      expect(properties['signup_month'], '2026_09');
      expect(properties['app_environment'], 'development');
      expect(properties.toString(), isNot(contains('someone@example.com')));
      expect(
        context(
          account: AnalyticsAccountState.signedOut,
        ).properties['signup_month'],
        isNull,
      );
      expect(
        context(created: DateTime(1900)).properties['signup_month'],
        isNull,
      );
    },
  );

  test(
    'attributes precede events and logout clears the previous signup month',
    () async {
      final sdk = RecordingAnalytics();
      final service = AnalyticsService(sdk);
      final configure = service.syncContext(enabled: true, context: context());
      final open = service.logAppOpen();
      await Future.wait([configure, open]);
      expect(sdk.events.single.properties['signup_month'], '2026_09');
      await service.syncContext(
        enabled: true,
        context: context(account: AnalyticsAccountState.signedOut),
      );
      await service.showMainTab(4);
      expect(sdk.events.last.properties['signup_month'], isNull);
      expect(sdk.events.last.properties['account_state'], 'signed_out');
      expect(sdk.ids, everyElement(isNull));
    },
  );

  test(
    'switching accounts uses the new cohort before the next event',
    () async {
      final sdk = RecordingAnalytics();
      final service = AnalyticsService(sdk);
      await service.syncContext(enabled: true, context: context());
      final update = service.syncContext(
        enabled: true,
        context: context(created: DateTime.utc(2025, 4, 1)),
      );
      final event = service.showMainTab(1);
      await Future.wait([update, event]);
      expect(sdk.events.last.properties['signup_month'], '2025_04');
    },
  );

  test(
    'opt-out drops queued events, clears properties and stays off',
    () async {
      final sdk = RecordingAnalytics();
      final service = AnalyticsService(sdk);
      await service.syncContext(enabled: true, context: context());
      final gate = Completer<void>();
      sdk.propertyGate = gate;
      final update = service.syncContext(
        enabled: true,
        context: context(campus: 'narashino'),
      );
      final queuedEvent = service.showMainTab(1);
      final disable = service.syncContext(enabled: false, context: context());
      gate.complete();
      await Future.wait([update, queuedEvent, disable]);
      await service.logAppOpen();
      expect(sdk.enabled, isFalse);
      expect(sdk.events, isEmpty);
      expect(sdk.properties.values, everyElement(isNull));
      await service.syncContext(enabled: true, context: context());
      await service.showMainTab(1);
      expect(sdk.events, hasLength(1));
    },
  );

  test('rapid disable/re-enable cannot resurrect old queued events', () async {
    final sdk = RecordingAnalytics();
    final service = AnalyticsService(sdk);
    await service.syncContext(enabled: true, context: context());
    final old = service.showMainTab(1);
    final off = service.syncContext(enabled: false, context: context());
    final on = service.syncContext(enabled: true, context: context());
    final fresh = service.showMainTab(4);
    await Future.wait([old, off, on, fresh]);
    expect(sdk.events.map((e) => e.parameters['screen_name']), ['profile']);
  });

  test('unknown names and free text cannot enter event parameters', () async {
    final sdk = RecordingAnalytics();
    final service = AnalyticsService(sdk);
    await service.syncContext(enabled: true, context: context());
    await service.logEvent(
      'student_email',
      parameters: {'email': 'someone@example.com'},
    );
    await service.logScreenView(
      screenName: '/classroom-map?q=someone@example.com',
    );
    await service.logEvent(
      'in_app_ad_click',
      parameters: {
        'ad_id': 'https://example.com/private',
        'placement': 'profileTop',
        'action_type': 'external',
        'email': 'someone@example.com',
        'body': 'private text',
      },
    );
    expect(sdk.events, hasLength(1));
    expect(sdk.events.single.parameters, {
      'placement': 'profileTop',
      'action_type': 'external',
    });
    for (final placement in AdPlacement.values) {
      await service.logEvent(
        'in_app_ad_impression',
        parameters: {'placement': placement.name},
      );
      expect(sdk.events.last.parameters['placement'], placement.name);
    }
  });

  test('all five tabs are counted without duplicate selections', () async {
    final sdk = RecordingAnalytics();
    final service = AnalyticsService(sdk);
    await service.syncContext(enabled: true, context: context());
    for (var index = 0; index < 5; index++) {
      await service.showMainTab(index);
      await service.showMainTab(index);
    }
    expect(
      sdk.events.map((e) => e.parameters['screen_name']),
      AnalyticsService.mainTabs,
    );
  });

  test(
    'failed SDK calls do not throw to callers and the queue recovers',
    () async {
      final sdk = RecordingAnalytics()..fail = true;
      final service = AnalyticsService(sdk);
      await service.syncContext(enabled: true, context: context());
      await service.logAppOpen();
      expect(sdk.events, isEmpty);
      sdk.fail = false;
      await service.syncContext(enabled: true, context: context());
      sdk.fail = true;
      await service.showMainTab(1);
      sdk.fail = false;
      await service.showMainTab(1);
      expect(sdk.events, hasLength(1));
    },
  );

  test('collection preference survives recreation', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifier = AnalyticsPreferenceNotifier(prefs);
    expect(notifier.state, isTrue);
    await notifier.setEnabled(false);
    notifier.dispose();
    final restored = AnalyticsPreferenceNotifier(prefs);
    expect(restored.state, isFalse);
    restored.dispose();
  });

  test(
    'observer ignores raw paths and home pushes, restores the selected tab',
    () async {
      final sdk = RecordingAnalytics();
      final service = AnalyticsService(sdk);
      await service.syncContext(enabled: true, context: context());
      final observer = AppAnalyticsObserver(service);
      MaterialPageRoute<void> route(String name) => MaterialPageRoute(
        settings: RouteSettings(name: name),
        builder: (_) => const SizedBox(),
      );
      final home = route('home');
      observer.didPush(home, null);
      await service.showMainTab(1);
      final privacy = route('privacy');
      observer.didPush(privacy, home);
      observer.didPush(route('/profile/someone@example.com'), privacy);
      observer.didPop(privacy, home);
      await service.logMainTabScreen();
      expect(sdk.events.map((e) => e.parameters['screen_name']), [
        'schedule',
        'privacy',
        'schedule',
      ]);
    },
  );
}

class _AnalyticsUser implements User {
  @override
  bool get emailVerified => true;
  @override
  UserMetadata get metadata =>
      UserMetadata(DateTime.utc(2025, 4, 1).millisecondsSinceEpoch, null);
  // Accessing email, UID, etc. fails the test: the listener needs neither.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class RecordedEvent {
  RecordedEvent(this.name, this.parameters, Map<String, String?> properties)
    : properties = Map.of(properties);
  final String name;
  final Map<String, Object> parameters;
  final Map<String, String?> properties;
}

class RecordingAnalytics implements FirebaseAnalytics {
  final properties = <String, String?>{};
  final events = <RecordedEvent>[];
  final ids = <String?>[];
  bool enabled = false;
  bool fail = false;
  Completer<void>? propertyGate;

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    if (fail) throw StateError('SDK unavailable');
    this.enabled = enabled;
  }

  @override
  Future<void> setUserId({
    String? id,
    AnalyticsCallOptions? callOptions,
  }) async {
    if (fail) throw StateError('SDK unavailable');
    ids.add(id);
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
    AnalyticsCallOptions? callOptions,
  }) async {
    await propertyGate?.future;
    if (fail) throw StateError('SDK unavailable');
    properties[name] = value;
  }

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
    AnalyticsCallOptions? callOptions,
  }) async {
    if (fail) throw StateError('SDK unavailable');
    events.add(RecordedEvent(name, parameters ?? {}, properties));
  }

  @override
  Future<void> logAppOpen({
    Map<String, Object>? parameters,
    AnalyticsCallOptions? callOptions,
  }) => logEvent(name: 'app_open');
  @override
  Future<void> logScreenView({
    String? screenName,
    String? screenClass,
    Map<String, Object>? parameters,
    AnalyticsCallOptions? callOptions,
  }) => logEvent(name: 'screen_view', parameters: {'screen_name': screenName!});
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
