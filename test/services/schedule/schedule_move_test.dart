import 'package:cit_app/models/schedule/schedule_model.dart';
import 'package:cit_app/services/schedule/schedule_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

class _MoveFirestore extends FakeFirebaseFirestore {
  int transactions = 0;
  bool fail = false;
  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> handler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) {
    transactions++;
    if (fail) {
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
    }
    return super.runTransaction(
      handler,
      timeout: timeout,
      maxAttempts: maxAttempts,
    );
  }
}

const lecture = ScheduleClass(
  id: 'lecture',
  subjectName: '情報工学',
  classroom: '3号館',
  instructor: '担当教員',
  color: '#E53935',
  notes: '教科書を持参',
  duration: 2,
);

void main() {
  late _MoveFirestore db;
  Future<Schedule> read() async =>
      (await ScheduleService.getScheduleById('schedule'))!;
  Future<Schedule> move({String day = 'saturday', int period = 9}) =>
      ScheduleService.moveClass(
        scheduleId: 'schedule',
        fromWeekdayKey: 'monday',
        fromPeriod: 1,
        toWeekdayKey: day,
        toPeriod: period,
        expectedClass: lecture,
      );
  setUp(() async {
    db = _MoveFirestore();
    ScheduleService.firestoreOverride = db;
    final schedule = DefaultTimeSlots.createDefault(
      id: 'schedule',
      userId: 'owner',
      semester: '2026年度前期',
    );
    await db.collection('schedules').doc('schedule').set(schedule.toJson());
    await ScheduleService.saveClass(
      scheduleId: 'schedule',
      weekdayKey: 'monday',
      period: 1,
      scheduleClass: lecture,
    );
    db.transactions = 0;
  });
  tearDown(() => ScheduleService.firestoreOverride = null);

  test(
    'moves the full lesson atomically and retains identity and details',
    () async {
      final updated = await move();
      expect(db.transactions, 1);
      expect(updated.timetable['monday']![1], isNull);
      expect(updated.timetable['monday']![2], isNull);
      final saved = (await read()).timetable['saturday']!;
      expect(saved[9]!.toJson(), lecture.toJson());
      expect(saved[10]!.toJson(), {...lecture.toJson(), 'isStartCell': false});
    },
  );
  test(
    'overlapping shift within the same day keeps continuation cells correct',
    () async {
      await move(day: 'monday', period: 2);
      final day = (await read()).timetable['monday']!;
      expect(day[1], isNull);
      expect(day[2]!.isStartCell, isTrue);
      expect(day[3]!.isStartCell, isFalse);
      expect(day[4], isNull);
    },
  );
  test('destination collision preserves both lessons', () async {
    const other = ScheduleClass(
      id: 'other',
      subjectName: '数学',
      classroom: '1号館',
      instructor: '',
      color: '#2196F3',
    );
    await ScheduleService.saveClass(
      scheduleId: 'schedule',
      weekdayKey: 'saturday',
      period: 10,
      scheduleClass: other,
    );
    await expectLater(move(), throwsStateError);
    final result = await read();
    expect(result.timetable['monday']![1]!.id, lecture.id);
    expect(result.timetable['monday']![2]!.id, lecture.id);
    expect(result.timetable['saturday']![9], isNull);
    expect(result.timetable['saturday']![10]!.id, other.id);
  });
  test('out-of-range and unknown weekdays do not remove source', () async {
    await expectLater(move(period: 10), throwsStateError);
    await expectLater(move(day: 'sunday', period: 1), throwsStateError);
    expect((await read()).timetable['monday']![1]!.id, lecture.id);
  });
  test('stale source and altered continuation are rejected', () async {
    await db.collection('schedules').doc('schedule').update({
      'timetable.monday.1.notes': '別端末の変更',
    });
    await expectLater(move(), throwsStateError);
    await db.collection('schedules').doc('schedule').update({
      'timetable.monday.1.notes': lecture.notes,
      'timetable.monday.2.id': 'replacement',
    });
    await expectLater(move(), throwsStateError);
    expect((await read()).timetable['saturday']![9], isNull);
  });
  test('transaction failure leaves the entire source intact', () async {
    db.fail = true;
    await expectLater(move(), throwsA(isA<FirebaseException>()));
    expect((await read()).timetable['monday']![1]!.toJson(), lecture.toJson());
    expect((await read()).timetable['saturday']![9], isNull);
  });
}
