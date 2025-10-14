import 'dart:convert';
import 'dart:io';
import 'package:home_widget/home_widget.dart';
import '../../models/schedule/schedule_model.dart';
import '../../models/bus/bus_model.dart';

class HomeWidgetsService {
  static const String _weeklyWidgetName = 'FullScheduleWidgetProvider';
  static const String _busWidgetName = 'BusRealtimeWidgetProvider';

  // Keys
  static const String _keyWeeklyFull = 'weekly_full_schedule';
  static const String _keyBusRealtime = 'bus_realtime';
  static const String _keyLastUpdate = 'last_update';

  static Future<void> initialize() async {
    try {
      if (Platform.isIOS) {
        await HomeWidget.setAppGroupId('group.com.cit.app');
      }
    } catch (_) {}
  }

  /// 週間フル時間割ウィジェットを更新（空スロットは送らない）
  static Future<void> updateWeeklyFullSchedule(Schedule schedule) async {
    final weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    final weeklyData = <String, dynamic>{};

    for (final day in weekdays) {
      final daySchedule = schedule.timetable[day];
      if (daySchedule != null) {
        final list = <Map<String, dynamic>>[];
        for (var i = 1; i <= 10; i++) {
          final c = daySchedule[i];
          if (c != null) {
            list.add({
              'period': i,
              'subject': c.subjectName,
              'classroom': c.classroom,
              'color': c.color,
              'duration': c.duration,
            });
          }
        }
        weeklyData[day] = list;
      } else {
        weeklyData[day] = <Map<String, dynamic>>[];
      }
    }

    await HomeWidget.saveWidgetData<String>(_keyWeeklyFull, jsonEncode(weeklyData));
    await HomeWidget.saveWidgetData<String>(_keyLastUpdate, DateTime.now().millisecondsSinceEpoch.toString());
    await HomeWidget.updateWidget(name: _weeklyWidgetName, androidName: _weeklyWidgetName);
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
    await HomeWidget.updateWidget(name: _busWidgetName, androidName: _busWidgetName);
  }
}

