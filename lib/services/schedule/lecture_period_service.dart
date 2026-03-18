import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/schedule/lecture_period_model.dart';

class LecturePeriodService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'app_settings';
  static const String _docId = 'lecture_period';

  static Stream<LecturePeriodSettings?> watchLecturePeriod() {
    return _firestore.collection(_collection).doc(_docId).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return LecturePeriodSettings.fromMap(data);
    });
  }

  static Future<LecturePeriodSettings?> getLecturePeriod() async {
    final doc = await _firestore.collection(_collection).doc(_docId).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return LecturePeriodSettings.fromMap(data);
  }

  static Future<void> updateLecturePeriod({
    DateTime? springStartDate,
    DateTime? springEndDate,
    DateTime? fallStartDate,
    DateTime? fallEndDate,
    // 旧API互換
    DateTime? lectureStartDate,
    DateTime? lectureEndDate,
    String? updatedBy,
  }) async {
    final resolvedSpringStart = springStartDate ?? lectureStartDate;
    final resolvedSpringEnd = springEndDate ?? lectureEndDate;

    await _firestore.collection(_collection).doc(_docId).set({
      if (resolvedSpringStart != null)
        'springStartDate': Timestamp.fromDate(_dateOnly(resolvedSpringStart)),
      if (resolvedSpringEnd != null)
        'springEndDate': Timestamp.fromDate(_dateOnly(resolvedSpringEnd)),
      if (fallStartDate != null)
        'fallStartDate': Timestamp.fromDate(_dateOnly(fallStartDate)),
      if (fallEndDate != null)
        'fallEndDate': Timestamp.fromDate(_dateOnly(fallEndDate)),
      // 旧フィールドも維持（既存UI互換）
      if (resolvedSpringStart != null)
        'lectureStartDate': Timestamp.fromDate(_dateOnly(resolvedSpringStart)),
      if (resolvedSpringEnd != null)
        'lectureEndDate': Timestamp.fromDate(_dateOnly(resolvedSpringEnd)),
      'updatedAt': FieldValue.serverTimestamp(),
      if (updatedBy != null) 'updatedBy': updatedBy,
    }, SetOptions(merge: true));
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
