import 'package:cit_app/services/auth/session_logout.dart';
import 'package:cit_app/services/auth/session_work_guard.dart';
import 'package:cit_app/services/notification/device_token_store.dart';
import 'package:cit_app/services/notification/notification_target.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('logout invalidates delayed device writes even after a later login', () {
    final startedBeforeLogout = SessionWorkGuard.generation;
    SessionWorkGuard.suspend();
    expect(SessionWorkGuard.isCurrent(startedBeforeLogout), isFalse);
    SessionWorkGuard.resume();
    expect(SessionWorkGuard.isCurrent(startedBeforeLogout), isFalse);
    expect(SessionWorkGuard.isCurrent(SessionWorkGuard.generation), isTrue);
  });
  test(
    'account switch removes only this device and its matching legacy token',
    () async {
      final db = FakeFirebaseFirestore();
      final store = DeviceTokenStore(db);
      await db.doc('user_tokens/A').set({'fcmToken': 'this-token'});
      await store.register(
        userId: 'A',
        installationId: 'phone',
        token: 'this-token',
        platform: 'android',
      );
      await store.register(
        userId: 'A',
        installationId: 'tablet',
        token: 'tablet-token',
        platform: 'android',
      );
      expect(
        (await db.doc('user_tokens/A').get()).data()!.containsKey('fcmToken'),
        isFalse,
      );
      await store.unregister(
        userId: 'A',
        installationId: 'phone',
        token: 'this-token',
      );
      await store.register(
        userId: 'B',
        installationId: 'phone',
        token: 'new-token',
        platform: 'android',
      );
      expect(
        (await db.doc('user_tokens/A/devices/phone').get()).exists,
        isFalse,
      );
      expect(
        (await db.doc('user_tokens/A/devices/tablet').get())
            .data()!['fcmToken'],
        'tablet-token',
      );
      expect(
        (await db.doc('user_tokens/B/devices/phone').get()).data()!['fcmToken'],
        'new-token',
      );
    },
  );
  test(
    'token rotation replaces a device without removing another legacy device',
    () async {
      final db = FakeFirebaseFirestore();
      final store = DeviceTokenStore(db);
      await db.doc('user_tokens/A').set({'fcmToken': 'another-device'});
      await store.register(
        userId: 'A',
        installationId: 'phone',
        token: 'old',
        platform: 'android',
      );
      await store.register(
        userId: 'A',
        installationId: 'phone',
        token: 'new',
        platform: 'android',
      );
      await store.unregister(
        userId: 'A',
        installationId: 'phone',
        token: 'new',
      );
      expect(
        (await db.doc('user_tokens/A').get()).data()!['fcmToken'],
        'another-device',
      );
    },
  );
  test(
    'migration clears only the retired token owned by this installation',
    () async {
      final db = FakeFirebaseFirestore();
      final store = DeviceTokenStore(db);
      await db.doc('user_tokens/A').set({'fcmToken': 'retired-token'});
      await store.register(
        userId: 'A',
        installationId: 'phone',
        token: 'rotated-token',
        previousToken: 'retired-token',
        platform: 'android',
      );
      expect(
        (await db.doc('user_tokens/A').get()).data()!.containsKey('fcmToken'),
        isFalse,
      );
      expect(
        (await db.doc('user_tokens/A/devices/phone').get()).data()!['fcmToken'],
        'rotated-token',
      );
    },
  );
  test(
    'logout revokes the device before clearing local state and signing out',
    () async {
      final steps = <String>[];
      await SessionLogout(
        unregisterDevice: () async {
          steps.add('remote');
        },
        clearLocalData: () async {
          steps.add('local');
        },
        signOut: () async {
          steps.add('auth');
        },
      ).run();
      expect(steps, ['remote', 'local', 'auth']);
    },
  );
  test(
    'failed revocation cannot report a successful logout or switch accounts',
    () async {
      final steps = <String>[];
      final logout = SessionLogout(
        unregisterDevice: () async {
          throw StateError('offline');
        },
        clearLocalData: () async {
          steps.add('local');
        },
        signOut: () async {
          steps.add('auth');
        },
      );
      await expectLater(logout.run(), throwsStateError);
      expect(steps, isEmpty);
    },
  );
  test(
    'cold start tap survives waiting for login and is consumed once',
    () async {
      final queue = NotificationTapQueue();
      addTearDown(queue.dispose);
      final target = NotificationTarget.fromData({
        'postId': 'post',
        'commentId': 'comment',
        'userId': 'A',
      });
      queue.add(target);
      await Future<void>.delayed(Duration.zero);
      expect(queue.consume('A')!.commentId, 'comment');
      expect(queue.consume('A'), isNull);
    },
  );
  test('old account taps are discarded and logout clears queued taps', () {
    final queue = NotificationTapQueue();
    addTearDown(queue.dispose);
    queue.add(NotificationTarget.fromData({'userId': 'A', 'postId': 'post'}));
    expect(queue.consume('B'), isNull);
    queue.add(NotificationTarget.fromData({'postId': 'post'}));
    queue.clear();
    expect(queue.consume('B'), isNull);
  });
  test(
    'foreground payload preserves routing but omits notification content',
    () {
      final target = NotificationTarget.fromData({
        'postId': 'post',
        'commentId': 'comment',
        'type': 'reply',
        'source': 'bulletin',
        'title': 'private title',
        'message': 'private message',
      });
      final restored = NotificationTarget.tryParse(target.encode())!;
      expect(restored.postId, 'post');
      expect(restored.commentId, 'comment');
      expect(target.encode(), isNot(contains('private')));
      expect(NotificationTarget.tryParse('{broken'), isNull);
      expect(
        NotificationTarget.tryParse('{"type":"class_attendance"}'),
        isNull,
      );
      expect(
        NotificationTarget.fromData({'postId': '../other'}).postId,
        isNull,
      );
    },
  );
}
