import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/community/cwitter_post.dart';

/// 返信送信・削除直後の楽観的表示（Firestore 反映待ち）
class CwitterReplyCountOverride {
  const CwitterReplyCountOverride({required this.replyCount});

  final int replyCount;
}

class CwitterReplyCountOverrideNotifier
    extends StateNotifier<Map<String, CwitterReplyCountOverride>> {
  CwitterReplyCountOverrideNotifier() : super({});

  void apply({
    required String postId,
    required int replyCount,
  }) {
    state = {
      ...state,
      postId: CwitterReplyCountOverride(
        replyCount: replyCount < 0 ? 0 : replyCount,
      ),
    };
  }

  void revert(String postId) {
    if (!state.containsKey(postId)) return;
    final next = Map<String, CwitterReplyCountOverride>.from(state);
    next.remove(postId);
    state = next;
  }

  /// サーバー側の値と一致したらオーバーライドを外す
  void syncWithCount(String postId, int serverCount) {
    final override = state[postId];
    if (override == null) return;

    if (override.replyCount == serverCount) {
      revert(postId);
    }
  }

  void syncWithPosts(List<CwitterPost> posts) {
    if (state.isEmpty) return;

    final next = Map<String, CwitterReplyCountOverride>.from(state);
    var changed = false;

    for (final post in posts) {
      final override = next[post.id];
      if (override == null) continue;

      if (post.replyCount == override.replyCount) {
        next.remove(post.id);
        changed = true;
      }
    }

    if (changed) state = next;
  }
}

final cwitterReplyCountOverrideProvider = StateNotifierProvider<
    CwitterReplyCountOverrideNotifier, Map<String, CwitterReplyCountOverride>>(
  (ref) => CwitterReplyCountOverrideNotifier(),
);

int resolveCwitterReplyCount({
  required CwitterPost post,
  required CwitterReplyCountOverride? override,
  required int? streamCount,
}) {
  if (override != null) return override.replyCount;
  if (streamCount != null) return streamCount;
  return post.replyCount;
}
