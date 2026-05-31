import 'cwitter_post.dart';
import 'cwitter_recweet.dart';
import 'cwitter_reply.dart';

enum CwitterProfileActivityKind { post, reply, recweet }

/// プロフィールの投稿一覧用（投稿 + 返信を時系列で表示）
class CwitterProfileActivity {
  const CwitterProfileActivity._({
    required this.kind,
    required this.createdAt,
    this.post,
    this.reply,
    this.parentPost,
    this.recweet,
  });

  factory CwitterProfileActivity.post(CwitterPost post) {
    return CwitterProfileActivity._(
      kind: CwitterProfileActivityKind.post,
      createdAt: post.createdAt,
      post: post,
    );
  }

  factory CwitterProfileActivity.reply({
    required CwitterReply reply,
    CwitterPost? parentPost,
  }) {
    return CwitterProfileActivity._(
      kind: CwitterProfileActivityKind.reply,
      createdAt: reply.createdAt,
      reply: reply,
      parentPost: parentPost,
    );
  }

  factory CwitterProfileActivity.recweet({
    required CwitterRecweet recweet,
    required CwitterPost post,
  }) {
    return CwitterProfileActivity._(
      kind: CwitterProfileActivityKind.recweet,
      createdAt: recweet.recweetedAt,
      post: post,
      recweet: recweet,
    );
  }

  final CwitterProfileActivityKind kind;
  final DateTime createdAt;
  final CwitterPost? post;
  final CwitterReply? reply;
  final CwitterPost? parentPost;
  final CwitterRecweet? recweet;
}
