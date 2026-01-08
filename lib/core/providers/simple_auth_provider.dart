import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user/user_model.dart';
import '../../services/user/user_service.dart';

/// シンプルな認証プロバイダー
/// Firebase Authの状態のみを信頼し、複雑なロジックを排除
final simpleAuthStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges().asyncMap((user) async {
    // ユーザー情報を最新の状態に更新（メール認証状態を含む）
    if (user != null) {
      try {
        await user.reload();
        // reload()後、最新のユーザー情報を取得
        final refreshedUser = FirebaseAuth.instance.currentUser;
        if (refreshedUser != null) {
          // Firestoreにメール認証状態を同期
          await UserService.syncEmailVerificationStatus(
            refreshedUser.uid,
            refreshedUser.emailVerified,
          );
        }
        return refreshedUser;
      } catch (e) {
        print('⚠️ ユーザー情報リロードエラー: $e');
        return user;
      }
    }
    return user;
  });
});

/// ログイン状態の判定（シンプル版）
final isLoggedInSimpleProvider = Provider<bool?>((ref) {
  final authState = ref.watch(simpleAuthStateProvider);

  return authState.when(
    data: (user) => user != null,
    loading: () => null, // ロード中は判定保留
    error: (_, __) => false, // エラー時は未ログイン
  );
});

/// 現在のユーザー（シンプル版）
final currentUserSimpleProvider = Provider<User?>((ref) {
  final authState = ref.watch(simpleAuthStateProvider);

  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// メール認証済みかどうか（Firestoreから取得）
final isEmailVerifiedSimpleProvider = StreamProvider<bool?>((ref) {
  final authState = ref.watch(simpleAuthStateProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(false);
      }
      
      // Firestoreのユーザードキュメントをリアルタイム監視
      return UserService.watchUser(user.uid).map((appUser) {
        return appUser?.emailVerified ?? false;
      });
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(false),
  );
});

/// メール認証済みかどうか（同期版、ルーター用）
final isEmailVerifiedSyncProvider = Provider<bool?>((ref) {
  final emailVerifiedAsync = ref.watch(isEmailVerifiedSimpleProvider);
  
  return emailVerifiedAsync.when(
    data: (verified) => verified,
    loading: () => null,
    error: (_, __) => false,
  );
});