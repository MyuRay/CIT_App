import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 再インストール後の Android Auto Backup 復元で SharedPreferences と
/// Firebase Auth の永続セッションが不整合になる問題を検出して修復する。
class AuthStorageReconciler {
  static const _authPreferenceKeys = <String>[
    'user_logged_in',
    'user_uid',
    'user_email',
    'last_auth_time',
    'last_access_time',
    'auth_token',
  ];

  static Future<void> reconcileAfterFirebaseInit() async {
    if (kIsWeb) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final auth = FirebaseAuth.instance;

      // Firebase Auth のディスク復元を待つ
      User? user = auth.currentUser;
      user ??= await auth.authStateChanges().first.timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );

      final wasLoggedIn = prefs.getBool('user_logged_in') ?? false;
      final hasAuthToken = (prefs.getString('auth_token') ?? '').isNotEmpty;

      if (user == null && (wasLoggedIn || hasAuthToken)) {
        debugPrint(
          '⚠️ 認証ストレージ不整合を検出（SharedPreferences のみログイン状態）。'
          '再インストール後の Auto Backup 復元が原因の可能性があります。キャッシュをクリアします。',
        );
        await _clearAuthPreferences(prefs);
      }
    } catch (e) {
      debugPrint('認証ストレージ整合チェックエラー: $e');
    }
  }

  static Future<void> _clearAuthPreferences(SharedPreferences prefs) async {
    for (final key in _authPreferenceKeys) {
      await prefs.remove(key);
    }
  }
}
