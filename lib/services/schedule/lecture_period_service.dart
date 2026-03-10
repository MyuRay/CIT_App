import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/schedule/lecture_period_model.dart';

class LecturePeriodService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _docPath = 'app_settings/lecture_period';

  static Stream<LecturePeriodSettings?> watchLecturePeriod() {
    return _firestore.doc(_docPath).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return LecturePeriodSettings.fromMap(data);
    });
  }

  static Future<void> updateLecturePeriod({
    DateTime? springStartDate,
    DateTime? springEndDate,
    DateTime? fallStartDate,
    DateTime? fallEndDate,
    String? updatedBy,
  }) async {
    await _firestore.doc(_docPath).set({
      'springStartDate':
          springStartDate != null ? Timestamp.fromDate(springStartDate) : null,
      'springEndDate':
          springEndDate != null ? Timestamp.fromDate(springEndDate) : null,
      'fallStartDate':
          fallStartDate != null ? Timestamp.fromDate(fallStartDate) : null,
      'fallEndDate': fallEndDate != null ? Timestamp.fromDate(fallEndDate) : null,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    }, SetOptions(merge: true));
  }
}
