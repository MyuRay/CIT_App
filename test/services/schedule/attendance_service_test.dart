import 'package:cit_app/models/schedule/attendance_session.dart';
import 'package:cit_app/services/schedule/attendance_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

class FailingAttendanceFirestore extends FakeFirebaseFirestore {
  bool failCommit = false;
  @override
  WriteBatch batch() =>
      failCommit ? _FailingBatch(super.batch()) : super.batch();
}

class _FailingBatch implements WriteBatch {
  _FailingBatch(this.delegate);
  final WriteBatch delegate;
  @override
  void delete(DocumentReference document) => delegate.delete(document);
  @override
  void set<T>(DocumentReference<T> document, T data, [SetOptions? options]) =>
      delegate.set(document, data, options);
  @override
  void update(DocumentReference document, Map<String, dynamic> data) =>
      delegate.update(document, data);
  @override
  Future<void> commit() async => throw StateError('offline');
}

void main() {
  late FailingAttendanceFirestore db;
  final start = DateTime(
    2026,
    9,
    17,
  ); // Thursday; Monday's first class is September 21.
  final firstDate = DateTime(2026, 9, 21);
  setUp(() => db = FailingAttendanceFirestore());

  Future<void> record(
    String id, {
    String user = 'owner',
    String schedule = 'schedule',
    String classId = 'lecture',
    int period = 2,
    DateTime? date,
    String status = 'present',
  }) => db.collection('attendance_records').doc(id).set({
    'userId': user,
    'scheduleId': schedule,
    'classId': classId,
    'subjectName': '情報演習',
    'weekdayKey': 'monday',
    'startPeriod': period,
    'duration': 2,
    'status': status,
    'attendanceDate': Timestamp.fromDate(date ?? firstDate),
  });
  Future<List<AttendanceSession>> load() =>
      AttendanceService.getClassAttendanceSessions(
        userId: 'owner',
        scheduleId: 'schedule',
        classId: 'lecture',
        weekdayKey: 'monday',
        startPeriod: 2,
        semesterStartDate: start,
        firestore: db,
      );
  Future<void> save(String? status, {String? existing}) =>
      AttendanceService.upsertAttendanceStatus(
        userId: 'owner',
        scheduleId: 'schedule',
        classId: 'lecture',
        subjectName: '情報演習',
        weekdayKey: 'monday',
        startPeriod: 2,
        duration: 2,
        attendanceDate: firstDate,
        status: status,
        existingRecordId: existing,
        firestore: db,
      );

  test(
    '15 weeks use the same weekday anchor and cross-year dates as management',
    () async {
      final sessions = await load();
      expect(sessions, hasLength(15));
      expect(sessions.first.date, firstDate);
      expect(sessions.last.date, DateTime(2026, 12, 28));
      expect(
        sessions.map((session) => session.week),
        List.generate(15, (i) => i + 1),
      );
      expect(sessions.every((session) => session.status == null), isTrue);
      final winter = AttendanceSession.fromRecords(
        semesterStartDate: DateTime(2026, 12, 31),
        weekdayKey: 'monday',
        startPeriod: 2,
        classId: 'lecture',
        records: [],
      );
      expect(winter.first.date, DateTime(2027, 1, 4));
    },
  );

  test(
    'query isolates owner, schedule, dates and period; exact class wins over legacy slot',
    () async {
      await record('legacy', classId: 'old-lecture', status: 'late');
      await record('exact', status: 'present');
      await record(
        'other-period',
        classId: 'other',
        period: 3,
        status: 'absent',
      );
      await record('other-user', user: 'other-user', status: 'absent');
      await record('other-schedule', schedule: 'other', status: 'absent');
      await record(
        'outside',
        date: firstDate.add(const Duration(days: 105)),
        status: 'absent',
      );
      final sessions = await load();
      expect(sessions.first.status, 'present');
      expect(sessions.first.recordId, 'exact');
      expect(
        sessions.skip(1).every((session) => session.status == null),
        isTrue,
      );
      await db.collection('attendance_records').doc('exact').delete();
      expect((await load()).first.recordId, 'legacy');
    },
  );

  test(
    'editing migrates a legacy record, updates status without duplicates, and clears it',
    () async {
      await record('legacy', classId: 'old-lecture');
      await record(
        'another-date',
        date: firstDate.add(const Duration(days: 7)),
      );
      await save('late', existing: 'legacy');
      expect(
        (await db.collection('attendance_records').doc('legacy').get()).exists,
        isFalse,
      );
      var sessions = await load();
      expect(sessions.first.status, 'late');
      final id = sessions.first.recordId;
      final data =
          (await db.collection('attendance_records').doc(id).get()).data()!;
      expect(data['startPeriod'], 2);
      expect(data['duration'], 2);
      for (final status in ['absent', 'cancelled', 'present']) {
        await save(status, existing: id);
        expect((await load()).first.status, status);
        expect((await db.collection('attendance_records').get()).size, 2);
      }
      await save(null, existing: id);
      sessions = await load();
      expect(sessions.first.status, isNull);
      expect(sessions[1].status, 'present');
      expect((await db.collection('attendance_records').get()).size, 1);
    },
  );

  test('an invalid status cannot modify existing attendance', () async {
    await record('legacy');
    await expectLater(save('unknown', existing: 'legacy'), throwsArgumentError);
    expect((await load()).first.status, 'present');
  });

  test(
    'a legacy record can be cleared before it has a canonical replacement',
    () async {
      await record('legacy', classId: 'old-lecture');
      await record(
        'another-date',
        date: firstDate.add(const Duration(days: 7)),
      );
      await save(null, existing: 'legacy');
      final records = await db.collection('attendance_records').get();
      expect(records.docs.single.id, 'another-date');
      expect((await load()).first.status, isNull);
    },
  );

  test(
    'failed replacement or clearing leaves the existing legacy record intact',
    () async {
      await record('legacy', classId: 'old-lecture');
      db.failCommit = true;
      for (final value in ['absent', null]) {
        await expectLater(save(value, existing: 'legacy'), throwsStateError);
        final records = await db.collection('attendance_records').get();
        expect(records.docs.single.id, 'legacy');
        expect(records.docs.single.data()['status'], 'present');
      }
    },
  );
}
