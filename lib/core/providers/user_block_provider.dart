import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/users/blocked_user_model.dart';
import '../../services/users/user_block_service.dart';
import '../../services/community/user_ban_service.dart';
import 'schedule_provider.dart';

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
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    return Stream.value(const <BlockedUser>[]);
  }
  return UserBlockService.watchBlockedUsers();
});

// ブロック済みユーザーID一覧プロバイダー
final blockedUserIdsProvider = FutureProvider<Set<String>>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    return const {};
  }
  return UserBlockService.getBlockedUserIds();
});

/// 表示対象外ユーザーID（自分がブロック + 自分をブロック + 運営によるBAN中）
final hiddenUserIdsProvider = StreamProvider<Set<String>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    return Stream.value(<String>{});
  }
  return _mergeIdSetStreams([
    UserBlockService.watchHiddenUserIds(),
    UserBanService.watchActiveBannedUserIds(),
  ]);
});

/// 複数の ID 集合ストリームを「最新値の和集合」として 1 本にまとめる。
Stream<Set<String>> _mergeIdSetStreams(List<Stream<Set<String>>> streams) {
  return Stream.multi((controller) {
    final latest = List<Set<String>>.generate(
      streams.length,
      (_) => <String>{},
    );
    final subscriptions = <StreamSubscription<Set<String>>>[];

    void emit() {
      final merged = <String>{};
      for (final set in latest) {
        merged.addAll(set);
      }
      controller.add(merged);
    }

    for (var i = 0; i < streams.length; i++) {
      final index = i;
      subscriptions.add(
        streams[i].listen(
          (value) {
            latest[index] = value;
            emit();
          },
          onError: controller.addError,
        ),
      );
    }

    controller.onCancel = () async {
      for (final sub in subscriptions) {
        await sub.cancel();
      }
    };
  });
}

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
