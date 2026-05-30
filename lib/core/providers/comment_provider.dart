import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/comment/comment_model.dart';
import '../../models/bulletin/bulletin_model.dart';
import 'notification_provider.dart';
import 'auth_provider.dart';
import 'user_block_provider.dart';
import '../../services/users/content_filter_service.dart';

/// 投稿ごとのコメント表示順（デフォルト: 新しい順）
final commentSortOrderProvider = StateProvider.family<CommentSortOrder, String>(
  (ref, postId) => CommentSortOrder.newest,
);

int _compareComments(BulletinComment a, BulletinComment b, CommentSortOrder order) {
  switch (order) {
    case CommentSortOrder.popular:
      final likeCmp = b.likeCount.compareTo(a.likeCount);
      if (likeCmp != 0) return likeCmp;
      return b.createdAt.compareTo(a.createdAt);
    case CommentSortOrder.newest:
      return b.createdAt.compareTo(a.createdAt);
    case CommentSortOrder.oldest:
      return a.createdAt.compareTo(b.createdAt);
  }
}

/// スレッド一覧を表示順で並び替え（親コメント・返信それぞれに適用）
List<CommentThread> sortCommentThreads(
  List<CommentThread> threads,
  CommentSortOrder order,
) {
  return threads
      .map((thread) {
        final replies = List<BulletinComment>.from(thread.replies)
          ..sort((a, b) => _compareComments(a, b, order));
        return CommentThread(comment: thread.comment, replies: replies);
      })
      .toList()
    ..sort((a, b) => _compareComments(a.comment, b.comment, order));
}

/// 表示順適用済みのコメント一覧（ブロックユーザーを除外）
final sortedPostCommentsProvider =
    Provider.family<AsyncValue<List<CommentThread>>, String>((ref, postId) {
  final sortOrder = ref.watch(commentSortOrderProvider(postId));
  final commentsAsync = ref.watch(postCommentsProvider(postId));
  final hiddenAsync = ref.watch(hiddenUserIdsProvider);

  return hiddenAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
    data: (hiddenUserIds) => commentsAsync.when(
      data: (threads) {
        final filtered = ContentFilterService.filterCommentThreads(
          threads,
          hiddenUserIds,
        );
        return AsyncValue.data(sortCommentThreads(filtered, sortOrder));
      },
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    ),
  );
});

// コメント所有権チェックプロバイダー
final commentOwnershipProvider = Provider.family<bool, String>((ref, authorId) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user?.uid == authorId,
    loading: () => false,
    error: (_, __) => false,
  );
});

// 投稿のコメント一覧プロバイダー（リアルタイム対応）
final postCommentsProvider = StreamProvider.family<List<CommentThread>, String>((ref, postId) {
  print('📝 リアルタイムコメント監視開始: $postId');
  
  return FirebaseFirestore.instance
      .collection('bulletin_comments')
      .where('postId', isEqualTo: postId)
      .snapshots()
      .map((snapshot) {
    try {
      print('📝 リアルタイム更新受信: ${snapshot.docs.length} 件のコメント');

      final allComments = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return BulletinComment.fromJson(data);
      }).where((comment) => !comment.isDeleted).toList();
      
      // Dartコード側でソート
      allComments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      print('📝 コメントソート完了: ${allComments.length} 件');

      // 親コメントとその返信をグループ化
      final Map<String, List<BulletinComment>> commentGroups = {};
      final List<BulletinComment> parentComments = [];

      // まず親コメントを分離
      for (final comment in allComments) {
        if (comment.parentCommentId == null) {
          parentComments.add(comment);
          commentGroups[comment.id] = [];
        }
      }

      // 返信を各親コメントにグループ化
      for (final comment in allComments) {
        if (comment.parentCommentId != null) {
          if (commentGroups.containsKey(comment.parentCommentId!)) {
            commentGroups[comment.parentCommentId!]!.add(comment);
          }
        }
      }

      // CommentThreadとして構築
      final commentThreads = parentComments.map((parentComment) {
        final replies = commentGroups[parentComment.id] ?? [];
        replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return CommentThread(
          comment: parentComment,
          replies: replies,
        );
      }).toList();

      print('📝 リアルタイムコメントスレッド構築完了: ${commentThreads.length} スレッド');
      return commentThreads;
    } catch (e, stackTrace) {
      print('❌ リアルタイムコメント取得エラー: $e');
      print('❌ スタックトレース: $stackTrace');
      return <CommentThread>[];
    }
  }).handleError((error) {
    print('❌ リアルタイムストリームエラー: $error');
    return <CommentThread>[];
  });
});

// コメント統計プロバイダー
final commentStatsProvider = FutureProvider.family<CommentStats, String>((ref, postId) async {
  try {
    print('📊 コメント統計取得開始: $postId');
    
    final querySnapshot = await FirebaseFirestore.instance
        .collection('bulletin_comments')
        .where('postId', isEqualTo: postId)
        .get();
    
    print('📊 統計用クエリ実行完了: ${querySnapshot.docs.length} 件');

    final comments = querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return BulletinComment.fromJson(data);
    }).where((comment) => !comment.isDeleted).toList(); // Dartコード側で削除フラグをチェック

    final directComments = comments.where((c) => c.parentCommentId == null).length;
    final repliesCount = comments.where((c) => c.parentCommentId != null).length;

    final stats = CommentStats(
      totalComments: comments.length,
      directComments: directComments,
      repliesCount: repliesCount,
    );
    
    print('📊 統計計算完了: 合計${stats.totalComments}, 直接${stats.directComments}, 返信${stats.repliesCount}');
    return stats;
  } catch (e, stackTrace) {
    print('❌ コメント統計取得エラー: $e');
    print('❌ スタックトレース: $stackTrace');
    return CommentStats(totalComments: 0, directComments: 0, repliesCount: 0);
  }
});

// コメント管理サービス
class CommentService {
  static Future<void> addComment({
    required String postId,
    required String content,
    required String authorName,
    String? parentCommentId,
  }) async {
    try {
      // 現在のユーザーを取得
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('ユーザーが認証されていません');
      }

      final commentId = FirebaseFirestore.instance
          .collection('bulletin_comments')
          .doc()
          .id;

      final comment = BulletinComment(
        id: commentId,
        postId: postId,
        content: content,
        authorId: user.uid, // 実際のFirebase Auth ユーザーIDを使用
        authorName: authorName,
        createdAt: DateTime.now(),
        parentCommentId: parentCommentId,
      );

      final commentData = comment.toJson();
      print('📝 投稿するコメントデータ:');
      print('  - postId: ${commentData['postId']}');
      print('  - authorId: ${commentData['authorId']}');
      print('  - authorName: ${commentData['authorName']}');
      print('  - content: ${commentData['content']}');
      print('  - createdAt: ${commentData['createdAt']}');
      print('  - parentCommentId: ${commentData['parentCommentId']}');

      await FirebaseFirestore.instance
          .collection('bulletin_comments')
          .doc(commentId)
          .set(commentData);

      print('✅ Firestore書き込み完了: $commentId');
      
      // 書き込み確認のため短時間待機
      await Future.delayed(const Duration(milliseconds: 200));
      
      // 書き込みが実際に完了したかドキュメントを確認
      final verifyDoc = await FirebaseFirestore.instance
          .collection('bulletin_comments')
          .doc(commentId)
          .get();
      
      if (verifyDoc.exists) {
        print('✅ コメント投稿確認完了: $commentId');
      } else {
        print('⚠️  コメント確認できず: $commentId');
        throw Exception('コメントの書き込み確認に失敗しました');
      }

      // 通知を送信
      print('🔔 通知送信処理開始...');
      await _sendNotificationForComment(postId, commentId, authorName, parentCommentId, user.uid);
      print('🔔 通知送信処理完了');

    } catch (e) {
      print('❌ コメント投稿エラー詳細: $e');
      print('❌ エラータイプ: ${e.runtimeType}');
      
      // Firebase Auth の状態確認
      final currentUser = FirebaseAuth.instance.currentUser;
      print('🔐 認証状態: ${currentUser != null ? "認証済み" : "未認証"}');
      if (currentUser != null) {
        print('🔐 ユーザーID: ${currentUser.uid}');
        print('🔐 メールアドレス: ${currentUser.email}');
        print('🔐 メール確認: ${currentUser.emailVerified}');
        
        // IDトークンの取得を試行
        try {
          final idToken = await currentUser.getIdToken();
          print('🔐 IDトークン取得: 成功');
        } catch (tokenError) {
          print('❌ IDトークン取得失敗: $tokenError');
        }
      }
      
      // permission-deniedエラーの場合の詳細情報
      if (e.toString().contains('permission-denied')) {
        print('🚨 【権限エラー】以下を確認してください:');
        print('  1. Firestoreルールで bulletin_comments コレクションが設定されているか');
        print('  2. ユーザーのメールアドレスが @s.chibakoudai.jp ドメインか');
        print('  3. Firebase Authの認証状態が有効か');
        print('');
        print('📋 暫定解決策: 以下のFirestoreルールを適用してください:');
        print('  Firebase Console → Firestore → Rules に以下を追加:');
        print('  match /bulletin_comments/{commentId} {');
        print('    allow read, write: if request.auth != null;');
        print('  }');
      }
      
      rethrow;
    }
  }

  // コメント投稿時の通知送信
  static Future<void> _sendNotificationForComment(
    String postId,
    String commentId,
    String authorName,
    String? parentCommentId,
    String fromUserId,
  ) async {
    print('🔔 通知送信メソッド開始');
    print('  - postId: $postId');
    print('  - commentId: $commentId');
    print('  - authorName: $authorName');
    print('  - parentCommentId: $parentCommentId');
    print('  - fromUserId: $fromUserId');
    
    try {
      // 投稿情報を取得
      print('📄 投稿情報を取得中: $postId');
      final postDoc = await FirebaseFirestore.instance
          .collection('bulletin_posts')
          .doc(postId)
          .get();

      if (!postDoc.exists) {
        print('⚠️ 投稿が見つかりません: $postId');
        return;
      }

      print('✅ 投稿情報取得成功: ${postDoc.id}');
      final postData = postDoc.data()!;
      postData['id'] = postDoc.id;
      final post = BulletinPost.fromJson(postData);
      print('📝 投稿タイトル: ${post.title}');
      print('👤 投稿作者ID: ${post.authorId}');

      if (parentCommentId != null) {
        print('💬 返信通知の送信処理開始');
        print('📍 親コメントID: $parentCommentId');
        
        // 返信の場合：元のコメント作者に通知
        final parentCommentDoc = await FirebaseFirestore.instance
            .collection('bulletin_comments')
            .doc(parentCommentId)
            .get();

        if (!parentCommentDoc.exists) {
          print('⚠️ 親コメントが見つかりません: $parentCommentId');
          return;
        }

        final parentCommentData = parentCommentDoc.data()!;
        final parentAuthorId = parentCommentData['authorId'] as String;
        print('👤 親コメント作者ID: $parentAuthorId');
        
        // 自分自身への通知かチェック
        if (fromUserId == parentAuthorId) {
          print('🚫 自分自身への返信通知はスキップします');
          return;
        }

        print('🔔 返信通知送信中...');
        await NotificationService.sendReplyNotification(
          commentAuthorId: parentAuthorId,
          replyAuthorName: authorName,
          postTitle: post.title,
          postId: postId,
          commentId: parentCommentId,
          replyId: commentId,
          fromUserId: fromUserId,
        );
        print('✅ 返信通知送信完了');
      } else {
        print('💬 新規コメント通知の送信処理開始');
        
        // 自分自身への通知かチェック
        if (fromUserId == post.authorId) {
          print('🚫 自分自身への新規コメント通知はスキップします');
          return;
        }

        // 新しいコメントの場合：投稿作者に通知
        print('🔔 新規コメント通知送信中...');
        await NotificationService.sendCommentNotification(
          postAuthorId: post.authorId,
          postTitle: post.title,
          commentAuthorName: authorName,
          postId: postId,
          commentId: commentId,
          fromUserId: fromUserId,
        );
        print('✅ 新規コメント通知送信完了');
      }
    } catch (e, stackTrace) {
      print('❌ コメント通知送信エラー: $e');
      print('❌ スタックトレース: $stackTrace');
      // 通知送信エラーでもコメント投稿は成功させる
    }
  }

  static Future<void> updateComment({
    required String commentId,
    required String newContent,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('bulletin_comments')
          .doc(commentId)
          .update({
        'content': newContent,
        'updatedAt': Timestamp.now(),
      });

      print('コメント更新完了: $commentId');
    } catch (e) {
      print('コメント更新エラー: $e');
      rethrow;
    }
  }

  static Future<void> deleteComment(String commentId) async {
    try {
      // 物理削除ではなく論理削除
      await FirebaseFirestore.instance
          .collection('bulletin_comments')
          .doc(commentId)
          .update({
        'isDeleted': true,
        'content': '[削除されたコメント]',
        'updatedAt': Timestamp.now(),
      });

      print('コメント削除完了: $commentId');
    } catch (e) {
      print('コメント削除エラー: $e');
      rethrow;
    }
  }

  static Future<void> likeComment(String commentId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        throw Exception('ログインが必要です');
      }

      final docRef = FirebaseFirestore.instance
          .collection('bulletin_comments')
          .doc(commentId);

      await FirebaseFirestore.instance.runTransaction((txn) async {
        final snap = await txn.get(docRef);
        if (!snap.exists) {
          throw Exception('コメントが見つかりません');
        }
        final data = snap.data() as Map<String, dynamic>;
        final currentCount = (data['likeCount'] as int?) ?? 0;
        final currentLikedBy = Map<String, dynamic>.from(data['likedBy'] as Map<String, dynamic>? ?? {});

        // 既にいいね済みなら何もしない（多重いいね防止）
        if (currentLikedBy[uid] == true) {
          return;
        }

        currentLikedBy[uid] = true;
        txn.update(docRef, {
          'likedBy': currentLikedBy,
          'likeCount': currentCount + 1,
        });
      });

      print('コメントいいね完了: $commentId');
    } catch (e) {
      print('コメントいいねエラー: $e');
      rethrow;
    }
  }

  static Future<void> unlikeComment(String commentId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        throw Exception('ログインが必要です');
      }

      final docRef = FirebaseFirestore.instance
          .collection('bulletin_comments')
          .doc(commentId);

      await FirebaseFirestore.instance.runTransaction((txn) async {
        final snap = await txn.get(docRef);
        if (!snap.exists) {
          throw Exception('コメントが見つかりません');
        }
        final data = snap.data() as Map<String, dynamic>;
        final currentCount = (data['likeCount'] as int?) ?? 0;
        final currentLikedBy = Map<String, dynamic>.from(data['likedBy'] as Map<String, dynamic>? ?? {});

        // いいねしていない場合は何もしない
        if (currentLikedBy[uid] == true) {
          currentLikedBy[uid] = false; // 削除ではなく false にしてルール判定を簡単に
          txn.update(docRef, {
            'likedBy': currentLikedBy,
            'likeCount': currentCount > 0 ? currentCount - 1 : 0,
          });
        }
      });

      print('コメントいいね取り消し完了: $commentId');
    } catch (e) {
      print('コメントいいね取り消しエラー: $e');
      rethrow;
    }
  }

}

// コメント投稿用StateNotifier
class CommentNotifier extends StateNotifier<AsyncValue<void>> {
  CommentNotifier() : super(const AsyncValue.data(null));

  Future<void> postComment({
    required String postId,
    required String content,
    required String authorName,
    String? parentCommentId,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      print('🔄 CommentNotifier: 投稿処理開始');
      await CommentService.addComment(
        postId: postId,
        content: content,
        authorName: authorName,
        parentCommentId: parentCommentId,
      );
      print('✅ CommentNotifier: 投稿処理完了');
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      print('❌ CommentNotifier: 投稿エラー: $e');
      state = AsyncValue.error(e, stackTrace);
      rethrow; // エラーを上位に再throw
    }
  }

  Future<void> editComment({
    required String commentId,
    required String newContent,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      await CommentService.updateComment(
        commentId: commentId,
        newContent: newContent,
      );
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteComment(String commentId) async {
    state = const AsyncValue.loading();
    
    try {
      await CommentService.deleteComment(commentId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// CommentNotifierプロバイダー
final commentNotifierProvider = StateNotifierProvider<CommentNotifier, AsyncValue<void>>((ref) {
  return CommentNotifier();
});
