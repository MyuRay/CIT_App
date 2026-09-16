import 'package:cit_app/core/constants/app_constants.dart';
import 'package:cit_app/services/auth/legal_consent_service.dart';
import 'package:cit_app/services/auth/verified_profile.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeFirebaseFirestore db;
  late SharedPreferences preferences;
  late LegalConsentService service;
  final student = MockUser(
    uid: 'student',
    email: 'student@chibatech.ac.jp',
    isEmailVerified: true,
  );
  final other = MockUser(
    uid: 'other',
    email: 'other@chibatech.ac.jp',
    isEmailVerified: true,
  );
  setUp(() async {
    db = FakeFirebaseFirestore();
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    service = LegalConsentService(db, preferences);
  });

  test(
    'registration consent survives a fresh device and normal profile sync',
    () async {
      await ensureVerifiedProfile(
        db,
        student,
        acceptedLegalConsentVersion: AppConstants.currentLegalConsentVersion,
      );
      await ensureVerifiedProfile(db, student);
      expect(preferences.getKeys(), isEmpty);
      expect(await service.hasAccepted(student), isTrue);
      expect(hasCachedLegalConsent(preferences, student.uid), isTrue);
      final record = (await db.doc('users/student').get()).data()!;
      expect(
        record['legalConsentVersion'],
        AppConstants.currentLegalConsentVersion,
      );
      expect(record['legalConsentRecordedAt'], isNotNull);
    },
  );

  test(
    'ordinary profile creation does not imply agreement with the update',
    () async {
      await ensureVerifiedProfile(db, student);
      expect(await service.hasAccepted(student), isFalse);
      expect(
        (await db.doc('users/student').get()).data()!['legalConsentVersion'],
        isNull,
      );
    },
  );

  test('old consent versions still require the update notice', () async {
    await db.doc('users/student').set({'legalConsentVersion': '2025-old'});
    await preferences.setString(
      legalConsentKeyForUser(student.uid),
      '2025-old',
    );
    expect(await service.hasAccepted(student), isFalse);
  });

  test(
    'update acceptance persists without replacing existing profile data',
    () async {
      await ensureVerifiedProfile(db, student);
      await db.doc('users/student').update({
        'cwitterId': 'kept',
        'reviewCount': 8,
      });
      await service.accept(student);
      final record = (await db.doc('users/student').get()).data()!;
      expect(record['cwitterId'], 'kept');
      expect(record['reviewCount'], 8);
      expect(await service.hasAccepted(student), isTrue);
      expect(await service.hasAccepted(other), isFalse);
      await preferences.clear();
      expect(await service.hasAccepted(student), isTrue);
    },
  );

  test(
    'device-wide or other-account consent never skips a user agreement',
    () async {
      await preferences.setString(
        AppConstants.legalConsentAcceptedVersionKey,
        AppConstants.currentLegalConsentVersion,
      );
      await preferences.setString('user_uid', student.uid);
      await cacheLegalConsentAcceptance(preferences, other.uid);
      expect(await service.hasAccepted(student), isFalse);
    },
  );

  test(
    'unverified sessions cannot record agreement or create profiles',
    () async {
      final unverified = MockUser(uid: 'unverified', isEmailVerified: false);
      await expectLater(service.accept(unverified), throwsStateError);
      expect(await service.hasAccepted(unverified), isFalse);
      expect((await db.collection('users').get()).docs, isEmpty);
      expect(preferences.getKeys(), isEmpty);
    },
  );
}
