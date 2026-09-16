import 'dart:convert';
import 'dart:io';

import 'package:cit_app/core/constants/app_constants.dart';
import 'package:cit_app/services/auth/email_registration.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RegistrationAuth extends MockFirebaseAuth {
  int sendCalls = 0;
  int completeCalls = 0;

  @override
  Future<void> sendSignInLinkToEmail({
    required String email,
    required ActionCodeSettings actionCodeSettings,
  }) async {
    sendCalls++;
  }

  @override
  Future<UserCredential> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    completeCalls++;
    throw StateError('Disallowed email reached Firebase account creation');
  }
}

void main() {
  final cases =
      jsonDecode(
            File(
              'test/fixtures/registration_email_policy.json',
            ).readAsStringSync(),
          )
          as List<dynamic>;

  for (final entry in cases) {
    final email = entry['email'] as String;
    final allowed = entry['allowed'] as bool;
    test('registration domain policy: ${jsonEncode(email)}', () {
      expect(AppConstants.isValidCitEmailForSignup(email), allowed);
      expect(AppConstants.validateCitEmailForSignup(email) == null, allowed);
    });
  }

  test('trims copied addresses and allows only the new signup domain', () {
    expect(AppConstants.signupAllowedDomains, ['@chibatech.ac.jp']);
    expect(
      AppConstants.validateCitEmailForSignup(' Student@CHIBATECH.AC.JP '),
      isNull,
    );
  });

  test('legacy users can log in but cannot register a new account', () {
    for (final domain in AppConstants.legacyEmailDomains) {
      final email = 'student$domain';
      expect(AppConstants.isAllowedDomain(email), isTrue);
      expect(AppConstants.validateCitEmail(email), isNull);
      expect(
        AppConstants.validateCitEmailForSignup(email),
        AppConstants.errorSignupInvalidDomain,
      );
    }
  });

  test('domain helpers reject multiple @ signs and empty local parts', () {
    for (final email in [
      'student@example.com@chibatech.ac.jp',
      'student@@chibatech.ac.jp',
      '@chibatech.ac.jp',
    ]) {
      expect(AppConstants.isAllowedDomain(email), isFalse);
      expect(AppConstants.isAllowedSignupDomain(email), isFalse);
    }
  });

  for (final completing in [false, true]) {
    test('registration service rejects disallowed emails before Firebase '
        '(completing=$completing)', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final auth = _RegistrationAuth();
      var savedProfiles = 0;
      final service = EmailRegistrationService(
        auth,
        preferences,
        saveProfile: (_) async {
          savedProfiles++;
        },
      );
      for (final entry in cases.where((entry) => entry['allowed'] == false)) {
        final email = entry['email'] as String;
        final operation =
            completing
                ? service.complete(
                  email: email,
                  link:
                      'https://$registrationAuthHost/__/auth/action'
                      '?mode=signIn&oobCode=test&apiKey=test',
                  displayName: 'テスト学生',
                  password: 'testpass123',
                )
                : service.sendLink(email);
        await expectLater(
          operation,
          throwsA(
            isA<FirebaseAuthException>().having(
              (error) => error.code,
              'code',
              'invalid-domain',
            ),
          ),
        );
      }
      expect(auth.sendCalls, 0);
      expect(auth.completeCalls, 0);
      expect(savedProfiles, 0);
      expect(preferences.getString(registrationEmailKey), isNull);
      expect(auth.currentUser, isNull);
    });
  }
}
