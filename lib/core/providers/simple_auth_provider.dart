import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart' show firebaseAuthProvider;

/// シンプルな認証プロバイダー
/// Firebase Auth の永続セッションをそのまま信頼する（起動時の reload / 強制 signOut は行わない）
final simpleAuthStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).idTokenChanges();
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

/// 認証状態は Firebase Auth を正とし、プロフィールの自己申告を使用しない。
final isEmailVerifiedSimpleProvider = StreamProvider<bool?>((ref) {
  final authState = ref.watch(simpleAuthStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(false);
      }

      return Stream.value(user.emailVerified);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(false),
  );
});

/// メール認証済みかどうか（同期版、ルーター用）
final isEmailVerifiedSyncProvider = Provider<bool?>((ref) {
  final authState = ref.watch(simpleAuthStateProvider);

  return authState.when(
    data: (user) => user?.emailVerified ?? false,
    loading: () => null,
    error: (_, __) => false,
  );
});
