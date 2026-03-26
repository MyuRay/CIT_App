import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

bool _firebaseReadyForAnalytics() {
  if (Firebase.apps.isEmpty) return false;
  try {
    Firebase.app();
    return true;
  } catch (_) {
    return false;
  }
}

/// GoRouter / MaterialApp 用。Firebase 未初期化時は空（チームメンバーが plist 未配置でも起動できる）。
final firebaseNavigationObserversProvider =
    Provider<List<NavigatorObserver>>((ref) {
  if (!_firebaseReadyForAnalytics()) return const [];
  try {
    return [
      FirebaseAnalyticsObserver(
        analytics: FirebaseAnalytics.instance,
        nameExtractor: (RouteSettings settings) => settings.name ?? 'unknown',
      ),
    ];
  } catch (_) {
    return const [];
  }
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return const AnalyticsService();
});

class AnalyticsService {
  const AnalyticsService();

  Future<void> logAppOpen() async {
    if (!_firebaseReadyForAnalytics()) return;
    await FirebaseAnalytics.instance.logAppOpen();
  }

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_firebaseReadyForAnalytics()) return;
    await FirebaseAnalytics.instance.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    if (!_firebaseReadyForAnalytics()) return;
    await FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
  }
}
