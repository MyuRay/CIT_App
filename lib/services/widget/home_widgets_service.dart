import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../../models/schedule/schedule_model.dart';
import '../../models/bus/bus_model.dart';

class HomeWidgetsService {
  static const String _weeklyWidgetName = 'FullScheduleWidgetProvider';
  static const String _busWidgetName = 'BusRealtimeWidgetProvider';
  static const String _todayScheduleWidgetName = 'TodayScheduleWidgetProvider';

  // Keys
  static const String _keyWeeklyFull = 'weekly_full_schedule';
  static const String _keyBusRealtime = 'bus_realtime';
  static const String _keyTodaySchedule = 'today_schedule';
  static const String _keyLastUpdate = 'last_update';

  static Future<void> initialize() async {
    try {
      if (Platform.isIOS) {
        await HomeWidget.setAppGroupId('group.com.cit.app');
      }
      debugPrint('✅ ホームウィジェットサービスを初期化しました');
    } catch (e) {
      debugPrint('❌ ホームウィジェットサービス初期化エラー: $e');
    }
  }

  /// 週間フル時間割ウィジェットを更新（空スロットは送らない）
  /// scheduleがnullの場合は空データを送信
  static Future<void> updateWeeklyFullSchedule(Schedule? schedule) async {
    try {
      debugPrint('📱 週間時間割ウィジェット更新開始');
      final weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
      final weeklyData = <String, dynamic>{};

      if (schedule == null) {
        debugPrint('⚠️ スケジュールがnullのため、空データを送信');
        for (final day in weekdays) {
          weeklyData[day] = <Map<String, dynamic>>[];
        }
      } else {
        for (final day in weekdays) {
          final daySchedule = schedule.timetable[day];
          if (daySchedule != null) {
            final list = <Map<String, dynamic>>[];
            for (var i = 1; i <= 10; i++) {
              final c = daySchedule[i];
              if (c != null) {
                list.add({
                  'period': i,
                  'subject': c.subjectName.isNotEmpty ? c.subjectName : '未設定',
                  'classroom': c.classroom.isNotEmpty ? c.classroom : '',
                  'color': c.color.isNotEmpty ? c.color : '#2196F3',
                  'duration': c.duration,
                });
              }
            }
            weeklyData[day] = list;
            debugPrint('  $day: ${list.length}件の授業');
          } else {
            weeklyData[day] = <Map<String, dynamic>>[];
            debugPrint('  $day: 授業なし');
          }
        }
      }

      final jsonString = jsonEncode(weeklyData);
      debugPrint('📱 ウィジェットデータを保存: ${jsonString.length}文字');
      debugPrint('📱 データ内容: ${jsonString.substring(0, jsonString.length > 200 ? 200 : jsonString.length)}...');
      
      // データを保存
      try {
        await HomeWidget.saveWidgetData<String>(_keyWeeklyFull, jsonString);
        debugPrint('✅ ウィジェットデータ保存完了');
        
        // データ保存の確認（Androidで確実に保存されるように少し待つ）
        if (Platform.isAndroid) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      } catch (e) {
        debugPrint('❌ ウィジェットデータ保存エラー: $e');
        rethrow;
      }
      
      try {
        await HomeWidget.saveWidgetData<String>(_keyLastUpdate, DateTime.now().millisecondsSinceEpoch.toString());
        debugPrint('✅ 最終更新時刻保存完了');
      } catch (e) {
        debugPrint('⚠️ 最終更新時刻保存エラー: $e (続行)');
      }
      
      // ウィジェットを更新（データ保存後に実行）
      try {
        await HomeWidget.updateWidget(
          name: _weeklyWidgetName,
          androidName: _weeklyWidgetName,
          qualifiedAndroidName: 'jp.ac.chibakoudai.citapp.widget.$_weeklyWidgetName',
        );
        debugPrint('✅ 週間時間割ウィジェット更新完了');
      } catch (e) {
        debugPrint('❌ ウィジェット更新呼び出しエラー: $e');
        // 更新呼び出しに失敗してもデータは保存されているので、次回の自動更新で表示される
        // Androidの場合、ウィジェットは定期的に自動更新される
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 週間時間割ウィジェット更新エラー: $e');
      debugPrint('❌ StackTrace: $stackTrace');
      // エラー時は空データを送信してウィジェットを更新
      try {
        final emptyData = <String, dynamic>{
          'monday': <Map<String, dynamic>>[],
          'tuesday': <Map<String, dynamic>>[],
          'wednesday': <Map<String, dynamic>>[],
          'thursday': <Map<String, dynamic>>[],
          'friday': <Map<String, dynamic>>[],
          'saturday': <Map<String, dynamic>>[],
        };
        await HomeWidget.saveWidgetData<String>(_keyWeeklyFull, jsonEncode(emptyData));
        await HomeWidget.updateWidget(
          name: _weeklyWidgetName,
          androidName: _weeklyWidgetName,
          qualifiedAndroidName: 'jp.ac.chibakoudai.citapp.widget.$_weeklyWidgetName',
        );
        debugPrint('⚠️ エラー時の空データでウィジェットを更新しました');
      } catch (e2) {
        debugPrint('❌ 空データ送信も失敗: $e2');
      }
    }
  }

  /// 学バスリアルタイムウィジェットを更新
  /// preferredCampus: 'tsudanuma' or 'narashino'
  static Future<void> updateBusRealtime(BusInformation? info, {String preferredCampus = 'tsudanuma'}) async {
    Map<String, dynamic> payload;
    if (info == null) {
      payload = {'routes': []};
    } else {
      var routes = info.activeRoutes;
      // 優先キャンパスの路線を先頭に（出発地でおおまかに判定）
      int cmp(BusRoute a, BusRoute b) {
        bool startsFrom(BusRoute r, String campusLabel) {
          final name = r.name;
          final idxArrow = name.indexOf('→');
          final idxCampus = name.indexOf(campusLabel);
          return idxCampus >= 0 && (idxArrow < 0 || idxCampus < idxArrow);
        }

        final pa = startsFrom(a, preferredCampus == 'narashino' ? '新習志野' : '津田沼');
        final pb = startsFrom(b, preferredCampus == 'narashino' ? '新習志野' : '津田沼');
        if (pa == pb) return 0;
        return pa ? -1 : 1;
      }
      routes = [...routes]..sort(cmp);

      final items = <Map<String, dynamic>>[];
      for (final r in routes) {
        final next = r.getNextBusTime();
        if (next != null) {
          final now = DateTime.now();
          final nextDt = DateTime(now.year, now.month, now.day, next.hour, next.minute);
          final diff = nextDt.difference(now).inMinutes;
          items.add({
            'name': r.name,
            'nextTime': next.timeString,
            'minutesUntil': diff,
            'note': next.note,
          });
        }
        if (items.length >= 2) break; // 最大2路線表示
      }
      payload = {'routes': items};
    }

    await HomeWidget.saveWidgetData<String>(_keyBusRealtime, jsonEncode(payload));
    await HomeWidget.saveWidgetData<String>(_keyLastUpdate, DateTime.now().millisecondsSinceEpoch.toString());
    await HomeWidget.updateWidget(
      name: _busWidgetName,
      androidName: _busWidgetName,
      qualifiedAndroidName: 'jp.ac.chibakoudai.citapp.widget.$_busWidgetName',
    );
  }

  /// 今日の時間割ウィジェットを更新
  /// todayClassesがnullまたは空の場合は空データを送信
  static Future<void> updateTodaySchedule(List<ScheduleClass?>? todayClasses, {int? currentPeriod}) async {
    try {
      debugPrint('📱 今日の時間割ウィジェット更新開始');
      
      final now = DateTime.now();
      final weekdayNames = ['月', '火', '水', '木', '金', '土'];
      final weekdayIndex = now.weekday - 1; // Monday = 0
      final weekdayName = weekdayIndex < weekdayNames.length ? weekdayNames[weekdayIndex] : '';

      final todayData = <String, dynamic>{
        'weekday': weekdayName,
        'date': '${now.month}/${now.day}',
        'currentPeriod': currentPeriod,
        'classes': <Map<String, dynamic>>[],
      };

      if (todayClasses != null && todayClasses.isNotEmpty) {
        final classes = <Map<String, dynamic>>[];
        for (int i = 0; i < todayClasses.length; i++) {
          final scheduleClass = todayClasses[i];
          if (scheduleClass != null) {
            // 連続講義の開始セルのみ表示
            if (scheduleClass.isStartCell) {
              classes.add({
                'period': i + 1,
                'subject': scheduleClass.subjectName.isNotEmpty ? scheduleClass.subjectName : '未設定',
                'classroom': scheduleClass.classroom.isNotEmpty ? scheduleClass.classroom : '',
                'color': scheduleClass.color.isNotEmpty ? scheduleClass.color : '#2196F3',
                'duration': scheduleClass.duration,
                'startTime': _getPeriodStartTime(i + 1),
                'endTime': _getPeriodEndTime(i + 1, scheduleClass.duration),
              });
            }
          }
        }
        todayData['classes'] = classes;
        debugPrint('  ${classes.length}件の授業を登録');
      } else {
        debugPrint('  今日は授業なし');
      }

      final jsonString = jsonEncode(todayData);
      debugPrint('📱 今日の時間割ウィジェットデータを保存: ${jsonString.length}文字');
      
      // データを保存
      try {
        await HomeWidget.saveWidgetData<String>(_keyTodaySchedule, jsonString);
        debugPrint('✅ ウィジェットデータ保存完了');
        
        // データ保存の確認（Androidで確実に保存されるように少し待つ）
        if (Platform.isAndroid) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      } catch (e) {
        debugPrint('❌ ウィジェットデータ保存エラー: $e');
        rethrow;
      }
      
      try {
        await HomeWidget.saveWidgetData<String>(_keyLastUpdate, DateTime.now().millisecondsSinceEpoch.toString());
        debugPrint('✅ 最終更新時刻保存完了');
      } catch (e) {
        debugPrint('⚠️ 最終更新時刻保存エラー: $e (続行)');
      }
      
      // ウィジェットを更新（データ保存後に実行）
      try {
        await HomeWidget.updateWidget(
          name: _todayScheduleWidgetName,
          androidName: _todayScheduleWidgetName,
          qualifiedAndroidName: 'jp.ac.chibakoudai.citapp.widget.$_todayScheduleWidgetName',
        );
        debugPrint('✅ 今日の時間割ウィジェット更新完了');
      } catch (e) {
        debugPrint('❌ ウィジェット更新呼び出しエラー: $e');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 今日の時間割ウィジェット更新エラー: $e');
      debugPrint('❌ StackTrace: $stackTrace');
      // エラー時は空データを送信してウィジェットを更新
      try {
        final emptyData = <String, dynamic>{
          'weekday': '',
          'date': '',
          'currentPeriod': null,
          'classes': <Map<String, dynamic>>[],
        };
        await HomeWidget.saveWidgetData<String>(_keyTodaySchedule, jsonEncode(emptyData));
        await HomeWidget.updateWidget(
          name: _todayScheduleWidgetName,
          androidName: _todayScheduleWidgetName,
          qualifiedAndroidName: 'jp.ac.chibakoudai.citapp.widget.$_todayScheduleWidgetName',
        );
        debugPrint('⚠️ エラー時の空データでウィジェットを更新しました');
      } catch (e2) {
        debugPrint('❌ 空データ送信も失敗: $e2');
      }
    }
  }

  /// 時限の開始時刻を取得（CITの時間割に基づく）
  static String _getPeriodStartTime(int period) {
    const times = [
      '9:00',  // 1限
      '10:40', // 2限
      '13:00', // 3限
      '14:40', // 4限
      '16:20', // 5限
      '18:00', // 6限
      '19:40', // 7限
      '21:20', // 8限
      '9:00',  // 9限（未使用）
      '9:00',  // 10限（未使用）
    ];
    return period >= 1 && period <= times.length ? times[period - 1] : '9:00';
  }

  /// 時限の終了時刻を取得（連続講義を考慮）
  static String _getPeriodEndTime(int period, int duration) {
    const times = [
      '10:30', // 1限
      '12:10', // 2限
      '14:30', // 3限
      '16:10', // 4限
      '17:50', // 5限
      '19:30', // 6限
      '21:10', // 7限
      '22:50', // 8限
      '10:30', // 9限（未使用）
      '10:30', // 10限（未使用）
    ];
    final endPeriod = period + duration - 1;
    return endPeriod >= 1 && endPeriod <= times.length ? times[endPeriod - 1] : '10:30';
  }
}

