import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provides a singleton FirebaseAnalytics instance.
final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>((ref) {
  return FirebaseAnalytics.instance;
});

/// Provides a ready-to-use analytics observer for navigator stacks.
final firebaseAnalyticsObserverProvider = Provider<FirebaseAnalyticsObserver>((
  ref,
) {
  final analytics = ref.watch(firebaseAnalyticsProvider);
  return FirebaseAnalyticsObserver(
    analytics: analytics,
    nameExtractor: (RouteSettings settings) => settings.name ?? 'unknown',
  );
});

/// Thin wrapper that centralises analytics related helpers.
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final analytics = ref.watch(firebaseAnalyticsProvider);
  return AnalyticsService(analytics);
});

class AnalyticsService {
  AnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  Future<void> logAppOpen() => _analytics.logAppOpen();

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) {
    return _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) {
    return _analytics.logEvent(name: name, parameters: parameters);
  }
}
