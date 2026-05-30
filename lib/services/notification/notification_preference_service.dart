import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/notification/notification_preference_model.dart';

class NotificationPreferenceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'user_settings';

  static DocumentReference<Map<String, dynamic>> _doc(String userId) =>
      _firestore.collection(_collection).doc(userId);

  static Stream<NotificationPreferences> watchPreferences(String userId) {
    return _doc(userId).snapshots().map((snap) {
      if (!snap.exists) return NotificationPreferences.defaults();
      final data = snap.data();
      return NotificationPreferences.fromMap(
        data?['notificationPreferences'] as Map<String, dynamic>?,
      );
    });
  }

  static Future<NotificationPreferences> getPreferences(String userId) async {
    final snap = await _doc(userId).get();
    if (!snap.exists) return NotificationPreferences.defaults();
    return NotificationPreferences.fromMap(
      snap.data()?['notificationPreferences'] as Map<String, dynamic>?,
    );
  }

  static Future<bool> isEnabled(
    String userId,
    NotificationPreferenceKey key,
  ) async {
    final prefs = await getPreferences(userId);
    return prefs.isEnabled(key);
  }

  static Future<void> setEnabled({
    required String userId,
    required NotificationPreferenceKey key,
    required bool enabled,
  }) async {
    final current = await getPreferences(userId);
    final updated = current.copyWithKey(key, enabled);
    await _doc(userId).set(
      {
        'notificationPreferences': updated.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
