import 'package:cit_app/services/auth/email_registration.dart';
import 'package:cit_app/services/auth/legal_consent_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../support/registration_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;
  late RegistrationTestUser user;
  late RegistrationTestAuth auth;
  late EmailRegistrationService service;
  var profiles = 0;
  var failProfile = false;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    user = RegistrationTestUser();
    auth = RegistrationTestAuth(user);
    profiles = 0;
    failProfile = false;
    service = EmailRegistrationService(
      auth,
      preferences,
      saveProfile: (user) async {
        expect(user.emailVerified, isTrue);
        if (failProfile) throw StateError('offline');
        profiles++;
      },
    );
  });
  Future<bool> complete({
    String email = 'student@chibatech.ac.jp',
    String link = registrationTestLink,
  }) => service.complete(
    email: email,
    link: link,
    displayName: '学生さん',
    password: 'Password123',
  );

  test(
    'sending only remembers the email and never creates Auth/profile/password',
    () async {
      await service.sendLink(' Student@chibatech.ac.jp ');
      expect(auth.currentUser, isNull);
      expect(auth.unverifiedCreates, 0);
      expect(auth.consumes, 0);
      expect(profiles, 0);
      expect(user.passwordWrites, 0);
      expect(preferences.getKeys(), {registrationEmailKey});
      expect(service.pendingEmail, 'student@chibatech.ac.jp');
      expect(auth.settings!.handleCodeInApp, isTrue);
      expect(Uri.parse(auth.settings!.url).queryParameters, isEmpty);
    },
  );
  test('send failures and invalid domains never create accounts', () async {
    auth.failure = 'operation-not-allowed';
    await expectLater(
      service.sendLink('student@chibatech.ac.jp'),
      throwsA(isA<FirebaseAuthException>()),
    );
    await expectLater(
      service.sendLink('student@gmail.com'),
      throwsA(isA<FirebaseAuthException>()),
    );
    expect(auth.sends, 1);
    expect(preferences.getKeys(), isEmpty);
    expect(auth.currentUser, isNull);
  });
  test(
    'valid ownership proof precedes password and profile and clears draft',
    () async {
      await service.sendLink('student@chibatech.ac.jp');
      await complete();
      expect(auth.currentUser!.emailVerified, isTrue);
      expect(auth.consumes, 1);
      expect(auth.unverifiedCreates, 0);
      expect(user.chosenPassword, 'Password123');
      expect(user.displayName, '学生さん');
      expect(profiles, 1);
      expect(preferences.getKeys(), {legalConsentKeyForUser(user.uid)});
      expect(hasCachedLegalConsent(preferences, user.uid), isTrue);
    },
  );
  test('wrong email and expired proof cannot reach profile writes', () async {
    await expectLater(
      complete(email: 'another@chibatech.ac.jp'),
      throwsA(isA<FirebaseAuthException>()),
    );
    auth.failure = 'expired-action-code';
    await expectLater(complete(), throwsA(isA<FirebaseAuthException>()));
    expect(auth.currentUser, isNull);
    expect(profiles, 0);
    expect(user.passwordWrites, 0);
    expect(hasCachedLegalConsent(preferences, user.uid), isFalse);
  });
  test(
    'an unverified SDK result is rejected without password or profile writes',
    () async {
      final unverified = RegistrationTestUser(verified: false);
      final badAuth = RegistrationTestAuth(unverified);
      service = EmailRegistrationService(
        badAuth,
        preferences,
        saveProfile: (_) async => profiles++,
      );
      await expectLater(complete(), throwsA(isA<FirebaseAuthException>()));
      expect(badAuth.currentUser, isNull);
      expect(profiles, 0);
      expect(unverified.passwordWrites, 0);
    },
  );
  test(
    'password and profile failures resume without consuming a used link again',
    () async {
      user.failPassword = true;
      await expectLater(complete(), throwsA(isA<FirebaseAuthException>()));
      expect(service.hasPendingSetup, isTrue);
      expect(auth.currentUser!.emailVerified, isTrue);
      user.failPassword = false;
      failProfile = true;
      await expectLater(complete(), throwsStateError);
      failProfile = false;
      await complete();
      expect(auth.consumes, 1);
      expect(profiles, 1);
      expect(service.hasPendingSetup, isFalse);
    },
  );
  test(
    'existing identity keeps its display name when a new password is chosen',
    () async {
      await user.updateDisplayName('既存の名前');
      await complete();
      expect(user.displayName, '既存の名前');
      expect(user.chosenPassword, 'Password123');
    },
  );
  test(
    'a different active account cannot be silently replaced by a link',
    () async {
      await auth.signInWithCredential(null);
      await expectLater(complete(), throwsA(isA<FirebaseAuthException>()));
      expect(auth.consumes, 0);
      expect(profiles, 0);
    },
  );
  test('Hosting links unwrap safely and never use email query parameters', () {
    final nested = Uri.https(registrationAuthHost, '/__/auth/links', {
      'link': registrationTestLink,
    });
    expect(normalizeRegistrationLink(nested.toString()), registrationTestLink);
    expect(
      registrationLinkFromLocation(
        Uri.parse(
          nested.toString().replaceFirst('https://$registrationAuthHost', ''),
        ),
      ),
      registrationTestLink,
    );
    for (final bad in [
      registrationTestLink.replaceFirst('https:', 'http:'),
      registrationTestLink.replaceFirst(
        registrationAuthHost,
        'attacker.example',
      ),
      registrationTestLink.replaceFirst('signIn', 'verifyEmail'),
      'https://$registrationAuthHost/__/auth/links?link=https://attacker.example',
    ]) {
      expect(normalizeRegistrationLink(bad), isNull);
    }
  });
}
