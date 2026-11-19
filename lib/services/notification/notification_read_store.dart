import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/notification/notification_model.dart';

class NotificationReadStore {
  NotificationReadStore(this.firestore);

  final FirebaseFirestore firestore;

  Future<void> markAsRead(String id) =>
      firestore.collection('notifications').doc(id).update({'isRead': true});

  Future<void> markAllAsRead(String userId) async {
    // Older notifications may have only `read`, or neither read flag.
    final snapshot =
        await firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .get();
    final unread =
        snapshot.docs
            .where((doc) => !AppNotification.readFlag(doc.data()))
            .toList();
    for (var start = 0; start < unread.length; start += 400) {
      final batch = firestore.batch();
      for (final doc in unread.skip(start).take(400)) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    }
  }
}
