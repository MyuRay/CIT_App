import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/community/cwitter_post.dart';

/// recweet タップ直後の楽観的表示（Firestore 反映待ち）
class CwitterRecweetOverride {
  const CwitterRecweetOverride({
    required this.isRecweeted,
    required this.recweetCount,
  });

  final bool isRecweeted;
  final int recweetCount;
}

class CwitterRecweetOverrideNotifier
    extends StateNotifier<Map<String, CwitterRecweetOverride>> {
  CwitterRecweetOverrideNotifier() : super({});

  void apply({
    required String postId,
    required bool isRecweeted,
    required int recweetCount,
  }) {
    state = {
      ...state,
      postId: CwitterRecweetOverride(
        isRecweeted: isRecweeted,
        recweetCount: recweetCount,
      ),
    };
  }

  void revert(String postId) {
    if (!state.containsKey(postId)) return;
    final next = Map<String, CwitterRecweetOverride>.from(state);
    next.remove(postId);
    state = next;
  }

  /// サーバー側の値と一致したらオーバーライドを外す
  void syncWithPosts(
    List<CwitterPost> posts,
    String? uid,
    bool Function(String postId) serverIsRecweeted,
  ) {
    if (uid == null || state.isEmpty) return;

    final next = Map<String, CwitterRecweetOverride>.from(state);
    var changed = false;

    for (final post in posts) {
      final override = next[post.id];
      if (override == null) continue;

      final serverRecweeted = serverIsRecweeted(post.id);
      if (serverRecweeted == override.isRecweeted &&
          post.recweetCount == override.recweetCount) {
        next.remove(post.id);
        changed = true;
      }
    }

    if (changed) state = next;
  }
}

final cwitterRecweetOverrideProvider = StateNotifierProvider<
    CwitterRecweetOverrideNotifier, Map<String, CwitterRecweetOverride>>(
  (ref) => CwitterRecweetOverrideNotifier(),
);
