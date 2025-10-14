import 'package:cloud_firestore/cloud_firestore.dart';

// コメントモデル
class BulletinComment {
  final String id;
  final String postId;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? parentCommentId; // 返信の場合の親コメントID
  final bool isDeleted;
  final int likeCount;
  final Map<String, dynamic>? likedBy; // uid -> true/false

  BulletinComment({
    required this.id,
    required this.postId,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.updatedAt,
    this.parentCommentId,
    this.isDeleted = false,
    this.likeCount = 0,
    this.likedBy,
  });

  factory BulletinComment.fromJson(Map<String, dynamic> json) {
    return BulletinComment(
      id: json['id'] as String,
      postId: json['postId'] as String,
      content: json['content'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null 
          ? (json['updatedAt'] as Timestamp).toDate() 
          : null,
      parentCommentId: json['parentCommentId'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      likeCount: json['likeCount'] as int? ?? 0,
      likedBy: json['likedBy'] is Map
          ? Map<String, dynamic>.from(json['likedBy'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'parentCommentId': parentCommentId,
      'isDeleted': isDeleted,
      'likeCount': likeCount,
      'likedBy': likedBy,
    };
  }

  // 返信かどうかの判定
  bool get isReply => parentCommentId != null;

  // 編集済みかどうかの判定
  bool get isEdited => updatedAt != null;

  // 時間表示用フォーマット
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'たった今';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${createdAt.month}/${createdAt.day}';
    }
  }

  // コピー用メソッド
  BulletinComment copyWith({
    String? id,
    String? postId,
    String? content,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? parentCommentId,
    bool? isDeleted,
    int? likeCount,
    Map<String, dynamic>? likedBy,
  }) {
    return BulletinComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      isDeleted: isDeleted ?? this.isDeleted,
      likeCount: likeCount ?? this.likeCount,
      likedBy: likedBy ?? this.likedBy,
    );
  }
}

// コメント統計情報
class CommentStats {
  final int totalComments;
  final int directComments;
  final int repliesCount;

  CommentStats({
    required this.totalComments,
    required this.directComments,
    required this.repliesCount,
  });
}

// コメントツリー構造用
class CommentThread {
  final BulletinComment comment;
  final List<BulletinComment> replies;

  CommentThread({
    required this.comment,
    required this.replies,
  });

  int get totalReplies => replies.length;
}
