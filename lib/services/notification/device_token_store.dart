import 'package:cloud_firestore/cloud_firestore.dart';

/// Each installation owns one entry; removing it never removes another device.
class DeviceTokenStore {
  const DeviceTokenStore(this.firestore);
  final FirebaseFirestore firestore;

  Future<void> register({
    required String userId,
    required String installationId,
    required String token,
    required String platform,
    String? previousToken,
  }) async {
    final owner = firestore.collection('user_tokens').doc(userId);
    final device = owner.collection('devices').doc(installationId);
    await firestore.runTransaction((transaction) async {
      final legacy = await transaction.get(owner);
      final previous = await transaction.get(device);
      final legacyToken = legacy.data()?['fcmToken'];
      final ownerUpdate = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
        if (legacyToken != null &&
            (legacyToken == token ||
                legacyToken == previousToken ||
                legacyToken == previous.data()?['fcmToken']))
          'fcmToken': FieldValue.delete(),
      };
      if (legacy.exists) {
        transaction.update(owner, ownerUpdate);
      } else {
        transaction.set(owner, ownerUpdate);
      }
      transaction.set(device, {
        'fcmToken': token,
        'platform': platform,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> unregister({
    required String userId,
    required String installationId,
    String? token,
  }) async {
    final owner = firestore.collection('user_tokens').doc(userId);
    final device = owner.collection('devices').doc(installationId);
    await firestore.runTransaction((transaction) async {
      final legacy = await transaction.get(owner);
      final current = await transaction.get(device);
      final legacyToken = legacy.data()?['fcmToken'];
      if (current.exists) transaction.delete(device);
      if (legacyToken != null &&
          (legacyToken == token ||
              legacyToken == current.data()?['fcmToken'])) {
        transaction.update(owner, {'fcmToken': FieldValue.delete()});
      }
    });
  }
}
