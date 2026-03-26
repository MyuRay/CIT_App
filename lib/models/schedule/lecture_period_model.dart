import 'package:cloud_firestore/cloud_firestore.dart';

class LecturePeriodSettings {
  const LecturePeriodSettings({
    this.springStartDate,
    this.springEndDate,
    this.fallStartDate,
    this.fallEndDate,
    this.updatedAt,
    this.updatedBy,
  });

  final DateTime? springStartDate;
  final DateTime? springEndDate;
  final DateTime? fallStartDate;
  final DateTime? fallEndDate;
  final DateTime? updatedAt;
  final String? updatedBy;

  // 旧形式（lectureStartDate / lectureEndDate）互換
  DateTime? get lectureStartDate => springStartDate;
  DateTime? get lectureEndDate => springEndDate;

  /// 指定日が前期または後期のいずれかの範囲内（日付のみ比較）なら true。
  /// 前期・後期の両方が未設定の場合は false。
  bool containsDate(DateTime date) {
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
    return LecturePeriodSettings(
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
      if (springStartDate != null)
        'springStartDate': Timestamp.fromDate(springStartDate!),
      if (springEndDate != null) 'springEndDate': Timestamp.fromDate(springEndDate!),
      if (fallStartDate != null) 'fallStartDate': Timestamp.fromDate(fallStartDate!),
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
