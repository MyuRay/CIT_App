import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/community/cwitter_follow_counts.dart';

/// フォロー操作直後の楽観的表示（Firestore 反映待ち）
class CwitterFollowCountsOverride {
  const CwitterFollowCountsOverride({
    this.followerCount,
    this.followingCount,
  });

  final int? followerCount;
  final int? followingCount;
}

class CwitterFollowCountsOverrideNotifier
    extends StateNotifier<Map<String, CwitterFollowCountsOverride>> {
  CwitterFollowCountsOverrideNotifier() : super({});

  void apply({
    required String userId,
    int? followerCount,
    int? followingCount,
  }) {
    if (followerCount == null && followingCount == null) return;

    final current = state[userId];
    state = {
      ...state,
      userId: CwitterFollowCountsOverride(
        followerCount: followerCount ?? current?.followerCount,
        followingCount: followingCount ?? current?.followingCount,
      ),
    };
  }

  void revert(String userId) {
    if (!state.containsKey(userId)) return;
    final next = Map<String, CwitterFollowCountsOverride>.from(state);
    next.remove(userId);
    state = next;
  }

  void revertPair(String userIdA, String userIdB) {
    final next = Map<String, CwitterFollowCountsOverride>.from(state);
    next.remove(userIdA);
    next.remove(userIdB);
    if (next.length != state.length) {
      state = next;
    }
  }

  /// サーバー側の値と一致したらオーバーライドを外す
  void syncWithCounts(String userId, CwitterFollowCounts server) {
    final override = state[userId];
    if (override == null) return;

    final followerSynced =
        override.followerCount == null || override.followerCount == server.followerCount;
    final followingSynced = override.followingCount == null ||
        override.followingCount == server.followingCount;

    if (followerSynced && followingSynced) {
      revert(userId);
    }
  }
}

final cwitterFollowCountsOverrideProvider = StateNotifierProvider<
    CwitterFollowCountsOverrideNotifier,
    Map<String, CwitterFollowCountsOverride>>(
  (ref) => CwitterFollowCountsOverrideNotifier(),
);

CwitterFollowCounts resolveCwitterFollowCounts({
  required CwitterFollowCounts server,
  required CwitterFollowCountsOverride? override,
}) {
  if (override == null) return server;
  return CwitterFollowCounts(
    followerCount: override.followerCount ?? server.followerCount,
    followingCount: override.followingCount ?? server.followingCount,
  );
}
