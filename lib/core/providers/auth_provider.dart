import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../services/user/user_service.dart';
import '../../models/user/user_model.dart';
import 'settings_provider.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  try {
    final auth = ref.watch(firebaseAuthProvider);
    print('🔐 AuthStateProvider: 認証状態変更リスナーを設定');
    
    return auth.authStateChanges().map((user) {
      if (user != null) {
        print('✅ AuthStateProvider: ユーザーログイン検出 - UID: ${user.uid}');
        print('✅ AuthStateProvider: メール: ${user.email}');
        print('✅ AuthStateProvider: メール認証済み: ${user.emailVerified}');
      } else {
        print('❌ AuthStateProvider: ユーザーログアウト検出');
      }
      return user;
    });
  } catch (e) {
    print('❌ AuthStateProvider: エラー - $e');
    // Firebase未初期化の場合はnullユーザーのStreamを返す
    return Stream.value(null);
  }
});

final isLoggedInProvider = Provider<bool?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user != null,
    loading: () => null, // ロード中は判定を保留
    error: (_, __) => false, // Firebase未初期化時は未ログイン状態
  );
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider));
});

// 現在のユーザー表示名プロバイダー
final currentUserDisplayNameProvider = Provider<String>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.getCurrentUserDisplayName();
});

class AuthService {
  final FirebaseAuth _auth;

  AuthService(this._auth);

  bool isValidCITEmail(String email) {
    return AppConstants.isAllowedDomain(email);
  }

  Future<UserCredential?> signUpWithEmailAndPassword({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      if (!isValidCITEmail(email)) {
        throw FirebaseAuthException(
          code: 'invalid-domain',
          message: AppConstants.errorInvalidDomain,
        );
      }

      final trimmedName = displayName.trim();
      if (trimmedName.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-display-name',
          message: '表示名を入力してください',
        );
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firebase Authでアカウント作成成功後、表示名を設定しFirestoreにも保存
      if (credential.user != null) {
        await credential.user!.updateDisplayName(trimmedName);
        await credential.user!.reload();
        final refreshedUser = _auth.currentUser ?? credential.user!;
        final appUser = UserService.createAppUserFromFirebaseUser(refreshedUser)
            .copyWith(displayName: trimmedName);
        await UserService.createUser(appUser);
        print('✅ Firestoreにユーザー情報を保存しました: ${credential.user!.uid}');
      }

      await credential.user?.sendEmailVerification();
      return credential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      print('❌ アカウント作成エラー: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      if (!isValidCITEmail(email)) {
        throw FirebaseAuthException(
          code: 'invalid-domain',
          message: AppConstants.errorInvalidDomain,
        );
      }

      print('🔐 Firebase Auth ログイン試行中...');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ Firebase Auth ログイン成功');

      // ログイン成功後、Firestoreにユーザー情報が存在するか確認し、なければ作成
      if (credential.user != null) {
        print('📝 Firestoreユーザー情報確認中...');
        await UserService.getCurrentUserOrCreate();
        print('✅ Firestoreユーザー情報確認完了');
        
        // SharedPreferencesにもログイン状態を保存（バックアップ）
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('user_logged_in', true);
          await prefs.setString('user_uid', credential.user!.uid);
          await prefs.setString('user_email', credential.user!.email ?? '');
          
          // ログイン時刻も記録（デバッグ用）
          await prefs.setString('last_login_time', DateTime.now().toIso8601String());
          
          print('✅ SharedPreferencesにログイン状態を保存しました');
          print('✅ UID: ${credential.user!.uid}');
          print('✅ Email: ${credential.user!.email}');
        } catch (prefsError) {
          print('⚠️ SharedPreferences保存に失敗: $prefsError');
          // SharedPreferencesエラーはログインを阻害しない
        }
      }

      return credential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      print('❌ ログインエラー: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    
    // SharedPreferencesからもログイン状態を削除
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_logged_in');
      await prefs.remove('user_uid');
      await prefs.remove('user_email');
      print('✅ SharedPreferencesからログイン状態を削除しました');
    } catch (prefsError) {
      print('⚠️ SharedPreferences削除に失敗: $prefsError');
      // SharedPreferencesエラーはサインアウトを阻害しない
    }
  }

  User? get currentUser => _auth.currentUser;
  
  // 現在のユーザーの表示名を取得
  String getCurrentUserDisplayName() {
    final user = _auth.currentUser;
    if (user == null) {
      return '匿名ユーザー';
    }
    
    // displayNameが設定されている場合はそれを使用
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    
    // displayNameがない場合はメールアドレスから推測
    if (user.email != null && user.email!.isNotEmpty) {
      return user.email!.split('@').first;
    }
    
    return '匿名ユーザー';
  }

  // 表示名を更新（コメント表示名としても使用）
  Future<void> updateDisplayName(String newName) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'not-logged-in', message: 'ログインが必要です');
    }
    await user.updateDisplayName(newName);
    await user.reload();
    // Firestoreのプロフィールも更新（存在しない場合はスキップ）
    try {
      await UserService.updateUserProfile(uid: user.uid, displayName: newName);
    } catch (_) {
      // Firestore側が未作成のケース等は無視
    }
  }
}
