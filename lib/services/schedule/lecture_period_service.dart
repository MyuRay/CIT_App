import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/schedule/lecture_period_model.dart';

class LecturePeriodService {
  @visibleForTesting
  static FirebaseFirestore? firestoreOverride;
  static FirebaseFirestore get _firestore =>
      firestoreOverride ?? FirebaseFirestore.instance;
  static const String _collection = 'app_settings';
  static const String _docId = 'lecture_period';

  static Stream<LecturePeriodSettings?> watchLecturePeriod() {
    return _firestore.collection(_collection).doc(_docId).snapshots().map((
      doc,
    ) {
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

  static Future<void> savePeriod(
    LecturePeriod period, {
    String? updatedBy,
    bool createOnly = false,
  }) async {
    if (!period.isValid)
      throw ArgumentError('開始日・終了日を選択した年度内（4月〜翌3月）で設定してください');
    final doc = _firestore.collection(_collection).doc(_docId);
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(doc);
      final data = snapshot.data() ?? <String, dynamic>{};
      if (createOnly &&
          LecturePeriodSettings.fromMap(
                data,
              ).periodForSemester(period.term.label) !=
              null)
        throw StateError('この年度・学期は登録済みです。一覧から編集してください');
      final periods = Map<String, dynamic>.from(data['periods'] as Map? ?? {});
      periods[period.term.key] = period.toMap();
      tx.set(doc, {
        ...data,
        'periods': periods,
        'updatedAt': FieldValue.serverTimestamp(),
        if (updatedBy != null) 'updatedBy': updatedBy,
      });
    });
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
