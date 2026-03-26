import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/schedule/schedule_model.dart';
import 'lecture_period_service.dart';

class AttendanceMarkResult {
  const AttendanceMarkResult({
    required this.success,
    required this.message,
    this.status,
  });

  final bool success;
  final String message;
  final String? status; // present / late
}

class AttendanceClassSummary {
  const AttendanceClassSummary({
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
  });

  final int presentCount;
  final int lateCount;
  final int absentCount;
}

class AttendanceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'attendance_records';

  static Future<AttendanceMarkResult> markAttendanceFromTap({
    required String userId,
    required String scheduleId,
    required Schedule schedule,
    required String weekdayKey,
    required int startPeriod,
    required ScheduleClass scheduleClass,
    DateTime? now,
  }) async {
    final current = now ?? DateTime.now();
    final todayWeekdayKey = _weekdayKeyFromDate(current);
    if (todayWeekdayKey == null) {
      return const AttendanceMarkResult(
        success: false,
        message: '日曜日は出欠を記録できません',
      );
    }
    if (todayWeekdayKey != weekdayKey) {
      return const AttendanceMarkResult(
        success: false,
        message: '当日の講義のみ出欠を記録できます',
      );
    }

    final lecturePeriod = await LecturePeriodService.getLecturePeriod();
    if (lecturePeriod == null || !lecturePeriod.containsDate(current)) {
      return const AttendanceMarkResult(
        success: false,
        message: '講義期間外のため出欠を記録できません',
      );
    }

    final startSlot = schedule.timeSlots.firstWhere(
      (slot) => slot.period == startPeriod,
      orElse:
          () => TimeSlot(
            period: startPeriod,
            startTime: '${startPeriod + 8}:00',
            endTime: '${startPeriod + 9}:00',
          ),
    );
    final startParts = startSlot.startTime.split(':');
    final lectureStart = DateTime(
      current.year,
      current.month,
      current.day,
      int.tryParse(startParts[0]) ?? 9,
      int.tryParse(startParts[1]) ?? 0,
    );
    final availableFrom = lectureStart.subtract(const Duration(minutes: 20));
    final lateDeadline = lectureStart.add(const Duration(hours: 1));

    // 許可時間外は拒否
    if (current.isBefore(availableFrom)) {
      return const AttendanceMarkResult(
        success: false,
        message: '講義開始20分前から記録できます',
      );
    }
    if (current.isAfter(lateDeadline)) {
      return const AttendanceMarkResult(
        success: false,
        message: '講義開始1時間後まで記録できます',
      );
    }

    final status = current.isAfter(lectureStart) ? 'late' : 'present';
    final statusLabel = status == 'present' ? '出席' : '遅刻';

    final docId = _recordDocId(
      userId: userId,
      scheduleId: scheduleId,
      classId: scheduleClass.id,
      date: current,
    );

    await _firestore.collection(_collection).doc(docId).set({
      'userId': userId,
      'scheduleId': scheduleId,
      'semester': schedule.semester,
      'classId': scheduleClass.id,
      'subjectName': scheduleClass.subjectName,
      'weekdayKey': weekdayKey,
      'startPeriod': startPeriod,
      'duration': scheduleClass.duration,
      'status': status,
      'recordedAt': Timestamp.now(),
      'attendanceDate': Timestamp.fromDate(
        DateTime(current.year, current.month, current.day),
      ),
    }, SetOptions(merge: true));

    return AttendanceMarkResult(
      success: true,
      message: '$statusLabelとして記録しました',
      status: status,
    );
  }

  static Future<void> upsertAttendanceStatus({
    required String userId,
    required String scheduleId,
    required String classId,
    required String subjectName,
    required String weekdayKey,
    required int startPeriod,
    required int duration,
    required DateTime attendanceDate,
    required String? status, // present / late / absent / null(未記録)
    String? existingRecordId,
  }) async {
    final docId = _recordDocId(
      userId: userId,
      scheduleId: scheduleId,
      classId: classId,
      date: attendanceDate,
    );
    final docRef = _firestore.collection(_collection).doc(docId);
    final existingRef =
        (existingRecordId != null && existingRecordId.isNotEmpty)
            ? _firestore.collection(_collection).doc(existingRecordId)
            : null;

    if (status == null || status.isEmpty) {
      final batch = _firestore.batch();
      if (existingRef != null && existingRecordId != docId) {
        batch.delete(existingRef);
      }
      batch.delete(docRef);
      await batch.commit();
      return;
    }

    if (existingRef != null && existingRecordId != docId) {
      await existingRef.delete();
    }

    await docRef.set({
      'userId': userId,
      'scheduleId': scheduleId,
      'classId': classId,
      'subjectName': subjectName,
      'weekdayKey': weekdayKey,
      'startPeriod': startPeriod,
      'duration': duration,
      'status': status,
      'recordedAt': Timestamp.now(),
      'attendanceDate': Timestamp.fromDate(
        DateTime(attendanceDate.year, attendanceDate.month, attendanceDate.day),
      ),
    }, SetOptions(merge: true));
  }

  static Stream<List<Map<String, dynamic>>> watchScheduleAttendanceRecords({
    required String userId,
    required String scheduleId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('scheduleId', isEqualTo: scheduleId)
        .where('attendanceDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('attendanceDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final attendanceDateRaw = data['attendanceDate'];
            final recordedAtRaw = data['recordedAt'];
            return {
              'id': doc.id,
              ...data,
              'attendanceDate':
                  attendanceDateRaw is Timestamp
                      ? attendanceDateRaw.toDate().toLocal()
                      : null,
              'recordedAt':
                  recordedAtRaw is Timestamp
                      ? recordedAtRaw.toDate().toLocal()
                      : null,
            };
          }).toList();
        });
  }

  static Future<AttendanceClassSummary> getClassAttendanceSummary({
    required String userId,
    required String scheduleId,
    required String classId,
  }) async {
    final snapshot =
        await _firestore
            .collection(_collection)
            .where('userId', isEqualTo: userId)
            .where('scheduleId', isEqualTo: scheduleId)
            .where('classId', isEqualTo: classId)
            .get();

    return _summarizeStatuses(snapshot.docs.map((doc) => doc.data()));
  }

  static Future<AttendanceClassSummary> getClassAttendanceSummaryForRange({
    required String userId,
    required String scheduleId,
    required String classId,
    required String weekdayKey,
    required int startPeriod,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    final snapshot =
        await _firestore
            .collection(_collection)
            .where('userId', isEqualTo: userId)
            .where('scheduleId', isEqualTo: scheduleId)
            .where('attendanceDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('attendanceDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
            .get();

    final filtered = snapshot.docs
        .map((doc) => doc.data())
        .where((data) {
          final recordClassId = data['classId'] as String? ?? '';
          if (recordClassId == classId) return true;
          final recordWeekday = data['weekdayKey'] as String? ?? '';
          final recordStartPeriod = data['startPeriod'] as int?;
          return recordWeekday == weekdayKey && recordStartPeriod == startPeriod;
        })
        .toList();
    return _summarizeStatuses(filtered);
  }

  static AttendanceClassSummary _summarizeStatuses(
    Iterable<Map<String, dynamic>> records,
  ) {
    int present = 0;
    int late = 0;
    int absent = 0;
    for (final data in records) {
      final status = data['status'] as String? ?? '';
      if (status == 'present') {
        present++;
      } else if (status == 'late') {
        late++;
      } else if (status.isNotEmpty && status != 'cancelled') {
        // 出欠管理画面と同じ基準: present/late/cancelled以外は欠席扱い
        absent++;
      }
    }
    return AttendanceClassSummary(
      presentCount: present,
      lateCount: late,
      absentCount: absent,
    );
  }

  static String? _weekdayKeyFromDate(DateTime date) {
    switch (date.weekday) {
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
        return null;
    }
  }

  static String _recordDocId({
    required String userId,
    required String scheduleId,
    required String classId,
    required DateTime date,
  }) {
    final dateKey =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    return '${userId}_${scheduleId}_${classId}_$dateKey';
  }
}
