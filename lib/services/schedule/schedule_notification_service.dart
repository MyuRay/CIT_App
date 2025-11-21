import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../models/schedule/schedule_model.dart';

/// ローカル講義通知を担当するサービス。
class ScheduleNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// プラグイン初期化（アプリ起動時に1度だけ呼ぶ）
  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'schedule_notifications',
            '講義通知',
            description: '講義開始10分前に通知します',
            importance: Importance.high,
          ),
        );

    await _requestAndroidPermissions();

    _initialized = true;
    debugPrint('✅ ScheduleNotificationService initialized');
  }

  static Future<void> _requestAndroidPermissions() async {
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return;

    final granted = await androidImpl.requestNotificationsPermission();
    debugPrint('📱 通知権限: ${granted == true ? "許可" : "拒否"}');
  }

  /// すべての講義通知をキャンセル
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('🗑️ すべての講義通知をキャンセルしました');
  }

  /// 1週間分の講義をまとめてスケジュール
  static Future<void> scheduleWeeklyNotifications(Schedule schedule) async {
    if (!_initialized) {
      await initialize();
    }

    await cancelAllNotifications();

    final now = DateTime.now();
    int scheduled = 0;

    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      final weekdayKey = _getWeekdayKey(targetDate.weekday);
      if (weekdayKey == null) continue;

      final daySchedule = schedule.timetable[weekdayKey];
      if (daySchedule == null) continue;

      for (int period = 1; period <= 10; period++) {
        final scheduleClass = daySchedule[period];
        if (scheduleClass == null || !scheduleClass.isStartCell) continue;

        final timeSlot = schedule.timeSlots.firstWhere(
          (slot) => slot.period == period,
          orElse: () => TimeSlot(
            period: period,
            startTime: '${period + 8}:00',
            endTime: '${period + 9}:00',
          ),
        );

        final notificationTime = _buildClassDateTime(
          targetDate,
          timeSlot.startTime,
        ).subtract(const Duration(minutes: 10));

        if (notificationTime.isBefore(now)) continue;

        final notificationId = _generateNotificationId(weekdayKey, period);
        final title = '📚 講義開始10分前';
        final body =
            '次の講義は「${scheduleClass.subjectName}」。教室は「${scheduleClass.classroom}」。';

        try {
          await _notifications.zonedSchedule(
            notificationId,
            title,
            body,
            tz.TZDateTime.from(notificationTime, tz.local),
            _notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: 'schedule_${weekdayKey}_$period',
          );
          scheduled++;
          debugPrint('✅ 通知を設定: $weekdayKey $period - $notificationTime');
        } catch (e) {
          debugPrint('❌ 通知設定失敗 ($weekdayKey $period): $e');
        }
      }
    }

    debugPrint('📅 合計 $scheduled 件の講義通知をスケジュールしました');
  }

  static DateTime _buildClassDateTime(DateTime base, String startTime) {
    final parts = startTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 9;
    final minute = int.tryParse(parts.elementAtOrNull(1) ?? '0') ?? 0;
    return DateTime(base.year, base.month, base.day, hour, minute);
  }

  static int _generateNotificationId(String weekday, int period) {
    final weekdayIndex = _weekdayIndexForId(weekday);
    return weekdayIndex * 100 + period;
  }

  static int _weekdayIndexForId(String weekday) {
    switch (weekday) {
      case 'monday':
        return 1;
      case 'tuesday':
        return 2;
      case 'wednesday':
        return 3;
      case 'thursday':
        return 4;
      case 'friday':
        return 5;
      case 'saturday':
        return 6;
      case 'sunday':
        return 7;
      default:
        return 0;
    }
  }

  static String? _getWeekdayKey(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
        return 'tuesday';
      case DateTime.wednesday:
        return 'wednesday';
      case DateTime.thursday:
        return 'thursday';
      case DateTime.friday:
        return 'friday';
      case DateTime.saturday:
        return 'saturday';
      default:
        return null;
    }
  }

  static const _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'schedule_notifications',
      '講義通知',
      channelDescription: '講義開始前の通知を受信します',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );
}

