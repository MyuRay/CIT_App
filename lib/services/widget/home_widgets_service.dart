import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../../core/utils/logger.dart';
import '../../models/schedule/schedule_model.dart';
import '../../models/bus/bus_model.dart';
import '../auth/session_work_guard.dart';
import 'home_widget_payloads.dart';

class HomeWidgetsService {
  // Matches both iOS entitlement files and the WidgetKit UserDefaults suite.
  static const appGroupId = 'group.com.masatomurai.citapp';
  static const _weekly = 'FullScheduleWidgetProvider';
  static const _today = 'TodayScheduleWidgetProvider';
  static const _bus = 'BusRealtimeWidgetProvider';
  static Future<void>? _initialization;
  static Future<void> _queue = Future.value();
  static String? _lastBusSnapshot;
  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> initialize() async {
    if (!_supported) return;
    try {
      await (_initialization ??= _initialize());
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  static Future<void> _initialize() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await HomeWidget.setAppGroupId(appGroupId);
    }
  }

  static Future<void> _serialize(Future<void> Function() write) {
    if (!_supported) return Future.value();
    final task = _queue.then((_) async {
      await initialize();
      await write();
    });
    _queue = task.catchError((Object _) {
      SecureLogger.debug('ホーム画面ウィジェットを更新できませんでした');
    });
    return task;
  }

  static Future<void> _reload(String name) async {
    await HomeWidget.updateWidget(
      androidName: name,
      qualifiedAndroidName: 'jp.ac.chibakoudai.citapp.widget.$name',
      iOSName: name,
    );
  }

  static Future<void> clearUserSchedule() => _serialize(() async {
    final empty = HomeWidgetPayloads.weekly(null, now: DateTime.now());
    await HomeWidget.saveWidgetData('weekly_full_schedule', jsonEncode(empty));
    await HomeWidget.saveWidgetData(
      'today_schedule',
      jsonEncode(HomeWidgetPayloads.today(empty, DateTime.now())),
    );
    await _reload(_weekly);
    await _reload(_today);
  });

  /// A complete week drives both schedule widgets, including after midnight.
  static Future<void> updateWeeklyFullSchedule(
    Schedule? schedule, {
    required String userId,
    String? scheduleTitle,
  }) async {
    final generation = SessionWorkGuard.generation;
    bool current() =>
        SessionWorkGuard.isCurrent(generation) &&
        FirebaseAuth.instance.currentUser?.uid == userId &&
        (schedule == null || schedule.userId == userId);
    if (!_supported || !current()) return;
    try {
      await _serialize(() async {
        if (!current()) return;
        final now = DateTime.now();
        final snapshot = HomeWidgetPayloads.weekly(
          schedule,
          now: now,
          title: scheduleTitle,
        );
        await HomeWidget.saveWidgetData(
          'weekly_full_schedule',
          jsonEncode(snapshot),
        );
        if (!current()) return;
        await HomeWidget.saveWidgetData(
          'today_schedule',
          jsonEncode(HomeWidgetPayloads.today(snapshot, now)),
        );
        if (!current()) return;
        await _reload(_weekly);
        await _reload(_today);
      });
    } catch (_) {
      /* Keep the last snapshot on transient failures. */
    }
  }

  static Future<void> updateBusRealtime(
    BusInformation? info, {
    String preferredCampus = 'tsudanuma',
  }) async {
    if (!_supported || info == null) return;
    try {
      await _serialize(() async {
        final payload = HomeWidgetPayloads.bus(
          info,
          now: DateTime.now(),
          preferredCampus: preferredCampus,
        );
        // Home cards may rebuild every second. Refresh on data changes or once
        // per minute, without spending the native widget's budget on duplicates.
        final signature = jsonEncode({
          ...payload,
          'updatedAt': (payload['updatedAt'] as int) ~/ 60000,
        });
        if (signature == _lastBusSnapshot) return;
        await HomeWidget.saveWidgetData('bus_realtime', jsonEncode(payload));
        await _reload(_bus);
        _lastBusSnapshot = signature;
      });
    } catch (_) {
      /* Native views show the snapshot's age. */
    }
  }
}
