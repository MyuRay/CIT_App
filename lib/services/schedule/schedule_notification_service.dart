import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../core/utils/period_time_resolver.dart';
import '../../models/schedule/schedule_model.dart';
import 'class_notification_payload.dart';
import 'lecture_period_service.dart';

/// 授業ローカル通知サービス。
///
/// - 講義期間設定がある場合は、現在日から講義期間終了日までの授業通知をローカル予約する。
/// - 通知文言/通知タイミング/payload 形式の責務をここに集約する。
/// - 通知タップは `onNotificationTap` ストリーム / `consumePendingLaunchPayload` で
///   UI 側に届ける（具体的な遷移は呼び出し側 = MainScreen が担当）。
class ScheduleNotificationService {
  ScheduleNotificationService._();

  /// 授業開始の何分前に通知するか（将来「5分前/10分前/15分前」を選べるよう、ここに集約）。
  static const int classNotificationBeforeMinutes = 15;

  /// 講義期間が未設定のときのフォールバック予約期間。
  ///
  /// 通常は管理画面の講義期間（前期/後期）を使う。未設定でも通知が途切れにくいよう、
  /// 半期相当より長めに予約する。
  static const int fallbackScheduleHorizonDays = 180;

  /// Android の通知チャンネル ID/名/説明。
  static const String _channelId = 'class_attendance_notifications';
  static const String _channelName = '授業出席通知';
  static const String _channelDescription = '講義開始まもなくお知らせします';

  /// 通知 ID の名前空間。授業出席通知は `0x10000000` 以上に割り当て、
  /// 他のローカル通知 ID と衝突しないようにする。
  static const int _attendanceIdMin = 0x10000000;
  static const int _attendanceIdMask = 0x6FFFFFFF; // ~ 1.8e9（int32 範囲内）

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// 通知タップ用 broadcast Stream。
  static final StreamController<String> _tapStreamController =
      StreamController<String>.broadcast();

  /// 通知タップ payload を購読するストリーム。
  static Stream<String> get onNotificationTap => _tapStreamController.stream;

  /// アプリ完全終了状態から通知タップで起動された場合の payload を保持。
  static String? _pendingLaunchPayload;

  /// 起動時 payload を 1 度だけ取り出す。
  static String? consumePendingLaunchPayload() {
    final p = _pendingLaunchPayload;
    _pendingLaunchPayload = null;
    return p;
  }

  /// 初期化。`main.dart` 起動シーケンスから 1 度だけ呼ぶ。
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

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          debugPrint('🔔 通知タップ: $payload');
          _tapStreamController.add(payload);
        }
      },
    );

    // 完全終了からの起動時に通知タップで起動された場合、payload を保持。
    try {
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        final payload = launchDetails?.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          debugPrint('🔔 通知から起動: $payload');
          _pendingLaunchPayload = payload;
        }
      }
    } catch (e) {
      debugPrint('⚠️ getNotificationAppLaunchDetails 失敗: $e');
    }

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.high,
          ),
        );

    await _requestAndroidPermissions();

    _initialized = true;
    debugPrint('✅ ScheduleNotificationService initialized');
  }

  static Future<void> _requestAndroidPermissions() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return;
    try {
      final granted = await androidImpl.requestNotificationsPermission();
      debugPrint('📱 Android 通知権限: ${granted == true ? "許可" : "拒否"}');
    } catch (e) {
      debugPrint('⚠️ Android 通知権限リクエスト失敗: $e');
    }
  }

  /// すべての授業出席通知をキャンセル。
  ///
  /// 予約 ID が attendance 範囲（[_attendanceIdMin] 以上）のもののみを
  /// 個別キャンセルし、他のローカル通知（学食/掲示板など）には影響しない。
  static Future<void> cancelAllNotifications() async {
    if (!_initialized) {
      // 初期化前でも cancel() 自体は安全に呼べる。
      try {
        await initialize();
      } catch (_) {}
    }
    try {
      final pending = await _plugin.pendingNotificationRequests();
      var cancelled = 0;
      for (final req in pending) {
        if (req.id >= _attendanceIdMin) {
          await _plugin.cancel(req.id);
          cancelled++;
        }
      }
      debugPrint('🗑️ 授業出席通知をキャンセル: $cancelled 件');
    } catch (e) {
      debugPrint('⚠️ pendingNotificationRequests 取得失敗: $e。fallback: cancelAll');
      await _plugin.cancelAll();
    }
  }

  /// 現在の時間割から、講義期間終了日までの授業通知を予約する。
  ///
  /// - 既存の授業出席通知は事前にすべてキャンセルする。
  /// - 講義期間設定がある場合は、対象 semester の期間内だけ予約する。
  /// - 講義期間設定がない場合は [fallbackScheduleHorizonDays] 日分を予約する。
  /// - 通知時刻が現在より過去のものは予約しない。
  /// - 連続講義は開始セルのみを通知対象とする。
  /// - 無効な period（1〜10 以外）は対象外。
  static Future<void> scheduleWeeklyNotifications(Schedule schedule) async {
    if (!_initialized) {
      await initialize();
    }
    await cancelAllNotifications();

    final now = DateTime.now();
    final window = await _resolveScheduleWindow(schedule, now);
    int skipped = 0;
    int failed = 0;
    final scheduledList = <_ScheduledNotificationLog>[];

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🔔 授業通知 予約処理開始');
    debugPrint('   時間割: ${schedule.name ?? schedule.semester} (id=${schedule.id})');
    debugPrint(
      '   対象期間: ${_formatDate(window.start)} 〜 ${_formatDate(window.end)}',
    );
    debugPrint('   通知タイミング: 講義開始 $classNotificationBeforeMinutes 分前');

    var targetDate = window.start;
    while (!targetDate.isAfter(window.end)) {
      final weekdayKey = _weekdayKeyFromDateTime(targetDate.weekday);
      if (weekdayKey != null) {
        final daySchedule = schedule.timetable[weekdayKey];
        if (daySchedule != null) {
          for (int period = PeriodTimeResolver.minPeriod;
              period <= PeriodTimeResolver.maxPeriod;
              period++) {
            if (!PeriodTimeResolver.isValidPeriod(period)) continue;
            final scheduleClass = daySchedule[period];
            if (scheduleClass == null) continue;
            // 連続講義の中間セルは通知対象外（開始セルのみ通知）
            if (!scheduleClass.isStartCell) continue;

            final startDateTime =
                PeriodTimeResolver.startDateTimeFor(targetDate, period);
            final endDateTime =
                PeriodTimeResolver.endDateTimeFor(targetDate, period);
            if (startDateTime == null || endDateTime == null) continue;

            final notificationTime = startDateTime.subtract(
              const Duration(minutes: classNotificationBeforeMinutes),
            );
            if (!notificationTime.isAfter(now)) {
              skipped++;
              continue;
            }

            final subjectName = scheduleClass.subjectName.trim().isNotEmpty
                ? scheduleClass.subjectName.trim()
                : '次の授業';
            final classroom = scheduleClass.classroom.trim();

            final payload = ClassNotificationPayload(
              scheduleId: schedule.id,
              subjectName: subjectName,
              weekday: targetDate.weekday,
              period: period,
              classDate: DateTime(
                targetDate.year,
                targetDate.month,
                targetDate.day,
              ),
              startDateTime: startDateTime,
              endDateTime: endDateTime,
              classroom: classroom.isNotEmpty ? classroom : null,
            );

            const title = 'まもなく授業が始まります';
            final body = classroom.isNotEmpty
                ? 'まもなく「$subjectName」が始まります。教室：$classroom'
                : 'まもなく「$subjectName」が始まります';

            final notificationId = _attendanceNotificationIdFor(
              scheduleId: schedule.id,
              classDate: payload.classDate,
              period: period,
            );

            try {
              await _plugin.zonedSchedule(
                notificationId,
                title,
                body,
                tz.TZDateTime.from(notificationTime, tz.local),
                _buildNotificationDetails(body),
                androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
                uiLocalNotificationDateInterpretation:
                    UILocalNotificationDateInterpretation.absoluteTime,
                payload: payload.toJsonString(),
              );
              scheduledList.add(
                _ScheduledNotificationLog(
                  notificationTime: notificationTime,
                  startDateTime: startDateTime,
                  period: period,
                  subjectName: subjectName,
                  classroom: classroom,
                ),
              );
            } catch (e) {
              failed++;
              debugPrint(
                '❌ 通知予約失敗: ${_formatDate(targetDate)} ${period}限 $subjectName / $e',
              );
            }
          }
        }
      }
      targetDate = targetDate.add(const Duration(days: 1));
    }

    scheduledList.sort(
      (a, b) => a.notificationTime.compareTo(b.notificationTime),
    );

    debugPrint(
      '✅ 通知予約完了: 予約=${scheduledList.length}件 / スキップ(過去)=$skipped件 / 失敗=$failed件',
    );
    if (scheduledList.isEmpty) {
      debugPrint('   予約された通知はありません（対象期間内に未来の講義なし）');
    } else {
      debugPrint('   ── 予約済み通知一覧（通知時刻順） ──');
      for (final entry in scheduledList) {
        debugPrint('   ${entry.toLogLine()}');
      }
    }
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  static String _formatDate(DateTime d) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final wd = weekdays[(d.weekday - 1).clamp(0, 6)];
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}($wd)';
  }

  static String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static Future<DateTimeRange> _resolveScheduleWindow(
    Schedule schedule,
    DateTime now,
  ) async {
    final today = DateTime(now.year, now.month, now.day);
    try {
      final settings = await LecturePeriodService.getLecturePeriod();
      final isFall = schedule.semester.contains('後期');
      final startRaw = isFall ? settings?.fallStartDate : settings?.springStartDate;
      final endRaw = isFall ? settings?.fallEndDate : settings?.springEndDate;
      final legacyStart = settings?.lectureStartDate;
      final legacyEnd = settings?.lectureEndDate;

      final start = startRaw ?? (!isFall ? legacyStart : null);
      final end = endRaw ?? (!isFall ? legacyEnd : null);
      if (start != null && end != null) {
        final startDay = DateTime(start.year, start.month, start.day);
        final endDay = DateTime(end.year, end.month, end.day);
        if (!endDay.isBefore(today)) {
          return DateTimeRange(
            start: today.isAfter(startDay) ? today : startDay,
            end: endDay,
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ 講義期間設定の取得に失敗。fallbackで通知予約します: $e');
    }

    return DateTimeRange(
      start: today,
      end: today.add(const Duration(days: fallbackScheduleHorizonDays - 1)),
    );
  }

  /// `scheduleId` + `classDate` + `period` から決定的に通知 ID を生成する。
  /// attendance 用 ID 範囲（[_attendanceIdMin] 以上）に必ず収まるようにする。
  static int _attendanceNotificationIdFor({
    required String scheduleId,
    required DateTime classDate,
    required int period,
  }) {
    final dateKey =
        '${classDate.year}${classDate.month.toString().padLeft(2, '0')}${classDate.day.toString().padLeft(2, '0')}';
    final raw = '$scheduleId|$dateKey|$period';
    // dart の hashCode は負値も返すため、絶対値→マスクで非負整数化
    final base = raw.hashCode.abs() & _attendanceIdMask;
    return _attendanceIdMin | base;
  }

  static String? _weekdayKeyFromDateTime(int weekday) {
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
        return null; // 日曜は授業対象外
    }
  }

  static NotificationDetails _buildNotificationDetails(String body) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}

/// 予約済み通知のデバッグログ用の小さな値オブジェクト。
class _ScheduledNotificationLog {
  _ScheduledNotificationLog({
    required this.notificationTime,
    required this.startDateTime,
    required this.period,
    required this.subjectName,
    required this.classroom,
  });

  final DateTime notificationTime;
  final DateTime startDateTime;
  final int period;
  final String subjectName;
  final String classroom;

  String toLogLine() {
    final dateStr = ScheduleNotificationService._formatDate(notificationTime);
    final notifyAt = ScheduleNotificationService._formatTime(notificationTime);
    final startAt = ScheduleNotificationService._formatTime(startDateTime);
    final classroomPart = classroom.isNotEmpty ? ' / 教室: $classroom' : '';
    return '🔔 $dateStr  通知 $notifyAt  →  $startAt 開始  ${period}限「$subjectName」$classroomPart';
  }
}
