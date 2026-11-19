import 'package:cit_app/models/notification/notification_model.dart';
import 'package:cit_app/services/notification/notification_read_store.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'mark all includes legacy/missing flags, >500 rows, and only this user',
    () async {
      final db = FakeFirebaseFirestore();
      var batch = db.batch();
      for (var i = 0; i < 510; i++) {
        batch.set(db.doc('notifications/n$i'), {
          'userId': 'self',
          if (i % 3 == 0) 'isRead': false,
          if (i % 3 == 1) 'read': false,
        });
        if ((i + 1) % 400 == 0) {
          await batch.commit();
          batch = db.batch();
        }
      }
      await batch.commit();
      await db.doc('notifications/other').set({
        'userId': 'other',
        'isRead': false,
      });
      await db.doc('notifications/already').set({
        'userId': 'self',
        'read': true,
      });
      await NotificationReadStore(db).markAllAsRead('self');
      final rows =
          await db
              .collection('notifications')
              .where('userId', isEqualTo: 'self')
              .get();
      expect(
        rows.docs.every((doc) => AppNotification.readFlag(doc.data())),
        isTrue,
      );
      expect(
        (await db.doc('notifications/other').get()).data()!['isRead'],
        isFalse,
      );
    },
  );

  test(
    'single read overrides a legacy unread flag without changing content',
    () async {
      final db = FakeFirebaseFirestore();
      await db.doc('notifications/one').set({
        'userId': 'self',
        'read': false,
        'message': 'keep',
      });
      await NotificationReadStore(db).markAsRead('one');
      final row = (await db.doc('notifications/one').get()).data()!;
      expect(AppNotification.readFlag(row), isTrue);
      expect(row['message'], 'keep');
    },
  );
}
