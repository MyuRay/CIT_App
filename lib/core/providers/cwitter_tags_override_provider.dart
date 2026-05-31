import 'package:hooks_riverpod/hooks_riverpod.dart';

/// ハッシュタグ更新直後の楽観的表示（Firestore 反映待ち）
class CwitterTagsOverrideNotifier
    extends StateNotifier<Map<String, List<String>>> {
  CwitterTagsOverrideNotifier() : super({});

  void apply({required String userId, required List<String> tags}) {
    state = {...state, userId: List<String>.from(tags)};
  }

  void revert(String userId) {
    if (!state.containsKey(userId)) return;
    final next = Map<String, List<String>>.from(state);
    next.remove(userId);
    state = next;
  }

  /// サーバー側の値と一致したらオーバーライドを外す
  void syncWithTags(String userId, List<String> serverTags) {
    final override = state[userId];
    if (override == null) return;

    if (_tagsEqual(override, serverTags)) {
      revert(userId);
    }
  }

  bool _tagsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

final cwitterTagsOverrideProvider = StateNotifierProvider<
    CwitterTagsOverrideNotifier, Map<String, List<String>>>(
  (ref) => CwitterTagsOverrideNotifier(),
);
