import 'package:cloud_firestore/cloud_firestore.dart';
import 'academic_term.dart';

class LecturePeriodSettings {
  const LecturePeriodSettings({
    this.springStartDate,
    this.springEndDate,
    this.fallStartDate,
    this.fallEndDate,
    this.periods = const {},
    this.updatedAt,
    this.updatedBy,
  });

  final Map<String, LecturePeriod> periods;

  /// 年度別設定がなければ従来の期間を使う。明示的に無効化した期間には戻さない。
  LecturePeriod? periodForSemester(String semester) {
    final term = AcademicTerm.parse(semester);
    if (term != null && periods.containsKey(term.key)) return periods[term.key];
    if (term == null && !RegExp('前期|後期|春|秋').hasMatch(semester)) return null;
    final fall = isFallSemester(semester);
    final start = fall ? fallStartDate : springStartDate;
    final end = fall ? fallEndDate : springEndDate;
    if (start == null || (term != null && start.year != term.year)) return null;
    return LecturePeriod(
      year: term?.year ?? start.year,
      isFall: fall,
      startDate: start,
      endDate: end,
    );
  }

  final DateTime? springStartDate;
  final DateTime? springEndDate;
  final DateTime? fallStartDate;
  final DateTime? fallEndDate;
  final DateTime? updatedAt;
  final String? updatedBy;

  // 旧形式（lectureStartDate / lectureEndDate）互換
  DateTime? get lectureStartDate => springStartDate;
  DateTime? get lectureEndDate => springEndDate;

  static bool isFallSemester(String semester) =>
      semester.contains('後期') || semester.contains('秋');

  /// Never substitute today's date or the other term for a missing start date.
  DateTime? startDateForSemester(String semester) {
    final period = periodForSemester(semester);
    final start = period?.startDate;
    if (period == null || !period.isActive || start == null) return null;
    return DateTime(start.year, start.month, start.day);
  }

  DateTime? endDateForSemester(String semester) {
    final start = startDateForSemester(semester);
    final end = periodForSemester(semester)?.endDate;
    if (start == null || end == null) return null;
    final day = DateTime(end.year, end.month, end.day);
    return day.isBefore(start) ? null : day;
  }

  bool containsDateForSemester(DateTime date, String semester) {
    final start = startDateForSemester(semester);
    final end = endDateForSemester(semester);
    final day = DateTime(date.year, date.month, date.day);
    return start != null &&
        end != null &&
        !day.isBefore(start) &&
        !day.isAfter(end);
  }

  /// 指定日が前期または後期のいずれかの範囲内（日付のみ比較）なら true。
  /// 前期・後期の両方が未設定の場合は false。
  bool containsDate(DateTime date) {
    if (periods.isNotEmpty) {
      final labels = <String>{for (final p in periods.values) p.term.label};
      if (springStartDate != null)
        labels.add(AcademicTerm(springStartDate!.year, false).label);
      if (fallStartDate != null)
        labels.add(AcademicTerm(fallStartDate!.year, true).label);
      return labels.any((label) => containsDateForSemester(date, label));
    }
    final d = DateTime(date.year, date.month, date.day);
    if (springStartDate != null && springEndDate != null) {
      final s = DateTime(
        springStartDate!.year,
        springStartDate!.month,
        springStartDate!.day,
      );
      final e = DateTime(
        springEndDate!.year,
        springEndDate!.month,
        springEndDate!.day,
      );
      if (!d.isBefore(s) && !d.isAfter(e)) return true;
    }
    if (fallStartDate != null && fallEndDate != null) {
      final s = DateTime(
        fallStartDate!.year,
        fallStartDate!.month,
        fallStartDate!.day,
      );
      final e = DateTime(
        fallEndDate!.year,
        fallEndDate!.month,
        fallEndDate!.day,
      );
      if (!d.isBefore(s) && !d.isAfter(e)) return true;
    }
    return false;
  }

  factory LecturePeriodSettings.fromMap(Map<String, dynamic> data) {
    final legacyStart = _toDateTime(data['lectureStartDate']);
    final legacyEnd = _toDateTime(data['lectureEndDate']);
    final periods = <String, LecturePeriod>{};
    final raw = data['periods'];
    if (raw is Map) {
      for (final entry in raw.entries) {
        if (entry.value is! Map) continue;
        final period = LecturePeriod.fromMap(
          Map<String, dynamic>.from(entry.value),
        );
        if (period != null) periods[period.term.key] = period;
      }
    }
    return LecturePeriodSettings(
      periods: periods,
      springStartDate: _toDateTime(data['springStartDate']) ?? legacyStart,
      springEndDate: _toDateTime(data['springEndDate']) ?? legacyEnd,
      fallStartDate: _toDateTime(data['fallStartDate']),
      fallEndDate: _toDateTime(data['fallEndDate']),
      updatedAt: _toDateTime(data['updatedAt']),
      updatedBy: data['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (periods.isNotEmpty)
        'periods': {for (final e in periods.entries) e.key: e.value.toMap()},
      if (springStartDate != null)
        'springStartDate': Timestamp.fromDate(springStartDate!),
      if (springEndDate != null)
        'springEndDate': Timestamp.fromDate(springEndDate!),
      if (fallStartDate != null)
        'fallStartDate': Timestamp.fromDate(fallStartDate!),
      if (fallEndDate != null) 'fallEndDate': Timestamp.fromDate(fallEndDate!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (updatedBy != null) 'updatedBy': updatedBy,
    };
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

class LecturePeriod {
  const LecturePeriod({
    required this.year,
    required this.isFall,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
  });
  final int year;
  final bool isFall;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  AcademicTerm get term => AcademicTerm(year, isFall);
  bool get isValid =>
      startDate != null &&
      endDate != null &&
      !endDate!.isBefore(startDate!) &&
      startDate!.year == year &&
      endDate!.isBefore(DateTime(year + 1, 4, 1)) &&
      !startDate!.isBefore(DateTime(year, 4, 1));
  Map<String, dynamic> toMap() => {
    'year': year,
    'isFall': isFall,
    'isActive': isActive,
    if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
    if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
  };
  static LecturePeriod? fromMap(Map<String, dynamic> data) {
    if (data['year'] is! int || data['isFall'] is! bool) return null;
    return LecturePeriod(
      year: data['year'] as int,
      isFall: data['isFall'] as bool,
      startDate: LecturePeriodSettings._toDateTime(data['startDate']),
      endDate: LecturePeriodSettings._toDateTime(data['endDate']),
      isActive: data['isActive'] != false,
    );
  }
}
