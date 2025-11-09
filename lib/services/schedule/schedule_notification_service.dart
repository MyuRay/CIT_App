import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../../models/schedule/schedule_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ScheduleNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // 通知サービスを初期化
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // タイムゾーンデータを初期化
      tz.initializeTimeZones();
      // 日本時間（Asia/Tokyo）を設定
      tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

      // Android初期化設定
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS初期化設定
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // 初期化設定
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      // 通知プラグインを初期化
      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Android通知チャンネルを作成
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'schedule_notifications',
        '講義通知',
        description: '講義開始前の通知を受け取ります',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      _initialized = true;
      debugPrint('✅ 講義通知サービスを初期化しました');
    } catch (e) {
      debugPrint('❌ 講義通知サービスの初期化エラー: $e');
    }
  }

  // 通知タップ時の処理
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('通知がタップされました: ${response.payload}');
    // 必要に応じて画面遷移などの処理を追加
  }

  // 全ての予定された通知をキャンセル
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('✅ 全ての講義通知をキャンセルしました');
  }

  // 次の講義の通知をスケジュール
  static Future<void> scheduleNextClassNotification(
    Schedule schedule,
  ) async {
    if (!_initialized) {
      await initialize();
    }

    // 既存の通知をキャンセル
    await cancelAllNotifications();

    // 次の講義を取得
    final nextClassInfo = _getNextClassWithTime(schedule);
    if (nextClassInfo == null) {
      debugPrint('次の講義が見つかりませんでした');
      return;
    }

    final nextClass = nextClassInfo['class'] as ScheduleClass;
    final notificationTime = nextClassInfo['time'] as DateTime;
    final period = nextClassInfo['period'] as int;

    // 通知時刻を10分前に設定
    final notificationDateTime = notificationTime.subtract(
      const Duration(minutes: 10),
    );

    // 現在時刻より過去の場合はスケジュールしない
    if (notificationDateTime.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint('通知時刻が過去のためスケジュールしません: $notificationDateTime');
      return;
    }

    // 通知ID（曜日と時限から生成）
    final notificationId = _generateNotificationId(
      nextClassInfo['weekday'] as String,
      period,
    );

    // 通知内容
    final title = '📚 講義開始10分前';
    final body =
        '次の講義は「${nextClass.subjectName}」です。教室は「${nextClass.classroom}」です。出席ボタンを押しましょう！';

    // 通知をスケジュール
    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(notificationDateTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'schedule_notifications',
          '講義通知',
          channelDescription: '講義開始前の通知を受け取ります',
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
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'schedule_${nextClassInfo['weekday']}_$period',
    );

    debugPrint(
      '✅ 講義通知をスケジュールしました: $notificationDateTime - ${nextClass.subjectName}',
    );
  }

  // 次の講義とその開始時刻を取得
  static Map<String, dynamic>? _getNextClassWithTime(Schedule schedule) {
    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1=月曜日, 7=日曜日
    final currentTime = TimeOfDay.fromDateTime(now);

    // 今週の残りの日をチェック（今日から1週間）
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      final targetWeekday = targetDate.weekday;
      final weekdayKey = _getWeekdayKey(targetWeekday);

      if (weekdayKey == null) continue;

      final daySchedule = schedule.timetable[weekdayKey];
      if (daySchedule == null) continue;

      // 各時限をチェック
      for (int period = 1; period <= 10; period++) {
        final scheduleClass = daySchedule[period];
        if (scheduleClass == null) continue;

        // 連続講義の場合、開始セルのみ通知をスケジュール
        if (!scheduleClass.isStartCell) continue;

        // 時限の開始時刻を取得
        final timeSlot = schedule.timeSlots.firstWhere(
          (slot) => slot.period == period,
          orElse: () => TimeSlot(
            period: period,
            startTime: '${period + 8}:00',
            endTime: '${period + 9}:00',
          ),
        );

        // 開始時刻をパース
        final startTimeParts = timeSlot.startTime.split(':');
        final startHour = int.parse(startTimeParts[0]);
        final startMinute = int.parse(startTimeParts[1]);

        // 通知時刻を計算
        final notificationTime = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          startHour,
          startMinute,
        );

        // 今日で、かつ現在時刻より未来の場合
        if (dayOffset == 0) {
          final startTimeOfDay = TimeOfDay(hour: startHour, minute: startMinute);
          if (startTimeOfDay.hour * 60 + startTimeOfDay.minute >
              currentTime.hour * 60 + currentTime.minute + 10) {
            // 10分以上先の講義
            return {
              'class': scheduleClass,
              'time': notificationTime,
              'period': period,
              'weekday': weekdayKey,
            };
          }
        } else {
          // 未来の日の講義
          return {
            'class': scheduleClass,
            'time': notificationTime,
            'period': period,
            'weekday': weekdayKey,
          };
        }
      }
    }

    return null;
  }

  // 曜日のキーを取得
  static String? _getWeekdayKey(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      default:
        return null; // 日曜日
    }
  }

  // 通知IDを生成（曜日と時限から）
  static int _generateNotificationId(String weekday, int period) {
    final weekdayHash = weekday.hashCode;
    return (weekdayHash * 100 + period).abs();
  }

  // 今週の全ての講義の通知をスケジュール
  static Future<void> scheduleWeeklyNotifications(Schedule schedule) async {
    if (!_initialized) {
      await initialize();
    }

    // 既存の通知をキャンセル
    await cancelAllNotifications();

    final now = DateTime.now();
    int notificationCount = 0;

    // 今週の残りの日をチェック（今日から1週間）
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      final targetWeekday = targetDate.weekday;
      final weekdayKey = _getWeekdayKey(targetWeekday);

      if (weekdayKey == null) continue;

      final daySchedule = schedule.timetable[weekdayKey];
      if (daySchedule == null) continue;

      final currentTime = TimeOfDay.fromDateTime(now);

      // 各時限をチェック
      for (int period = 1; period <= 10; period++) {
        final scheduleClass = daySchedule[period];
        if (scheduleClass == null) continue;

        // 連続講義の場合、開始セルのみ通知をスケジュール
        if (!scheduleClass.isStartCell) continue;

        // 時限の開始時刻を取得
        final timeSlot = schedule.timeSlots.firstWhere(
          (slot) => slot.period == period,
          orElse: () => TimeSlot(
            period: period,
            startTime: '${period + 8}:00',
            endTime: '${period + 9}:00',
          ),
        );

        // 開始時刻をパース
        final startTimeParts = timeSlot.startTime.split(':');
        final startHour = int.parse(startTimeParts[0]);
        final startMinute = int.parse(startTimeParts[1]);

        // 通知時刻を計算（10分前）
        final notificationTime = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          startHour,
          startMinute,
        ).subtract(const Duration(minutes: 10));

        // 現在時刻より過去の場合はスケジュールしない
        if (notificationTime.isBefore(now)) continue;

        // 通知ID
        final notificationId = _generateNotificationId(weekdayKey, period);

        // 通知内容
        final title = '📚 講義開始10分前';
        final body =
            '次の講義は「${scheduleClass.subjectName}」です。教室は「${scheduleClass.classroom}」です。出席ボタンを押しましょう！';

        // 通知をスケジュール
        await _notifications.zonedSchedule(
          notificationId,
          title,
          body,
          tz.TZDateTime.from(notificationTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'schedule_notifications',
              '講義通知',
              channelDescription: '講義開始前の通知を受け取ります',
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
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'schedule_${weekdayKey}_$period',
        );

        notificationCount++;
        debugPrint(
          '✅ 講義通知をスケジュール: $notificationTime - ${scheduleClass.subjectName}',
        );
      }
    }

    debugPrint('✅ 合計 $notificationCount 件の講義通知をスケジュールしました');
  }
}

