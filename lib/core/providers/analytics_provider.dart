import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/analytics_service.dart';
import 'settings_provider.dart';
import 'simple_auth_provider.dart';
import 'theme_provider.dart';

final analyticsCollectionEnabledProvider =
    StateNotifierProvider<AnalyticsPreferenceNotifier, bool>((ref) {
      return AnalyticsPreferenceNotifier(ref.watch(sharedPreferencesProvider));
    });

class AnalyticsPreferenceNotifier extends StateNotifier<bool> {
  AnalyticsPreferenceNotifier(this._prefs)
    : super(_prefs.getBool(analyticsCollectionPreferenceKey) ?? true);
  final SharedPreferences _prefs;

  Future<void> setEnabled(bool enabled) async {
    if (!await _prefs.setBool(analyticsCollectionPreferenceKey, enabled)) {
      throw StateError('Could not save analytics preference');
    }
    state = enabled;
  }
}

/// Uses existing Auth/settings data; never exports the Firestore users collection.
final analyticsSessionSyncProvider = Provider<void>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  var didLogAppOpen = false;

  void sync() {
    final auth = ref.read(simpleAuthStateProvider);
    final user = auth.asData?.value;
    final settings = ref.read(settingsProvider);
    final enabled = ref.read(analyticsCollectionEnabledProvider);
    unawaited(
      analytics.syncContext(
        enabled: enabled,
        context: AnalyticsUserContext(
          accountState:
              !auth.hasValue
                  ? AnalyticsAccountState.unknown
                  : user == null
                  ? AnalyticsAccountState.signedOut
                  : user.emailVerified
                  ? AnalyticsAccountState.verified
                  : AnalyticsAccountState.unverified,
          accountCreatedAt: user?.metadata.creationTime,
          campus: settings.preferredBusCampus,
          themeMode: ref.read(themeModeProvider),
          fontSize: settings.appFontSize,
          lectureReminders: settings.scheduleNotificationEnabled,
          releaseBuild: kReleaseMode,
        ),
      ),
    );
    if (enabled && auth.hasValue && !didLogAppOpen) {
      didLogAppOpen = true;
      unawaited(analytics.logAppOpen());
    }
  }

  ref.listen(simpleAuthStateProvider, (_, __) => sync());
  ref.listen(settingsProvider, (_, __) => sync());
  ref.listen(themeModeProvider, (_, __) => sync());
  ref.listen(analyticsCollectionEnabledProvider, (_, __) => sync());
  sync();
});
