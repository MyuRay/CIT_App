import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_constants.dart';

/// ログイン時の Firebase Auth エラーをユーザー向けメッセージに変換する。
String loginAuthErrorMessage(FirebaseAuthException e) {
  final code = e.code.toLowerCase();
  switch (code) {
    case 'wrong-password':
    case 'invalid-credential':
    case 'invalid-login-credentials':
    case 'user-not-found':
      return AppConstants.errorLoginInvalidCredentials;
    case 'invalid-domain':
      return AppConstants.errorInvalidDomain;
    case 'invalid-email':
      return AppConstants.errorInvalidEmail;
    case 'user-disabled':
      return 'このアカウントは無効になっています';
    case 'too-many-requests':
      return '試行回数が多すぎます。しばらく待ってから再試行してください';
    default:
      break;
  }

  final msg = (e.message ?? '').toLowerCase();
  if (msg.contains('invalid-credential') ||
      msg.contains('invalid login') ||
      msg.contains('wrong password') ||
      msg.contains('incorrect password') ||
      msg.contains('no user record')) {
    return AppConstants.errorLoginInvalidCredentials;
  }

  return e.message ?? 'ログインに失敗しました';
}
