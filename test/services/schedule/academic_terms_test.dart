import 'package:cit_app/models/schedule/academic_term.dart';
import 'package:cit_app/models/schedule/lecture_period_model.dart';
import 'package:cit_app/models/schedule/schedule_model.dart';
import 'package:cit_app/services/schedule/lecture_period_service.dart';
import 'package:cit_app/services/schedule/schedule_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  setUp(() {
    db = FakeFirebaseFirestore();
    ScheduleService.firestoreOverride = db;
    LecturePeriodService.firestoreOverride = db;
  });
  tearDown(() {
    ScheduleService.firestoreOverride = null;
    LecturePeriodService.firestoreOverride = null;
  });
  LecturePeriod period(int year, bool fall, {bool active = true}) =>
      LecturePeriod(
        year: year,
        isFall: fall,
        startDate: DateTime(year, fall ? 9 : 4, 8),
        endDate: DateTime(fall ? year + 1 : year, fall ? 1 : 7, 31),
        isActive: active,
      );
  Future<void> settle() => Future<void>.delayed(Duration.zero);
  test(
    'academic years follow April boundary and legacy labels remain readable',
    () {
      expect(AcademicTerm.currentYear(DateTime(2027, 3, 31)), 2026);
      expect(AcademicTerm.currentYear(DateTime(2027, 4, 1)), 2027);
      expect(AcademicTerm.parse('2026年度秋学期')!.label, '2026年度後期');
      expect(AcademicTerm.parse('2026年前期')!.key, '2026_spring');
      expect(AcademicTerm.parse('自由な名前'), isNull);
    },
  );
  test(
    'adding multiple years preserves every period and unrelated settings',
    () async {
      await db.doc('app_settings/lecture_period').set({'legacy': 'keep'});
      for (final p in [
        period(2025, false),
        period(2026, false),
        period(2026, true),
      ]) {
        await LecturePeriodService.savePeriod(p, createOnly: true);
        await settle();
      }
      final settings = (await LecturePeriodService.getLecturePeriod())!;
      expect(settings.periods.length, 3);
      expect(settings.startDateForSemester('2025年度前期'), DateTime(2025, 4, 8));
      expect(settings.startDateForSemester('2026年度後期'), DateTime(2026, 9, 8));
      expect(
        settings.containsDateForSemester(DateTime(2027, 1, 20), '2026年度後期'),
        isTrue,
      );
      expect(settings.startDateForSemester('2027年度前期'), isNull);
      expect(settings.startDateForSemester('自由な名前'), isNull);
      expect(
        (await db.doc('app_settings/lecture_period').get()).data()!['legacy'],
        'keep',
      );
    },
  );
  test(
    'disabled term takes precedence over legacy dates and other years stay active',
    () {
      final settings = LecturePeriodSettings(
        springStartDate: DateTime(2026, 4, 8),
        springEndDate: DateTime(2026, 7, 31),
        periods: {
          '2026_spring': period(2026, false, active: false),
          '2025_spring': period(2025, false),
        },
      );
      expect(settings.startDateForSemester('2026年度前期'), isNull);
      expect(settings.containsDate(DateTime(2026, 5, 1)), isFalse);
      expect(settings.containsDate(DateTime(2025, 5, 1)), isTrue);
      final restored = LecturePeriodSettings.fromMap(settings.toMap());
      expect(restored.periods['2026_spring']!.isActive, isFalse);
    },
  );
  test(
    'duplicate additions and invalid academic date ranges do not overwrite',
    () async {
      await LecturePeriodService.savePeriod(
        period(2026, false),
        createOnly: true,
      );
      await settle();
      await expectLater(
        LecturePeriodService.savePeriod(
          period(2026, false, active: false),
          createOnly: true,
        ),
        throwsStateError,
      );
      await expectLater(
        LecturePeriodService.savePeriod(
          LecturePeriod(
            year: 2026,
            isFall: false,
            startDate: DateTime(2026, 3, 1),
            endDate: DateTime(2026, 7, 1),
          ),
        ),
        throwsArgumentError,
      );
      expect(
        (await LecturePeriodService.getLecturePeriod())!
            .periods['2026_spring']!
            .isActive,
        isTrue,
      );
    },
  );
  test(
    'removing empty extensions keeps ten base periods and custom slot times',
    () {
      final base = DefaultTimeSlots.createDefault(id: 'week', userId: 'owner');
      var schedule = base.withAdditionalPeriod().withAdditionalPeriod();
      schedule = schedule.withoutLastPeriod();
      expect(schedule.periodCount, 11);
      expect(Schedule.fromJson(schedule.toJson()).periodCount, 11);
      expect(
        schedule.timetable.values.every((day) => !day.containsKey(12)),
        isTrue,
      );
      expect(schedule.withoutLastPeriod().periodCount, 10);
      expect(base.withoutLastPeriod, throwsStateError);
    },
  );
  test(
    'occupied tail requires confirmation and removes entire spanning lesson only',
    () {
      final expanded =
          DefaultTimeSlots.createDefault(
            id: 'week',
            userId: 'owner',
          ).withAdditionalPeriod();
      const start = ScheduleClass(
        id: 'spanning',
        subjectName: '演習',
        classroom: '',
        instructor: '',
        color: '#2196F3',
        duration: 2,
      );
      expanded.timetable['monday']![10] = start;
      expanded.timetable['monday']![11] = const ScheduleClass(
        id: 'spanning',
        subjectName: '演習',
        classroom: '',
        instructor: '',
        color: '#2196F3',
        isStartCell: false,
      );
      expanded.timetable['tuesday']![1] = const ScheduleClass(
        id: 'keep',
        subjectName: '残す',
        classroom: '',
        instructor: '',
        color: '#2196F3',
      );
      expect(expanded.withoutLastPeriod, throwsStateError);
      final reduced = expanded.withoutLastPeriod(removeClasses: true);
      expect(reduced.timetable['monday']![10], isNull);
      expect(reduced.timetable['tuesday']![1]!.id, 'keep');
      expect(expanded.timetable['monday']![10], isNotNull);
    },
  );
  test(
    'transaction refuses stale period counts and preserves latest lessons',
    () async {
      final expanded =
          DefaultTimeSlots.createDefault(
            id: 'week',
            userId: 'owner',
          ).withAdditionalPeriod();
      await db.doc('schedules/week').set(expanded.toJson());
      await db.doc('schedules/week').update({
        'name': '最新の名前',
        'timetable': {
          'monday': {
            '1':
                const ScheduleClass(
                  id: 'latest',
                  subjectName: '新しい科目',
                  classroom: '',
                  instructor: '',
                  color: '#2196F3',
                ).toJson(),
          },
        },
      });
      await expectLater(
        ScheduleService.removeLastPeriod(
          scheduleId: 'week',
          expectedPeriod: 12,
        ),
        throwsStateError,
      );
      final updated = await ScheduleService.removeLastPeriod(
        scheduleId: 'week',
        expectedPeriod: 11,
      );
      await settle();
      expect(updated.name, '最新の名前');
      expect(updated.timetable['monday']![1]!.id, 'latest');
      expect((await ScheduleService.getScheduleById('week'))!.periodCount, 10);
    },
  );
  test('term changes preserve timetable name, rows, and lessons', () async {
    final schedule = await ScheduleService.createNamedSchedule(
      userId: 'owner',
      name: 'お気に入り時間割',
      semester: '2026年度前期',
    );
    await ScheduleService.setSemester(schedule.id, '2027年度後期');
    await settle();
    final restored = (await ScheduleService.getScheduleById(schedule.id))!;
    expect(restored.name, 'お気に入り時間割');
    expect(restored.semester, '2027年度後期');
    expect(restored.periodCount, 10);
  });
}
