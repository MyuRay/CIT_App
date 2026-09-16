/// One lecture date in the attendance management table (including unrecorded dates).
class AttendanceSession {
  const AttendanceSession({
    required this.week,
    required this.date,
    this.status,
    this.recordId,
  });

  final int week;
  final DateTime date;
  final String? status;
  final String? recordId;

  /// The save uses the canonical document ID. Do not reuse a deleted legacy ID.
  AttendanceSession withSavedStatus(String? value) =>
      AttendanceSession(week: week, date: date, status: value);

  static const weekCount = 15;

  /// Use the same first-week anchor and legacy slot fallback as attendance management.
  static List<AttendanceSession> fromRecords({
    required DateTime semesterStartDate,
    required String weekdayKey,
    required int startPeriod,
    required String classId,
    required List<Map<String, dynamic>> records,
  }) {
    const weekdays = {
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
    };
    final weekday = weekdays[weekdayKey];
    if (weekday == null) throw ArgumentError.value(weekdayKey, 'weekdayKey');
    final start = DateTime(
      semesterStartDate.year,
      semesterStartDate.month,
      semesterStartDate.day,
    );
    final offset = (weekday - start.weekday + 7) % 7;
    return List.generate(weekCount, (index) {
      final date = DateTime(
        start.year,
        start.month,
        start.day + offset + index * 7,
      );
      Map<String, dynamic>? exact;
      Map<String, dynamic>? slot;
      for (final record in records) {
        final recordedDate = record['attendanceDate'];
        if (recordedDate is! DateTime ||
            recordedDate.year != date.year ||
            recordedDate.month != date.month ||
            recordedDate.day != date.day) {
          continue;
        }
        if (record['classId'] == classId) exact = record;
        if (record['weekdayKey'] == weekdayKey &&
            record['startPeriod'] == startPeriod) {
          slot = record;
        }
      }
      final record = exact ?? slot;
      final status = record?['status'] as String?;
      return AttendanceSession(
        week: index + 1,
        date: date,
        status: status == null || status.isEmpty ? null : status,
        recordId: record?['id'] as String?,
      );
    });
  }
}
