import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// シンプルな認証プロバイダー
/// Firebase Authの状態のみを信頼し、複雑なロジックを排除
final simpleAuthStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
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
