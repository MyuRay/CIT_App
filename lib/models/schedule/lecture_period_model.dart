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

  factory LecturePeriodSettings.fromMap(Map<String, dynamic> data) {
    return LecturePeriodSettings(
      springStartDate: _toDateTime(data['springStartDate']),
      springEndDate: _toDateTime(data['springEndDate']),
      fallStartDate: _toDateTime(data['fallStartDate']),
      fallEndDate: _toDateTime(data['fallEndDate']),
      updatedAt: _toDateTime(data['updatedAt']),
      updatedBy: data['updatedBy'] as String?,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
