import 'dart:convert';
import 'package:cit_app/models/bus/bus_model.dart';
import 'package:cit_app/models/schedule/schedule_model.dart';
import 'package:cit_app/services/widget/home_widget_payloads.dart';
import 'package:cit_app/services/widget/home_widget_destination.dart';
import 'package:cit_app/services/widget/home_widgets_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final monday = DateTime.utc(2026, 9, 7, 1, 30); // 10:30 JST
  Schedule schedule() {
    const lesson = ScheduleClass(
      id: 'lesson',
      subjectName: '演習',
      instructor: '非公開の教員名',
      classroom: '701',
      color: '#2563EB',
      duration: 2,
      isStartCell: true,
      notes: 'private-note',
    );
    return Schedule(
      id: 'test',
      userId: 'private-user',
      semester: '後期',
      timeSlots: [
        const TimeSlot(period: 1, startTime: '09:15', endTime: '10:05'),
        const TimeSlot(period: 2, startTime: '10:15', endTime: '11:05'),
      ],
      timetable: {
        'monday': {
          1: lesson,
          2: ScheduleClass.fromJson({...lesson.toJson(), 'isStartCell': false}),
        },
        'tuesday': {},
      },
    );
  }

  test(
    'native snapshots use configured times and merge continuous classes',
    () {
      final weekly = HomeWidgetPayloads.weekly(schedule(), now: monday);
      final entries = weekly['monday'] as List;
      expect(entries, hasLength(1));
      expect(entries.single['startTime'], '09:15');
      expect(entries.single['endTime'], '11:05');
      expect(entries.single['endPeriod'], 2);
      final encoded = jsonEncode(weekly);
      expect(encoded, isNot(contains('private-')));
      expect(encoded, isNot(contains('非公開の教員名')));
      final today = HomeWidgetPayloads.today(weekly, monday);
      expect(today['currentPeriod'], 1);
    },
  );
  test(
    'a saved week advances the date in Japan without another app update',
    () {
      final weekly = HomeWidgetPayloads.weekly(schedule(), now: monday);
      final nextDay = HomeWidgetPayloads.today(
        weekly,
        DateTime.utc(2026, 9, 7, 15),
      );
      expect(nextDay['dateKey'], '2026-09-08');
      expect(nextDay['weekday'], '火');
      expect(nextDay['classes'], isEmpty);
      expect(nextDay['hasSchedule'], isTrue);
      expect(
        HomeWidgetPayloads.today(weekly, DateTime.utc(2026, 9, 13))['classes'],
        isEmpty,
      );
    },
  );
  test(
    'all ten periods export times, including empty and continuation cells',
    () {
      final weekly = HomeWidgetPayloads.weekly(schedule(), now: monday);
      final slots = weekly['timeSlots'] as List;
      expect(
        slots.map((slot) => slot['period']),
        List.generate(10, (i) => i + 1),
      );
      expect(slots[0], {'period': 1, 'startTime': '09:15', 'endTime': '10:05'});
      // A merged lecture must not hide the boundary between the two periods.
      expect(slots[1], {'period': 2, 'startTime': '10:15', 'endTime': '11:05'});
      expect(slots[2], {'period': 3, 'startTime': '11:00', 'endTime': '12:00'});
      expect(slots.last['endTime'], '19:00');
      expect(HomeWidgetPayloads.today(weekly, monday)['timeSlots'], slots);
      expect(
        HomeWidgetPayloads.weekly(null, now: monday)['timeSlots'],
        isEmpty,
      );
    },
  );
  test('missing times match the app defaults and preserve lecture range', () {
    final source = schedule();
    final weekly = HomeWidgetPayloads.weekly(
      Schedule(
        id: source.id,
        userId: source.userId,
        semester: source.semester,
        timetable: source.timetable,
      ),
      now: monday,
    );
    final lesson = (weekly['monday'] as List).single;
    expect(lesson['startTime'], '09:00');
    expect(lesson['endTime'], '11:00');
    expect(HomeWidgetPayloads.today(weekly, monday)['currentPeriod'], 1);
  });
  test(
    'custom slots are ordered by period and formatted without guessing invalid times',
    () {
      final source = schedule();
      final weekly = HomeWidgetPayloads.weekly(
        Schedule(
          id: source.id,
          userId: source.userId,
          semester: source.semester,
          timetable: source.timetable,
          timeSlots: const [
            TimeSlot(period: 10, startTime: '18:20', endTime: '19:10'),
            TimeSlot(period: 2, startTime: '10:20', endTime: 'invalid'),
            TimeSlot(period: 1, startTime: ' 9:05 ', endTime: '9:55'),
          ],
        ),
        now: monday,
      );
      final slots = weekly['timeSlots'] as List;
      expect(slots.first['startTime'], '09:05');
      expect(slots.first['endTime'], '09:55');
      expect(slots[1]['endTime'], isEmpty);
      expect(slots.last['endTime'], '19:10');
      final lesson = (weekly['monday'] as List).single;
      expect(lesson['startTime'], '09:05');
      expect(lesson['endTime'], isEmpty);
      expect(HomeWidgetPayloads.today(weekly, monday)['currentPeriod'], isNull);
    },
  );
  test('today tolerates a cached snapshot without period times', () {
    final weekly = HomeWidgetPayloads.weekly(schedule(), now: monday)
      ..remove('timeSlots');
    final today = HomeWidgetPayloads.today(weekly, monday);
    expect(today['timeSlots'], isEmpty);
    expect((today['classes'] as List).single['endTime'], '11:05');
  });
  test('logout is distinct from a day without classes', () {
    final empty = HomeWidgetPayloads.weekly(null, now: monday);
    expect(empty['hasSchedule'], isFalse);
    expect(HomeWidgetPayloads.today(empty, monday)['classes'], isEmpty);
  });
  test('bus exports dated departures and expires at Japan midnight', () {
    final info = BusInformation(
      id: 'bus',
      title: '学バス',
      description: '',
      operationPeriods: [],
      lastUpdated: monday,
      updatedBy: 'private-admin',
      routes: [
        const BusRoute(
          id: 'route',
          name: '津田沼 → 新習志野',
          description: '',
          sortOrder: 1,
          isActive: true,
          timeEntries: [
            BusTimeEntry(id: 'weekday', hour: 11, minute: 0, isActive: true),
            BusTimeEntry(
              id: 'weekend',
              hour: 12,
              minute: 0,
              dayType: 'saturday',
              isActive: true,
            ),
            BusTimeEntry(id: 'disabled', hour: 13, minute: 0, isActive: false),
          ],
        ),
      ],
    );
    final payload = HomeWidgetPayloads.bus(info, now: monday);
    final route = (payload['routes'] as List).single;
    expect(route['departures'], hasLength(1));
    expect(
      route['departures'][0]['departureAt'],
      DateTime.utc(2026, 9, 7, 2).millisecondsSinceEpoch,
    );
    expect(
      payload['expiresAt'],
      DateTime.utc(2026, 9, 7, 15).millisecondsSinceEpoch,
    );
    expect(jsonEncode(payload), isNot(contains('private-admin')));
  });
  test('Android and iOS widget links share destinations', () {
    expect(
      homeWidgetDestination(Uri.parse('citapp://schedule?homeWidget=true')),
      '/home?tab=schedule',
    );
    expect(
      homeWidgetDestination(Uri.parse('citapp://bus?homeWidget=true')),
      '/bus',
    );
    expect(homeWidgetDestination(Uri.parse('/schedule')), '/home?tab=schedule');
    expect(
      homeWidgetDestination(Uri.parse('https://example.com/schedule')),
      isNull,
    );
    expect(homeWidgetDestination(Uri.parse('citapp://unknown')), isNull);
  });
  test(
    'iOS initializes App Group before saving and refreshes both widget kinds',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final calls = <MethodCall>[];
      const channel = MethodChannel('home_widget');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return true;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      await HomeWidgetsService.clearUserSchedule();
      expect(calls.first.method, 'setAppGroupId');
      expect(
        calls.where((call) => call.method == 'saveWidgetData'),
        hasLength(2),
      );
      final reloads =
          calls
              .where((call) => call.method == 'updateWidget')
              .map((call) => call.arguments['ios'])
              .toSet();
      expect(reloads, {
        'FullScheduleWidgetProvider',
        'TodayScheduleWidgetProvider',
      });
    },
  );
}
