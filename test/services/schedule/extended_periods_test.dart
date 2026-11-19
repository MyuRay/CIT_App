import 'dart:convert';
import 'package:cit_app/core/utils/period_time_resolver.dart';
import 'package:cit_app/models/schedule/lecture_period_model.dart';
import 'package:cit_app/models/schedule/schedule_model.dart';
import 'package:cit_app/services/schedule/attendance_service.dart';
import 'package:cit_app/services/schedule/lecture_period_service.dart';
import 'package:cit_app/services/schedule/schedule_class_edit.dart';
import 'package:cit_app/services/schedule/schedule_service.dart';
import 'package:cit_app/services/schedule/excel_schedule_import_service.dart';
import 'package:cit_app/services/widget/home_widget_payloads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

const _lesson = ScheduleClass(
  id: 'late',
  subjectName: '夜間演習',
  classroom: '101',
  instructor: '担当',
  color: '#2196F3',
  notes: '保持するメモ',
  duration: 2,
);

void main() {
  late FakeFirebaseFirestore db;
  late Schedule original;
  setUp(() {
    db = FakeFirebaseFirestore();
    ScheduleService.firestoreOverride = db;
    AttendanceService.firestoreOverride = db;
    LecturePeriodService.firestoreOverride = db;
    original = DefaultTimeSlots.createDefault(
      id: 'week',
      userId: 'owner',
      semester: '2026年度後期',
    );
  });
  tearDown(() {
    ScheduleService.firestoreOverride = null;
    AttendanceService.firestoreOverride = null;
    LecturePeriodService.firestoreOverride = null;
  });

  test(
    'five-hour lectures occupy every cell and reject overlaps in the fifth cell',
    () {
      const lesson = ScheduleClass(
        id: 'long',
        subjectName: '集中講義',
        classroom: '101',
        instructor: '担当',
        color: '#2196F3',
        duration: 5,
      );
      final edited = applyScheduleClassEdit(
        schedule: original,
        weekdayKey: 'monday',
        period: 3,
        replacement: lesson,
      );
      for (var period = 3; period <= 7; period++) {
        expect(edited['monday']![period]!.duration, 5);
        expect(edited['monday']![period]!.isStartCell, period == 3);
      }
      final occupied = Schedule(
        id: original.id,
        userId: original.userId,
        semester: original.semester,
        timetable: {
          'monday': {7: _lesson},
        },
      );
      expect(
        () => applyScheduleClassEdit(
          schedule: occupied,
          weekdayKey: 'monday',
          period: 3,
          replacement: lesson,
        ),
        throwsA(isA<ScheduleClassOverlap>()),
      );
      expect(
        () => applyScheduleClassEdit(
          schedule: original,
          weekdayKey: 'monday',
          period: 8,
          replacement: lesson,
        ),
        throwsStateError,
      );
    },
  );

  test(
    'old timetables retain ten rows and added empty rows survive both storage formats',
    () {
      expect(Schedule.fromJson(original.toJson()).periodCount, 10);
      var expanded = original;
      for (var count = 11; count <= PeriodTimeResolver.maxPeriod; count++) {
        expanded = expanded.withAdditionalPeriod();
        for (final json in [
          expanded.toJson(),
          expanded.toJsonWithListTimeSlots(),
        ]) {
          final restored = Schedule.fromJson(
            jsonDecode(
              jsonEncode(
                json,
                toEncodable:
                    (v) => v is Timestamp ? v.toDate().toIso8601String() : v,
              ),
            ),
          );
          expect(restored.periodCount, count);
          expect(restored.timeSlots.last.period, count);
          for (final day in Weekday.values) {
            expect(restored.timetable[day.name]!.containsKey(count), isTrue);
            expect(restored.timetable[day.name]![count], isNull);
          }
        }
      }
      expect(expanded.withAdditionalPeriod, throwsStateError);
      expect(original.periodCount, 10);
      expect(original.timetable['monday']!.containsKey(11), isFalse);
    },
  );

  test(
    'adding a row retains the latest persisted lesson, custom times and other timetables',
    () async {
      await db
          .doc('schedules/week')
          .set(
            jsonDecode(
              jsonEncode(
                original.toJsonWithListTimeSlots(),
                toEncodable:
                    (value) =>
                        value is Timestamp
                            ? value.toDate().toIso8601String()
                            : value,
              ),
            ),
          );
      await db.doc('schedules/other').set(original.toJson());
      await db.doc('schedules/week').update({
        'timetable.monday.1': _lesson.toJson(),
      });
      final expanded = await ScheduleService.addPeriod(scheduleId: 'week');
      expect(expanded.periodCount, 11);
      final restored = Schedule.fromFirestore(
        await db.doc('schedules/week').get(),
      );
      expect(restored.timetable['monday']![1]!.notes, _lesson.notes);
      expect(restored.periodCount, 11);
      expect(
        Schedule.fromFirestore(
          await db.doc('schedules/other').get(),
        ).periodCount,
        10,
      );
      await expectLater(
        ScheduleService.addPeriod(scheduleId: 'missing'),
        throwsStateError,
      );
    },
  );

  test(
    '11-12 period lesson survives edit, move, overlap rejection and removal',
    () async {
      final expanded = original.withAdditionalPeriod().withAdditionalPeriod();
      await db.doc('schedules/week').set(expanded.toJson());
      await ScheduleService.saveClass(
        scheduleId: 'week',
        weekdayKey: 'monday',
        period: 11,
        scheduleClass: _lesson,
      );
      var restored = Schedule.fromFirestore(
        await db.doc('schedules/week').get(),
      );
      expect(restored.timetable['monday']![12]!.isStartCell, isFalse);
      final moved = await ScheduleService.moveClass(
        scheduleId: 'week',
        fromWeekdayKey: 'monday',
        fromPeriod: 11,
        toWeekdayKey: 'saturday',
        toPeriod: 11,
        expectedClass: _lesson,
      );
      expect(moved.timetable['monday']![11], isNull);
      expect(moved.timetable['saturday']![11]!.notes, _lesson.notes);
      expect(
        () => applyScheduleClassEdit(
          schedule: moved,
          weekdayKey: 'saturday',
          period: 11,
          replacement: _lesson,
        ),
        throwsA(isA<ScheduleClassOverlap>()),
      );
      await expectLater(
        ScheduleService.saveClass(
          scheduleId: 'week',
          weekdayKey: 'friday',
          period: 12,
          scheduleClass: _lesson,
        ),
        throwsStateError,
      );
      await ScheduleService.removeClass(
        scheduleId: 'week',
        weekdayKey: 'saturday',
        period: 11,
        expectedClass: _lesson,
      );
      restored = Schedule.fromFirestore(await db.doc('schedules/week').get());
      expect(restored.periodCount, 12);
      expect(restored.timetable['saturday']![11], isNull);
      expect(restored.timetable['saturday']![12], isNull);
    },
  );

  test(
    'clear timetable preserves expanded row count and last-day times',
    () async {
      var expanded = original;
      for (var i = 10; i < 15; i++) {
        expanded = expanded.withAdditionalPeriod();
      }
      await db.doc('schedules/week').set(expanded.toJson());
      await ScheduleService.clearSchedule('week');
      final cleared = Schedule.fromFirestore(
        await db.doc('schedules/week').get(),
      );
      expect(cleared.periodCount, 15);
      expect(cleared.timeSlots.last.endTime, '24:00');
      expect(
        PeriodTimeResolver.startDateTimeFor(DateTime(2026, 10, 22), 11),
        DateTime(2026, 10, 22, 19),
      );
      expect(
        PeriodTimeResolver.endDateTimeFor(DateTime(2026, 10, 22), 15),
        DateTime(2026, 10, 23),
      );
      expect(
        PeriodTimeResolver.startDateTimeFor(DateTime(2026, 10, 22), 16),
        isNull,
      );
    },
  );

  test(
    'widget snapshots retain extended lessons and the midnight end boundary',
    () {
      final expanded = Schedule(
        id: 'week',
        userId: 'owner',
        semester: '後期',
        timeSlots: DefaultTimeSlots.forPeriodCount(15),
        timetable: {
          'monday': {
            14: _lesson,
            15: ScheduleClass.fromJson({
              ..._lesson.toJson(),
              'isStartCell': false,
            }),
          },
        },
      );
      final weekly = HomeWidgetPayloads.weekly(
        expanded,
        now: DateTime.utc(2026, 10, 19),
      );
      expect(weekly['periodCount'], 15);
      expect((weekly['timeSlots'] as List).length, 15);
      final entry = (weekly['monday'] as List).single;
      expect(entry['period'], 14);
      expect(entry['endTime'], '24:00');
      expect(
        HomeWidgetPayloads.today(
          weekly,
          DateTime.utc(2026, 10, 19, 14, 30),
        )['currentPeriod'],
        14,
      );
      expect(
        HomeWidgetPayloads.today(
          weekly,
          DateTime.utc(2026, 10, 19, 15),
        )['classes'],
        isEmpty,
      );
    },
  );

  test(
    'Excel import extends time definitions and retains late lessons on reload',
    () async {
      await db.doc('schedules/week').set(original.toJson());
      final result = await ExcelScheduleImportService.applyImport(
        scheduleId: 'week',
        entries: const [
          ImportedScheduleEntry(
            subjectName: '夜間演習',
            instructor: '担当',
            classroom: '101',
            weekdayKey: 'monday',
            startPeriod: 11,
            duration: 2,
          ),
        ],
        clearExisting: true,
        autoColorAdjacent: false,
      );
      expect(result.appliedCount, 1);
      final restored = Schedule.fromFirestore(
        await db.doc('schedules/week').get(),
      );
      expect(restored.periodCount, 12);
      expect(restored.timeSlots.last.endTime, '21:00');
      expect(restored.timetable['monday']![11]!.subjectName, '夜間演習');
      expect(restored.timetable['monday']![12]!.isStartCell, isFalse);
    },
  );

  test(
    'attendance uses the selected term, never the other term or another academic year',
    () async {
      final settings = LecturePeriodSettings(
        springStartDate: DateTime(2026, 4, 8),
        springEndDate: DateTime(2026, 7, 31),
        fallStartDate: DateTime(2026, 9, 17),
        fallEndDate: DateTime(2027, 1, 31),
      );
      expect(settings.startDateForSemester('2026年度前期'), DateTime(2026, 4, 8));
      expect(settings.startDateForSemester('2026年度秋学期'), DateTime(2026, 9, 17));
      expect(settings.startDateForSemester('2025年度後期'), isNull);
      expect(
        settings.containsDateForSemester(DateTime(2027, 1, 11), '2026年度後期'),
        isTrue,
      );
      expect(
        settings.containsDateForSemester(DateTime(2026, 10, 19), '2026年度前期'),
        isFalse,
      );
      expect(
        LecturePeriodSettings(
          springStartDate: DateTime(2026, 4, 8),
        ).startDateForSemester('後期'),
        isNull,
      );
      await db.doc('app_settings/lecture_period').set(settings.toMap());
      final expanded = original.withAdditionalPeriod().withAdditionalPeriod();
      final result = await AttendanceService.markAttendanceFromTap(
        userId: 'owner',
        scheduleId: expanded.id,
        schedule: expanded,
        weekdayKey: 'monday',
        startPeriod: 11,
        scheduleClass: _lesson,
        now: DateTime(2026, 10, 19, 18, 50),
      );
      expect(result.success, isTrue);
      expect(
        (await db.collection('attendance_records').get()).docs.single
            .data()['startPeriod'],
        11,
      );
    },
  );
}
