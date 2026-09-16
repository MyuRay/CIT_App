import 'package:cit_app/models/schedule/schedule_model.dart';
import 'package:cit_app/models/schedule/academic_year_model.dart';
import 'package:cit_app/services/schedule/schedule_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

ScheduleClass lesson(
  String id, {
  int duration = 1,
  String name = '数学',
  bool start = true,
}) => ScheduleClass(
  id: id,
  subjectName: name,
  classroom: '101',
  instructor: '教員',
  color: '#ffffff',
  duration: duration,
  isStartCell: start,
);

class FailingFirestore extends FakeFirebaseFirestore {
  bool failTransaction = false;
  bool failRead = false;
  int transactionCount = 0;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    if (failRead)
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    return super.collection(path);
  }

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) {
    transactionCount++;
    if (failTransaction)
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
    return super.runTransaction(
      transactionHandler,
      timeout: timeout,
      maxAttempts: maxAttempts,
    );
  }
}

void main() {
  late FailingFirestore db;
  setUp(() async {
    db = FailingFirestore();
    ScheduleService.firestoreOverride = db;
    final schedule = DefaultTimeSlots.createDefault(
      id: 'schedule',
      userId: 'owner',
      semester: AcademicYear.current().displayName,
    );
    await db.collection('schedules').doc('schedule').set(schedule.toJson());
  });
  tearDown(() => ScheduleService.firestoreOverride = null);
  Future<void> save(
    ScheduleClass value, {
    int period = 1,
    ScheduleClass? expected,
  }) => ScheduleService.saveClass(
    scheduleId: 'schedule',
    weekdayKey: 'monday',
    period: period,
    scheduleClass: value,
    expectedClass: expected,
  );
  Future<Schedule> read() async =>
      (await ScheduleService.getScheduleById('schedule'))!;

  test('continuous lesson is placed in one transaction', () async {
    await save(lesson('math', duration: 3));
    final day = (await read()).timetable['monday']!;
    expect(db.transactionCount, 1);
    expect([day[1]?.id, day[2]?.id, day[3]?.id], ['math', 'math', 'math']);
    expect(day[1]!.isStartCell, isTrue);
    expect(day[2]!.isStartCell, isFalse);
  });
  test(
    'conflict during edit preserves the original and the neighbor',
    () async {
      final original = lesson('math');
      await save(original);
      await save(lesson('other'), period: 2);
      await expectLater(
        save(lesson('math', duration: 2), expected: original),
        throwsStateError,
      );
      final day = (await read()).timetable['monday']!;
      expect(day[1]!.duration, 1);
      expect(day[2]!.id, 'other');
    },
  );
  test('out-of-range edit keeps the tenth period', () async {
    final original = lesson('math');
    await save(original, period: 10);
    await expectLater(
      save(lesson('math', duration: 2), period: 10, expected: original),
      throwsStateError,
    );
    expect((await read()).timetable['monday']![10]!.duration, 1);
  });
  test(
    'growing then shrinking clears only the old continuation cells',
    () async {
      final original = lesson('math');
      await save(original);
      await save(lesson('math', duration: 3), expected: original);
      await save(lesson('other'), period: 4);
      await save(lesson('math'), expected: lesson('math', duration: 3));
      final day = (await read()).timetable['monday']!;
      expect(day[2], isNull);
      expect(day[3], isNull);
      expect(day[4]!.id, 'other');
    },
  );
  test('failed transaction cannot delete an existing lesson', () async {
    final original = lesson('math');
    await save(original);
    db.failTransaction = true;
    await expectLater(
      save(lesson('math', duration: 2), expected: original),
      throwsA(isA<FirebaseException>()),
    );
    expect((await read()).timetable['monday']![1]!.duration, 1);
    expect((await read()).timetable['monday']![2], isNull);
  });
  test('stale edit and stale delete cannot overwrite another editor', () async {
    final original = lesson('math');
    await save(original);
    await save(lesson('math', name: '変更済み'), expected: original);
    await expectLater(
      save(lesson('math', duration: 2), expected: original),
      throwsStateError,
    );
    await expectLater(
      ScheduleService.removeClass(
        scheduleId: 'schedule',
        weekdayKey: 'monday',
        period: 1,
        expectedClass: original,
      ),
      throwsStateError,
    );
    expect((await read()).timetable['monday']![1]!.subjectName, '変更済み');
  });
  test(
    'deleting a continuation removes the complete lesson in one transaction',
    () async {
      await save(lesson('math', duration: 2));
      final oldCount = db.transactionCount;
      await ScheduleService.removeClass(
        scheduleId: 'schedule',
        weekdayKey: 'monday',
        period: 2,
      );
      expect(db.transactionCount, oldCount + 1);
      expect((await read()).timetable['monday']![1], isNull);
      expect((await read()).timetable['monday']![2], isNull);
    },
  );
  test('missing schedules and failed reads are distinct', () async {
    expect(await ScheduleService.getScheduleById('absent'), isNull);
    expect(await ScheduleService.getAllSchedulesByUserId('absent'), isEmpty);
    db.failRead = true;
    await expectLater(
      ScheduleService.getScheduleById('schedule'),
      throwsA(isA<FirebaseException>()),
    );
    await expectLater(
      ScheduleService.getAllSchedulesByUserId('owner'),
      throwsA(isA<FirebaseException>()),
    );
    await expectLater(
      ScheduleService.getScheduleByUserId('owner'),
      throwsA(isA<FirebaseException>()),
    );
  });
}
