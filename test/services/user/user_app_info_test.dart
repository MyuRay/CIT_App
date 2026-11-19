import 'dart:async';
import 'package:cit_app/services/user/user_app_info_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MockFirebaseAuth auth;
  const info = {
    'os': 'android',
    'osVersion': '15',
    'platform': 'android',
    'appVersion': '2.3.3',
    'buildNumber': '42',
    'packageName': 'cit.app',
    'locale': 'ja-JP',
  };
  setUp(() {
    db = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'student', isEmailVerified: true),
    );
  });
  test(
    'app diagnostics are stored privately without changing the public profile',
    () async {
      await db.doc('users/student').set({'displayName': '学生'});
      final service = UserAppInfoService(
        firestore: db,
        auth: auth,
        loadInfo: () async => info,
      );
      await service.sync('student');
      final stored =
          (await db.doc('users/student/support_info/client').get()).data()!;
      expect(stored['appVersion'], '2.3.3');
      expect(stored['osVersion'], '15');
      expect(stored['updatedAt'], isNotNull);
      expect((await db.doc('users/student').get()).data(), {
        'displayName': '学生',
      });
    },
  );
  test('another UID, signed out and unverified sessions cannot sync', () async {
    var loads = 0;
    Future<Map<String, String>> load() async {
      loads++;
      return info;
    }

    final service = UserAppInfoService(
      firestore: db,
      auth: auth,
      loadInfo: load,
    );
    await service.sync('other');
    await auth.signOut();
    await service.sync('student');
    final unverified = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'student', isEmailVerified: false),
    );
    await UserAppInfoService(
      firestore: db,
      auth: unverified,
      loadInfo: load,
    ).sync('student');
    expect(loads, 0);
    expect(
      (await db.doc('users/student/support_info/client').get()).exists,
      false,
    );
  });
  test('logout while collecting info discards the pending write', () async {
    final pending = Completer<Map<String, String>>();
    final service = UserAppInfoService(
      firestore: db,
      auth: auth,
      loadInfo: () => pending.future,
    );
    final sync = service.sync('student');
    await auth.signOut();
    pending.complete(info);
    await sync;
    expect(
      (await db.doc('users/student/support_info/client').get()).exists,
      false,
    );
  });
  test(
    'sync saves once per app session and retries a failed collection',
    () async {
      var attempts = 0;
      final service = UserAppInfoService(
        firestore: db,
        auth: auth,
        loadInfo: () async {
          if (++attempts == 1) throw StateError('not ready');
          return info;
        },
      );
      await expectLater(service.sync('student'), throwsStateError);
      await service.sync('student');
      await service.sync('student');
      expect(attempts, 2);
      expect(
        (await db.doc('users/student/support_info/client').get()).exists,
        true,
      );
    },
  );
  test(
    'concurrent initial and resume sync share one diagnostics write',
    () async {
      var loads = 0;
      final pending = Completer<Map<String, String>>();
      final service = UserAppInfoService(
        firestore: db,
        auth: auth,
        loadInfo: () {
          loads++;
          return pending.future;
        },
      );
      final first = service.sync('student'), second = service.sync('student');
      expect(loads, 1);
      pending.complete(info);
      await Future.wait([first, second]);
      expect(
        (await db.doc('users/student/support_info/client').get()).exists,
        isTrue,
      );
    },
  );
}
