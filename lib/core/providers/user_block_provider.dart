import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/users/blocked_user_model.dart';
import '../../services/users/user_block_service.dart';

// ブロック操作状態を管理するStateNotifier
class UserBlockNotifier extends StateNotifier<AsyncValue<void>> {
  UserBlockNotifier() : super(const AsyncValue.data(null));

  /// ユーザーをブロック
  Future<void> blockUser({
    required String blockedUserId,
    required String blockedUserName,
    required BlockReason reason,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await UserBlockService.blockUser(
        blockedUserId: blockedUserId,
        blockedUserName: blockedUserName,
        reason: reason,
        notes: notes,
      );
    });
  }

  /// ユーザーのブロックを解除
  Future<void> unblockUser({
    required String blockedUserId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await UserBlockService.unblockUser(
        blockedUserId: blockedUserId,
      );
    });
  }

  /// 状態をリセット
  void reset() {
    state = const AsyncValue.data(null);
  }
}

// ブロック操作プロバイダー
final userBlockProvider = StateNotifierProvider<UserBlockNotifier, AsyncValue<void>>((ref) {
  return UserBlockNotifier();
});

// ブロック済みユーザー一覧プロバイダー（Stream）
final blockedUsersProvider = StreamProvider<List<BlockedUser>>((ref) {
  return UserBlockService.watchBlockedUsers();
});

// ブロック済みユーザーID一覧プロバイダー
final blockedUserIdsProvider = FutureProvider<Set<String>>((ref) async {
  return await UserBlockService.getBlockedUserIds();
});

// 特定ユーザーのブロック状態チェックプロバイダー
final isUserBlockedProvider = FutureProvider.family<bool, String>((ref, blockedUserId) async {
  return await UserBlockService.isBlocked(
    blockedUserId: blockedUserId,
  );
});

// ブロック数プロバイダー
final blockedUserCountProvider = FutureProvider<int>((ref) async {
  return await UserBlockService.getBlockedUserCount();
});

// ブロック済みユーザー一覧プロバイダー（Future版）
final blockedUsersListProvider = FutureProvider<List<BlockedUser>>((ref) async {
  return await UserBlockService.getBlockedUsers();
});
