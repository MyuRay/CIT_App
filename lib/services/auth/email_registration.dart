import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import 'legal_consent_service.dart';

const registrationAuthHost = 'cit-app-2de1c.firebaseapp.com';
const registrationEmailKey = 'registration_pending_email';
const registrationSetupUidKey = 'registration_verified_setup_uid';

/// Only Firebase Hosting links for this project are accepted. Never take an
/// email address from the URL: the person must supply it or use their own draft.
String? normalizeRegistrationLink(String value) {
  var uri = Uri.tryParse(value.trim());
  for (var depth = 0; depth < 5 && uri != null; depth++) {
    if (uri.scheme != 'https' ||
        !{registrationAuthHost, 'cit-app-2de1c.web.app'}.contains(uri.host) ||
        uri.userInfo.isNotEmpty ||
        (uri.hasPort && uri.port != 443)) {
      return null;
    }
    if (uri.queryParameters['mode'] == 'signIn' &&
        (uri.queryParameters['oobCode']?.isNotEmpty ?? false) &&
        (uri.queryParameters['apiKey']?.isNotEmpty ?? false)) {
      return uri.toString();
    }
    final inner = uri.queryParameters['link'];
    if (inner == null) return null;
    uri = Uri.tryParse(inner);
  }
  return null;
}

/// GoRouter supplies a relative URI on Web and may do so on native startup.
String? registrationLinkFromLocation(Uri location) {
  if (!{'/__/auth/links', '/__/auth/action'}.contains(location.path)) {
    return null;
  }
  final absolute =
      location.hasScheme
          ? location
          : Uri.https(
            registrationAuthHost,
            location.path,
            location.queryParameters,
          );
  return normalizeRegistrationLink(absolute.toString());
}

class EmailRegistrationService {
  EmailRegistrationService(
    this.auth,
    this.preferences, {
    required this.saveProfile,
  });
  final FirebaseAuth auth;
  final SharedPreferences preferences;
  final Future<void> Function(User user) saveProfile;
  String? get pendingEmail => preferences.getString(registrationEmailKey);
  bool get hasPendingSetup =>
      auth.currentUser != null &&
      auth.currentUser!.emailVerified &&
      auth.currentUser!.uid == preferences.getString(registrationSetupUidKey);

  Future<void> sendLink(String email) async {
    final normalized = _validateEmail(email);
    await auth.setLanguageCode('ja');
    await auth.sendSignInLinkToEmail(
      email: normalized,
      actionCodeSettings: ActionCodeSettings(
        url: 'https://$registrationAuthHost/signup/complete',
        handleCodeInApp: true,
        androidPackageName: 'jp.ac.chibakoudai.citapp',
        androidInstallApp: false,
        iOSBundleId: 'com.masatomurai.citapp',
      ),
    );
    // No password, bearer link, or profile is stored before ownership proof.
    await preferences.setString(registrationEmailKey, normalized);
  }

  /// Fresh email proof can also recover legacy unverified accounts. Firebase
  /// removes their old password on proof, so explicitly set the chosen password.
  Future<bool> complete({
    required String email,
    required String link,
    required String displayName,
    required String password,
  }) async {
    final normalized = _validateEmail(email);
    if (displayName.trim().length < 2) {
      throw FirebaseAuthException(
        code: 'invalid-display-name',
        message: '表示名は2文字以上で入力してください',
      );
    }
    if (!AppConstants.isValidPasswordFormat(password)) {
      throw FirebaseAuthException(
        code: 'weak-password',
        message: AppConstants.validatePassword(password),
      );
    }
    var user = auth.currentUser;
    var setup = hasPendingSetup && user?.email?.toLowerCase() == normalized;
    if (!setup) {
      final verifiedLink = normalizeRegistrationLink(link);
      if (verifiedLink == null || !auth.isSignInWithEmailLink(verifiedLink)) {
        throw FirebaseAuthException(
          code: 'invalid-action-code',
          message: '確認メールにある登録リンクを開いてください',
        );
      }
      if (user != null) {
        throw FirebaseAuthException(
          code: 'already-signed-in',
          message: '登録する場合は、先に現在のアカウントからログアウトしてください',
        );
      }
      // This is the FIRST operation that can create an Auth account. Firebase
      // verifies the one-time email proof and creates an emailVerified user.
      final credential = await auth.signInWithEmailLink(
        email: normalized,
        emailLink: verifiedLink,
      );
      user = credential.user;
      if (user == null || !user.emailVerified) {
        await auth.signOut();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'メール認証を確認できませんでした。新しい確認メールでやり直してください',
        );
      }
      setup = true;
      await preferences.setString(registrationSetupUidKey, user.uid);
    }
    if (user == null || !user.emailVerified) {
      throw StateError('Verified user required');
    }
    if (setup) {
      // Failed password/profile writes can resume without reusing a spent link.
      await user.updatePassword(password);
      if (user.displayName?.trim().isNotEmpty != true) {
        await user.updateDisplayName(displayName.trim());
      }
      await user.reload();
      user = auth.currentUser ?? user;
    }
    await user.getIdToken(true);
    await saveProfile(user);
    await cacheLegalConsentAcceptance(preferences, user.uid);
    await preferences.remove(registrationSetupUidKey);
    await preferences.remove(registrationEmailKey);
    return setup;
  }

  static String _validateEmail(String email) {
    final normalized = email.trim().toLowerCase();
    if (!AppConstants.isValidCitEmailForSignup(normalized)) {
      throw FirebaseAuthException(
        code: 'invalid-domain',
        message: AppConstants.errorSignupInvalidDomain,
      );
    }
    return normalized;
  }
}

String registrationErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'operation-not-allowed':
        return 'メール登録が利用できません。運営側の認証設定の確認が必要です。';
      case 'invalid-action-code':
      case 'expired-action-code':
      case 'invalid-credential':
        return 'リンクが無効・使用済み・期限切れ、またはメールアドレスが一致しません。新しい確認メールでやり直してください。';
      case 'too-many-requests':
        return '送信・試行回数が多すぎます。しばらく待ってから再試行してください。';
      case 'network-request-failed':
        return '通信できませんでした。接続を確認して再試行してください。';
      case 'requires-recent-login':
        return '確認から時間が経過しました。ログアウトして新しい確認メールでやり直してください。';
      default:
        return error.message ?? '登録を完了できませんでした。もう一度お試しください。';
    }
  }
  return '保存を完了できませんでした。入力を残しているので、通信状態を確認して再試行してください。';
}
