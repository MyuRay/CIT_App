import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../services/user/user_service.dart';
import '../../services/notification/notification_service.dart';
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

// メール認証済みかどうかをチェックするプロバイダー
final isEmailVerifiedProvider = Provider<bool?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user?.emailVerified ?? false,
    loading: () => null,
    error: (_, __) => false,
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
    return AppConstants.isValidCitEmail(email);
  }

  bool isAllowedCITDomain(String email) {
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

      if (!AppConstants.isValidPasswordFormat(password)) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: password.length < 6
              ? AppConstants.errorWeakPassword
              : AppConstants.errorPasswordChars,
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
        // メール認証状態も含めて保存（初期はfalse）
        await UserService.createUser(appUser);
        print('✅ Firestoreにユーザー情報を保存しました: ${credential.user!.uid}');
      }

      // メール認証メールを送信
      try {
        await credential.user?.sendEmailVerification();
        print('✅ 認証メールを送信しました: ${credential.user?.email}');
      } catch (emailError) {
        print('⚠️ 認証メール送信エラー: $emailError');
        // メール送信エラーでもアカウント作成は成功しているため、続行
        // ユーザーは認証待ち画面から再送信可能
      }
      
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
      if (!isAllowedCITDomain(email)) {
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
        // メール認証状態を確認
        await credential.user!.reload();
        final refreshedUser = _auth.currentUser ?? credential.user!;
        print('📧 メール認証状態: ${refreshedUser.emailVerified}');
        
        print('📝 Firestoreユーザー情報確認中...');
        await UserService.getCurrentUserOrCreate();
        
        // メール認証状態をFirestoreに同期
        await UserService.syncEmailVerificationStatus(
          refreshedUser.uid,
          refreshedUser.emailVerified,
        );
        await UserService.syncEmailFromFirebaseAuth(refreshedUser);
        
        // 最終ログイン時刻を更新
        await UserService.updateLastLogin(credential.user!.uid);
        print('✅ Firestoreユーザー情報確認完了');

        // プッシュ通知を初期化
        try {
          print('🔔 プッシュ通知サービス初期化中...');
          await NotificationService.initialize();
          print('🔔 プッシュ通知サービス初期化完了');
        } catch (notificationError) {
          print('⚠️ プッシュ通知初期化エラー: $notificationError');
          // プッシュ通知エラーはログインを阻害しない
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

  Future<void> sendPasswordResetEmail({required String email}) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'メールアドレスを入力してください',
      );
    }
    if (!normalizedEmail.contains('@')) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: AppConstants.errorInvalidEmail,
      );
    }
    if (!isAllowedCITDomain(normalizedEmail)) {
      throw FirebaseAuthException(
        code: 'invalid-domain',
        message: AppConstants.errorInvalidDomain,
      );
    }
    await _auth.sendPasswordResetEmail(email: normalizedEmail);
  }

  Future<void> signOut() async {
    print('🔓 ログアウト処理開始');

    // Firebase Authからサインアウト
    await _auth.signOut();
    print('✅ Firebase Authからサインアウトしました');
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

  // メール認証状態をチェック（ユーザー情報を再読み込み）
  Future<bool> checkEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }
    await user.reload();
    final refreshedUser = _auth.currentUser;
    return refreshedUser?.emailVerified ?? false;
  }

  // 認証メールを再送信
  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'not-logged-in', message: 'ログインが必要です');
    }
    if (user.emailVerified) {
      throw FirebaseAuthException(code: 'already-verified', message: 'メールアドレスは既に認証済みです');
    }
    await user.sendEmailVerification();
  }

  /// パスワードで再認証したうえで、新しいメールアドレスへ確認メールを送信する。
  /// ユーザーがメール内のリンクを開くと Firebase Auth のメールが更新される。
  Future<String> requestEmailChange({
    required String currentPassword,
    required String newEmail,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'not-logged-in', message: 'ログインが必要です');
    }

    final currentEmail = user.email?.trim();
    if (currentEmail == null || currentEmail.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: '現在のメールアドレスを取得できません',
      );
    }

    final normalizedNew = newEmail.trim();
    if (normalizedNew.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: '新しいメールアドレスを入力してください',
      );
    }
    if (!normalizedNew.contains('@')) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: AppConstants.errorInvalidEmail,
      );
    }
    if (!isValidCITEmail(normalizedNew)) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: !AppConstants.isValidEmailLocalPart(normalizedNew)
            ? AppConstants.errorEmailLocalPart
            : AppConstants.errorInvalidDomain,
      );
    }
    if (normalizedNew.toLowerCase() == currentEmail.toLowerCase()) {
      throw FirebaseAuthException(
        code: 'same-email',
        message: '現在と同じメールアドレスです',
      );
    }

    if (currentPassword.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-password',
        message: 'パスワードを入力してください',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: currentEmail,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.verifyBeforeUpdateEmail(normalizedNew);
    return normalizedNew;
  }
}
