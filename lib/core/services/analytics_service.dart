import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/settings_provider.dart';
import '../../models/ads/in_app_ad_model.dart';

const analyticsCollectionPreferenceKey = 'analytics_collection_enabled';

final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>((ref) {
  return FirebaseAnalytics.instance;
});

final firebaseAnalyticsObserverProvider = Provider<NavigatorObserver>((ref) {
  return AppAnalyticsObserver(ref.watch(analyticsServiceProvider));
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(ref.watch(firebaseAnalyticsProvider));
});

enum AnalyticsAccountState { unknown, signedOut, unverified, verified }

/// Only bounded, non-identifying attributes enter Analytics. Deliberately accepts
/// no AppUser, UID, email, student ID, profile text or Firestore document.
class AnalyticsUserContext {
  const AnalyticsUserContext({
    required this.accountState,
    required this.campus,
    required this.themeMode,
    required this.fontSize,
    required this.lectureReminders,
    required this.releaseBuild,
    this.accountCreatedAt,
  });

  final AnalyticsAccountState accountState;
  final String campus;
  final ThemeMode themeMode;
  final AppFontSizeOption fontSize;
  final bool lectureReminders;
  final bool releaseBuild;
  final DateTime? accountCreatedAt;

  static const propertyNames = [
    'account_state',
    'main_campus',
    'theme_preference',
    'font_size',
    'lecture_reminders',
    'app_environment',
    'signup_month',
  ];

  Map<String, String?> get properties {
    final signedIn =
        accountState == AnalyticsAccountState.verified ||
        accountState == AnalyticsAccountState.unverified;
    // Month precision only, always in JST so OS timezone cannot change cohorts.
    final created = accountCreatedAt?.toUtc().add(const Duration(hours: 9));
    return {
      'account_state': switch (accountState) {
        AnalyticsAccountState.unknown => 'unknown',
        AnalyticsAccountState.signedOut => 'signed_out',
        AnalyticsAccountState.unverified => 'unverified',
        AnalyticsAccountState.verified => 'verified',
      },
      'main_campus': switch (campus) {
        'tsudanuma' || 'narashino' => campus,
        _ => 'unknown',
      },
      'theme_preference': themeMode.name,
      'font_size': fontSize.name,
      'lecture_reminders': lectureReminders ? 'enabled' : 'disabled',
      'app_environment': releaseBuild ? 'production' : 'development',
      'signup_month':
          signedIn &&
                  created != null &&
                  created.year >= 2020 &&
                  created.year <= 2100
              ? '${created.year}_${created.month.toString().padLeft(2, '0')}'
              : null,
    };
  }
}

class AnalyticsService {
  AnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;
  Future<void> _pending = Future<void>.value();
  bool _enabled = false;
  bool _ready = false;
  int _generation = 0;
  Map<String, String?> _properties = {};
  String _mainTab = 'home';
  String? _screen;

  static const mainTabs = [
    'home',
    'schedule',
    'community',
    'bulletin',
    'profile',
  ];
  static const routeScreens = {
    'bus': 'bus',
    'login': 'login',
    'signup': 'signup',
    'email-verification': 'email_verification',
    'change-email': 'change_email',
    'change-email-verification': 'change_email_verification',
    'terms': 'terms',
    'privacy': 'privacy',
    'blocked-users': 'blocked_users',
    'classroom-map': 'classroom_map',
  };

  // Preserve ordering between attribute changes and events. SDK failures must
  // never prevent navigation or another application operation.
  Future<void> _enqueue(Future<void> Function() operation) {
    _pending = _pending.then((_) async {
      try {
        await operation();
      } catch (_) {
        debugPrint('Analytics operation failed; app operation continues.');
      }
    });
    return _pending;
  }

  Future<void> syncContext({
    required bool enabled,
    required AnalyticsUserContext context,
  }) {
    _enabled = enabled;
    if (!enabled) _generation++;
    final generation = _generation;
    final properties = context.properties;
    return _enqueue(() async {
      if (!enabled) {
        _ready = false;
        _screen = null;
        await _analytics.setAnalyticsCollectionEnabled(false);
        await _analytics.setUserId(id: null);
        for (final name in AnalyticsUserContext.propertyNames) {
          await _analytics.setUserProperty(name: name, value: null);
        }
        _properties = {};
        return;
      }
      if (!_enabled || generation != _generation) return;
      try {
        // Use Analytics' installation identifier, without linking Auth accounts.
        if (!_ready) await _analytics.setUserId(id: null);
        for (final entry in properties.entries) {
          if (!_ready || _properties[entry.key] != entry.value) {
            await _analytics.setUserProperty(
              name: entry.key,
              value: entry.value,
            );
          }
        }
        if (!_enabled || generation != _generation) return;
        if (!_ready) await _analytics.setAnalyticsCollectionEnabled(true);
        _properties = properties;
        _ready = true;
      } catch (_) {
        _ready = false;
        rethrow;
      }
    });
  }

  Future<void> _event(Future<void> Function() operation) {
    if (!_enabled) return Future<void>.value();
    final generation = _generation;
    return _enqueue(() async {
      if (_enabled && _ready && generation == _generation) await operation();
    });
  }

  Future<void> logAppOpen() => _event(_analytics.logAppOpen);

  Future<void> showMainTab(int index) {
    _mainTab = mainTabs[index >= 0 && index < mainTabs.length ? index : 0];
    return logMainTabScreen();
  }

  Future<void> logMainTabScreen() => logScreenView(screenName: _mainTab);

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) {
    if (!mainTabs.contains(screenName) &&
        !routeScreens.containsValue(screenName)) {
      return Future<void>.value();
    }
    return _event(() async {
      if (_screen == screenName) return;
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: 'Flutter',
      );
      _screen = screenName;
    });
  }

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) {
    if (name != 'in_app_ad_impression' && name != 'in_app_ad_click') {
      return Future<void>.value();
    }
    final safe = <String, Object>{};
    final adId = parameters?['ad_id'];
    if (adId is String && RegExp(r'^[a-zA-Z0-9_-]{1,64}$').hasMatch(adId)) {
      safe['ad_id'] = adId;
    }
    final placement = parameters?['placement'];
    if (AdPlacement.values.any((value) => value.name == placement)) {
      safe['placement'] = placement!;
    }
    final action = parameters?['action_type'];
    if (const ['external', 'bulletin'].contains(action)) {
      safe['action_type'] = action!;
    }
    return _event(() => _analytics.logEvent(name: name, parameters: safe));
  }
}

/// Never use raw routes, query strings, search terms or IDs as screen names.
class AppAnalyticsObserver extends NavigatorObserver {
  AppAnalyticsObserver(this.analytics);
  final AnalyticsService analytics;

  void _view(Route<dynamic>? route, {bool restoreMain = false}) {
    if (route is! PageRoute) return;
    final name = route.settings.name;
    if (name == 'home') {
      // MainScreen owns initial/tab/deep-link views. Only restore on return.
      if (restoreMain) unawaited(analytics.logMainTabScreen());
    } else {
      final screen = AnalyticsService.routeScreens[name];
      if (screen != null) {
        unawaited(analytics.logScreenView(screenName: screen));
      }
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _view(route);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _view(previousRoute, restoreMain: true);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _view(newRoute);
}
