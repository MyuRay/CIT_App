import 'cwitter_post.dart';
import 'cwitter_recweet.dart';

/// フィード表示用（通常 Cweet または recweet 付き）
class CwitterFeedItem {
  const CwitterFeedItem({
    required this.post,
    required this.sortAt,
    this.recweet,
  });

  final CwitterPost post;
  final CwitterRecweet? recweet;
  final DateTime sortAt;

  bool get isRecweet => recweet != null;
}
