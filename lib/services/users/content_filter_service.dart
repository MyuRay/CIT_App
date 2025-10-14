import '../../models/bulletin/bulletin_model.dart';
import '../../models/comment/comment_model.dart';
import 'user_block_service.dart';

/// ブロックユーザーのコンテンツをフィルタリングするサービス
class ContentFilterService {
  /// 投稿一覧からブロック済みユーザーの投稿を除外
  static Future<List<BulletinPost>> filterBlockedPosts(
    List<BulletinPost> posts,
  ) async {
    try {
      // ブロックユーザーIDのセットを取得
      final blockedUserIds = await UserBlockService.getBlockedUserIds();

      if (blockedUserIds.isEmpty) {
        return posts;
      }

      // ブロックユーザーの投稿を除外
      return posts.where((post) {
        return !blockedUserIds.contains(post.authorId);
      }).toList();
    } catch (e) {
      print('投稿フィルタリング時のエラー: $e');
      // エラー時は元のリストをそのまま返す
      return posts;
    }
  }

  /// コメント一覧からブロック済みユーザーのコメントを除外
  static Future<List<BulletinComment>> filterBlockedComments(
    List<BulletinComment> comments,
  ) async {
    try {
      // ブロックユーザーIDのセットを取得
      final blockedUserIds = await UserBlockService.getBlockedUserIds();

      if (blockedUserIds.isEmpty) {
        return comments;
      }

      // ブロックユーザーのコメントを除外
      return comments.where((comment) {
        return !blockedUserIds.contains(comment.authorId);
      }).toList();
    } catch (e) {
      print('コメントフィルタリング時のエラー: $e');
      // エラー時は元のリストをそのまま返す
      return comments;
    }
  }

  /// 特定のユーザーがブロック済みかチェック
  static Future<bool> isUserBlocked(String userId) async {
    try {
      return await UserBlockService.isBlocked(blockedUserId: userId);
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
  /// 同一画面内で複数回フィルタリングする場合に使用
  static List<BulletinPost> filterPostsWithCachedIds(
    List<BulletinPost> posts,
    Set<String> blockedUserIds,
  ) {
    if (blockedUserIds.isEmpty) {
      return posts;
    }

    return posts.where((post) {
      return !blockedUserIds.contains(post.authorId);
    }).toList();
  }

  /// ブロックユーザーIDのキャッシュを持つ軽量版フィルター（コメント用）
  static List<BulletinComment> filterCommentsWithCachedIds(
    List<BulletinComment> comments,
    Set<String> blockedUserIds,
  ) {
    if (blockedUserIds.isEmpty) {
      return comments;
    }

    return comments.where((comment) {
      return !blockedUserIds.contains(comment.authorId);
    }).toList();
  }
}
