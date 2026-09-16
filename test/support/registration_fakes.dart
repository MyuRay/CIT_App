import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

// MockUser intentionally mutates Firebase user attributes in tests.
// ignore: must_be_immutable
class RegistrationTestUser extends MockUser {
  RegistrationTestUser({bool verified = true, String? name})
    : super(
        uid: 'verified-user',
        email: 'student@chibatech.ac.jp',
        isEmailVerified: verified,
        displayName: name,
      );
  int passwordWrites = 0;
  bool failPassword = false;
  String? chosenPassword;
  @override
  Future<void> updatePassword(String password) async {
    passwordWrites++;
    if (failPassword) {
      throw FirebaseAuthException(code: 'network-request-failed');
    }
    chosenPassword = password;
  }
}

class RegistrationTestAuth extends MockFirebaseAuth {
  RegistrationTestAuth(this.testUser, {super.signedIn = false})
    : super(mockUser: testUser);
  final RegistrationTestUser testUser;
  int sends = 0, consumes = 0, unverifiedCreates = 0;
  ActionCodeSettings? settings;
  String? consumedEmail;
  String? failure;
  @override
  Stream<User?> idTokenChanges() => authStateChanges();
  @override
  Future<void> setLanguageCode(String? languageCode) async {}
  @override
  Future<void> sendSignInLinkToEmail({
    required String email,
    required ActionCodeSettings actionCodeSettings,
  }) async {
    sends++;
    if (failure != null) throw FirebaseAuthException(code: failure!);
    settings = actionCodeSettings;
  }

  @override
  bool isSignInWithEmailLink(String link) =>
      Uri.parse(link).queryParameters['mode'] == 'signIn';
  @override
  Future<UserCredential> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    consumes++;
    consumedEmail = email;
    if (failure != null) throw FirebaseAuthException(code: failure!);
    if (email != testUser.email) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    return signInWithCredential(null);
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    unverifiedCreates++;
    throw StateError('Unverified creation is forbidden');
  }
}

const registrationTestLink =
    'https://cit-app-2de1c.firebaseapp.com/__/auth/action?mode=signIn&oobCode=test-proof&apiKey=test-key';
