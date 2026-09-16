import 'package:cit_app/services/auth/verified_profile.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unverified Auth identities never create profiles', () async {
    final db = FakeFirebaseFirestore();
    expect(
      await ensureVerifiedProfile(
        db,
        MockUser(uid: 'u', isEmailVerified: false),
      ),
      isNull,
    );
    expect((await db.collection('users').get()).docs, isEmpty);
  });
  test(
    'verified first use creates once and preserves existing user data',
    () async {
      final db = FakeFirebaseFirestore();
      final user = MockUser(
        uid: 'u',
        email: 'u@chibatech.ac.jp',
        isEmailVerified: true,
        displayName: '学生さん',
      );
      await ensureVerifiedProfile(db, user);
      await db.doc('users/u').update({
        'reviewCount': 7,
        'cwitterId': 'saved_id',
        'isActive': false,
      });
      await ensureVerifiedProfile(db, user);
      final record = (await db.doc('users/u').get()).data()!;
      expect(record['reviewCount'], 7);
      expect(record['cwitterId'], 'saved_id');
      expect(record['isActive'], false);
      expect(record['emailVerified'], true);
      expect(record['displayName'], '学生さん');
    },
  );
  test(
    'registration synchronizes a chosen name without resetting the profile',
    () async {
      final db = FakeFirebaseFirestore();
      final user = MockUser(
        uid: 'u',
        email: 'u@chibatech.ac.jp',
        isEmailVerified: true,
        displayName: '仮の名前',
      );
      await ensureVerifiedProfile(db, user);
      await db.doc('users/u').update({'reviewCount': 4});
      await user.updateDisplayName('設定した名前');
      await ensureVerifiedProfile(db, user, syncDisplayName: true);
      final result = (await db.doc('users/u').get()).data()!;
      expect(result['displayName'], '設定した名前');
      expect(result['reviewCount'], 4);
    },
  );
}
