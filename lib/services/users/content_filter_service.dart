import '../../models/bulletin/bulletin_model.dart';
import '../../models/comment/comment_model.dart';
import '../../models/community/cwitter_post.dart';
import '../../models/community/cwitter_profile_activity.dart';
import '../../models/community/cwitter_recweet.dart';
import '../../models/community/cwitter_reply.dart';
import 'user_block_service.dart';

/// ブロックユーザーのコンテンツをフィルタリングするサービス
class ContentFilterService {
  /// 投稿一覧からブロック済みユーザーの投稿を除外
  static Future<List<BulletinPost>> filterBlockedPosts(
    List<BulletinPost> posts,
  ) async {
    try {
      final hiddenUserIds = await UserBlockService.getHiddenUserIds();

      if (hiddenUserIds.isEmpty) {
        return posts;
      }

      return filterPostsWithCachedIds(posts, hiddenUserIds);
    } catch (e) {
      print('投稿フィルタリング時のエラー: $e');
      return posts;
    }
  }

  /// コメント一覧からブロック済みユーザーのコメントを除外
  static Future<List<BulletinComment>> filterBlockedComments(
    List<BulletinComment> comments,
  ) async {
    try {
      final hiddenUserIds = await UserBlockService.getHiddenUserIds();

      if (hiddenUserIds.isEmpty) {
        return comments;
      }

      return filterCommentsWithCachedIds(comments, hiddenUserIds);
    } catch (e) {
      print('コメントフィルタリング時のエラー: $e');
      return comments;
    }
  }

  /// 特定のユーザーがブロック済みかチェック
  static Future<bool> isUserBlocked(String userId) async {
    try {
      final hiddenUserIds = await UserBlockService.getHiddenUserIds();
      return hiddenUserIds.contains(userId);
    } catch (e) {
      print('ブロック状態チェック時のエラー: $e');
      return false;
    }
  }

  /// 投稿を1件ずつチェックしてブロックユーザーのものか判定
  static Future<bool> shouldHidePost(BulletinPost post) async {
    return await isUserBlocked(post.authorId);
  }

  /// コメントを1件ずつチェックしてブロックユーザーのものか判定
  static Future<bool> shouldHideComment(BulletinComment comment) async {
    return await isUserBlocked(comment.authorId);
  }

  /// ブロックユーザーIDのキャッシュを持つ軽量版フィルター
  static List<BulletinPost> filterPostsWithCachedIds(
    List<BulletinPost> posts,
    Set<String> hiddenUserIds,
  ) {
    if (hiddenUserIds.isEmpty) {
      return posts;
    }

    return posts.where((post) {
      return !hiddenUserIds.contains(post.authorId);
    }).toList();
  }

  /// ブロックユーザーIDのキャッシュを持つ軽量版フィルター（コメント用）
  static List<BulletinComment> filterCommentsWithCachedIds(
    List<BulletinComment> comments,
    Set<String> hiddenUserIds,
  ) {
    if (hiddenUserIds.isEmpty) {
      return comments;
    }

    return comments.where((comment) {
      return !hiddenUserIds.contains(comment.authorId);
    }).toList();
  }

  static List<CwitterPost> filterCwitterPosts(
    List<CwitterPost> posts,
    Set<String> hiddenUserIds,
  ) {
    if (hiddenUserIds.isEmpty) {
      return posts;
    }

    return posts
        .where((post) => !hiddenUserIds.contains(post.authorId))
        .toList();
  }

  static List<CwitterReply> filterCwitterReplies(
    List<CwitterReply> replies,
    Set<String> hiddenUserIds,
  ) {
    if (hiddenUserIds.isEmpty) {
      return replies;
    }

    return replies
        .where((reply) => !hiddenUserIds.contains(reply.authorId))
        .toList();
  }

  static List<CwitterRecweet> filterCwitterRecweets(
    List<CwitterRecweet> recweets,
    Set<String> hiddenUserIds,
  ) {
    if (hiddenUserIds.isEmpty) {
      return recweets;
    }

    return recweets.where((recweet) {
      return !hiddenUserIds.contains(recweet.userId) &&
          !hiddenUserIds.contains(recweet.originalAuthorId);
    }).toList();
  }

  static List<CwitterProfileActivity> filterCwitterActivities(
    List<CwitterProfileActivity> activities,
    Set<String> hiddenUserIds,
  ) {
    if (hiddenUserIds.isEmpty) {
      return activities;
    }

    return activities.where((activity) {
      switch (activity.kind) {
        case CwitterProfileActivityKind.post:
          return !hiddenUserIds.contains(activity.post!.authorId);
        case CwitterProfileActivityKind.reply:
          if (hiddenUserIds.contains(activity.reply!.authorId)) {
            return false;
          }
          final parentAuthorId = activity.parentPost?.authorId;
          return parentAuthorId == null ||
              !hiddenUserIds.contains(parentAuthorId);
        case CwitterProfileActivityKind.recweet:
          if (hiddenUserIds.contains(activity.recweet!.userId)) {
            return false;
          }
          return !hiddenUserIds.contains(activity.recweet!.originalAuthorId);
      }
    }).toList();
  }

  static List<CommentThread> filterCommentThreads(
    List<CommentThread> threads,
    Set<String> hiddenUserIds,
  ) {
    if (hiddenUserIds.isEmpty) {
      return threads;
    }

    return threads
        .where((thread) => !hiddenUserIds.contains(thread.comment.authorId))
        .map((thread) {
          final filteredReplies = thread.replies
              .where((reply) => !hiddenUserIds.contains(reply.authorId))
              .toList();
          return CommentThread(
            comment: thread.comment,
            replies: filteredReplies,
          );
        })
        .toList();
  }
}
