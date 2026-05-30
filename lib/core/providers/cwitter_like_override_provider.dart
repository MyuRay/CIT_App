import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/community/cwitter_post.dart';

/// いいねタップ直後の楽観的表示（Firestore 反映待ち）
class CwitterLikeOverride {
  const CwitterLikeOverride({
    required this.isLiked,
    required this.likeCount,
  });

  final bool isLiked;
  final int likeCount;
}

class CwitterLikeOverrideNotifier
    extends StateNotifier<Map<String, CwitterLikeOverride>> {
  CwitterLikeOverrideNotifier() : super({});

  void apply({
    required String postId,
    required bool isLiked,
    required int likeCount,
  }) {
    state = {
      ...state,
      postId: CwitterLikeOverride(isLiked: isLiked, likeCount: likeCount),
    };
  }

  void revert(String postId) {
    if (!state.containsKey(postId)) return;
    final next = Map<String, CwitterLikeOverride>.from(state);
    next.remove(postId);
    state = next;
  }

  /// サーバー側の値と一致したらオーバーライドを外す
  void syncWithPosts(List<CwitterPost> posts, String? uid) {
    if (uid == null || state.isEmpty) return;

    final next = Map<String, CwitterLikeOverride>.from(state);
    var changed = false;

    for (final post in posts) {
      final override = next[post.id];
      if (override == null) continue;

      final serverLiked = post.isLikedBy(uid);
      if (serverLiked == override.isLiked &&
          post.likeCount == override.likeCount) {
        next.remove(post.id);
        changed = true;
      }
    }

    if (changed) state = next;
  }
}

final cwitterLikeOverrideProvider = StateNotifierProvider<
    CwitterLikeOverrideNotifier, Map<String, CwitterLikeOverride>>(
  (ref) => CwitterLikeOverrideNotifier(),
);
