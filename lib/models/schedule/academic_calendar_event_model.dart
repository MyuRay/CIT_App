import 'package:cloud_firestore/cloud_firestore.dart';

class AcademicCalendarEvent {
  const AcademicCalendarEvent({
    required this.id,
    required this.date,
    required this.title,
    this.note = '',
    this.colorHex = '#E53935',
    this.updatedAt,
    this.updatedBy,
  });

  final String id;
  final DateTime date;
  final String title;
  final String note;
  final String colorHex;
  final DateTime? updatedAt;
  final String? updatedBy;

  factory AcademicCalendarEvent.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final date = _toDateTime(data['date']) ?? DateTime.now();
    return AcademicCalendarEvent(
      id: doc.id,
      date: DateTime(date.year, date.month, date.day),
      title: (data['title'] as String? ?? '').trim(),
      note: (data['note'] as String? ?? '').trim(),
      colorHex: (data['colorHex'] as String? ?? '#E53935').trim(),
      updatedAt: _toDateTime(data['updatedAt']),
      updatedBy: data['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'title': title.trim(),
      'note': note.trim(),
      'colorHex': colorHex.trim().isEmpty ? '#E53935' : colorHex.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (updatedBy != null) 'updatedBy': updatedBy,
    };
  }

  AcademicCalendarEvent copyWith({
    String? id,
    DateTime? date,
    String? title,
    String? note,
    String? colorHex,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return AcademicCalendarEvent(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      note: note ?? this.note,
      colorHex: colorHex ?? this.colorHex,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
