import 'package:cit_app/core/utils/logger.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notification/notification_model.dart';
import '../../models/notification/notification_preference_model.dart';

// ユーザーの通知一覧プロバイダー
final userNotificationsProvider = StreamProvider.family<
  List<AppNotification>,
  String
>((ref, userId) {
  SecureLogger.debug('🚀 userNotificationsProvider初期化 - ユーザーID: $userId');

  try {
    SecureLogger.debug('📢 Firestoreから通知監視開始: $userId');

    final stream =
        FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots();

    SecureLogger.debug('🔗 Firestoreストリームを作成しました');

    return stream
        .map((snapshot) {
          SecureLogger.debug('📢 通知データ受信: ${snapshot.docs.length}件 (ユーザー: $userId)');
          SecureLogger.debug(
            '🔍 スナップショット情報: metadata=${snapshot.metadata}, fromCache=${snapshot.metadata.isFromCache}',
          );

          if (snapshot.docs.isEmpty) {
            SecureLogger.debug('ℹ️ このユーザーの通知はありません: $userId');
            SecureLogger.debug(
              '🔍 Firestoreクエリ確認: collection=notifications, where userId == $userId',
            );
            return <AppNotification>[];
          }

          final notifications = <AppNotification>[];

          for (int i = 0; i < snapshot.docs.length; i++) {
            final doc = snapshot.docs[i];
            try {
              SecureLogger.debug(
                '🔍 通知ドキュメント ${i + 1}/${snapshot.docs.length} を処理中: ${doc.id}',
              );
              final data = doc.data();
              data['id'] = doc.id;

              SecureLogger.debug('📋 通知データ内容: ${data.toString()}');
              final notification = AppNotification.fromJson(data);
              notifications.add(notification);
              SecureLogger.debug('✅ 通知データ変換成功: ${notification.title}');
            } catch (e, stackTrace) {
              SecureLogger.debug('❌ 通知データ変換エラー (docId: ${doc.id}): $e');
              SecureLogger.debug('❌ エラースタック: $stackTrace');
            }
          }

          SecureLogger.debug('📢 通知データ処理完了: ${notifications.length}件');
          if (notifications.isNotEmpty) {
            SecureLogger.debug('📝 最新通知: ${notifications.first.title}');
          }

          return notifications;
        })
        .handleError((error, stackTrace) {
          SecureLogger.debug('❌ 通知ストリームエラー (ユーザー: $userId): $error');
          SecureLogger.debug('❌ エラースタック: $stackTrace');
          return <AppNotification>[];
        });
  } catch (e, stackTrace) {
    SecureLogger.debug('❌ 通知プロバイダー初期化エラー (ユーザー: $userId): $e');
    SecureLogger.debug('❌ 初期化エラースタック: $stackTrace');
    return Stream.value(<AppNotification>[]);
  }
});

// 未読通知数プロバイダー
final unreadNotificationCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  SecureLogger.debug('📊 unreadNotificationCountProvider初期化 - ユーザーID: $userId');

  try {
    SecureLogger.debug('📊 未読通知数監視開始: $userId');

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          try {
            SecureLogger.debug('📊 未読通知数計算中... (総通知数: ${snapshot.docs.length})');
            // Dartコード側で未読をフィルタ
            final unreadCount =
                snapshot.docs.where((doc) {
                  final data = doc.data();
                  final isRead = data['isRead'] ?? false;
                  return !isRead; // nullまたはfalseの場合は未読
                }).length;

            SecureLogger.debug('📊 未読通知数計算結果: $unreadCount (ユーザー: $userId)');
            return unreadCount;
          } catch (e, stackTrace) {
            SecureLogger.debug('❌ 未読通知数計算エラー (ユーザー: $userId): $e');
            SecureLogger.debug('❌ エラースタック: $stackTrace');
            return 0;
          }
        })
        .handleError((error, stackTrace) {
          SecureLogger.debug('❌ 未読通知数ストリームエラー (ユーザー: $userId): $error');
          SecureLogger.debug('❌ エラースタック: $stackTrace');
          return 0;
        });
  } catch (e, stackTrace) {
    SecureLogger.debug('❌ 未読通知数プロバイダー初期化エラー (ユーザー: $userId): $e');
    SecureLogger.debug('❌ 初期化エラースタック: $stackTrace');
    return Stream.value(0);
  }
});

// 通知サービス
class NotificationService {
  static Future<void> sendNotification(
    AppNotification notification, {
    NotificationPreferenceKey? preferenceKey,
  }) async {
    try {
      SecureLogger.debug('📢 sendNotification開始: ${notification.type.displayName}');
      SecureLogger.debug('🔍 通知送信対象ユーザーID: ${notification.userId}');

      final docRef =
          FirebaseFirestore.instance.collection('notifications').doc();
      SecureLogger.debug('🆔 生成された通知ID: ${docRef.id}');

      final notificationWithId = notification.copyWith(id: docRef.id);
      final jsonData = notificationWithId.toJson();

      SecureLogger.debug('📝 Firestoreに保存する通知データ:');
      jsonData.forEach((key, value) {
        SecureLogger.debug('  $key: $value');
      });

      SecureLogger.debug('💾 Firestoreに通知を保存中...');
      await docRef.set(jsonData);

      SecureLogger.debug('🔍 保存確認のため通知ドキュメントを読み込み中...');
      final savedDoc = await docRef.get();
      if (savedDoc.exists) {
        SecureLogger.debug('✅ 通知がFirestoreに正常に保存されました');
        final savedData = savedDoc.data();
        SecureLogger.debug('📋 保存された通知データ確認:');
        savedData?.forEach((key, value) {
          SecureLogger.debug('  $key: $value');
        });
      } else {
        SecureLogger.debug('❌ 通知の保存確認に失敗しました');
      }

      SecureLogger.debug('✅ 通知送信完了: ${notification.title}');
    } catch (e, stackTrace) {
      SecureLogger.debug('❌ 通知送信エラー: $e');
      SecureLogger.debug('❌ スタックトレース: $stackTrace');
      rethrow;
    }
  }

  static Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      SecureLogger.debug('✅ 通知既読化完了: $notificationId');
    } catch (e) {
      SecureLogger.debug('❌ 通知既読化エラー: $e');
      rethrow;
    }
  }

  static Future<void> markAllAsRead(String userId) async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .where('isRead', isEqualTo: false)
              .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      SecureLogger.debug('✅ 全通知既読化完了: ${querySnapshot.docs.length}件');
    } catch (e) {
      SecureLogger.debug('❌ 全通知既読化エラー: $e');
      rethrow;
    }
  }

  static Future<void> deleteNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();

      SecureLogger.debug('✅ 通知削除完了: $notificationId');
    } catch (e) {
      SecureLogger.debug('❌ 通知削除エラー: $e');
      rethrow;
    }
  }

  // テスト用のダミー通知作成メソッド
  static Future<void> createTestNotification(String userId) async {
    try {
      SecureLogger.debug('🧪 テスト通知を作成中... (ユーザー: $userId)');

      final notification = AppNotification(
        id: '', // Firestoreで自動生成
        userId: userId,
        type: NotificationType.system,
        title: 'テスト通知',
        message: 'これはテスト用の通知です。通知システムが正常に動作しています。',
        createdAt: DateTime.now(),
      );

      await sendNotification(notification);
      SecureLogger.debug('✅ テスト通知作成完了');
    } catch (e) {
      SecureLogger.debug('❌ テスト通知作成エラー: $e');
      rethrow;
    }
  }

  // 特定ユーザーの全通知を削除するメソッド
  static Future<void> deleteAllNotifications(String userId) async {
    try {
      SecureLogger.debug('🗑️ 全通知削除開始 - ユーザー: $userId');

      // ユーザーの全通知を取得
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .get();

      SecureLogger.debug('📊 削除対象通知数: ${querySnapshot.docs.length}件');

      if (querySnapshot.docs.isEmpty) {
        SecureLogger.debug('ℹ️ 削除する通知がありません');
        return;
      }

      // バッチで一括削除
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
        SecureLogger.debug('🔄 削除キューに追加: ${doc.id}');
      }

      SecureLogger.debug('📦 バッチ削除実行中...');
      await batch.commit();

      SecureLogger.debug('✅ 全通知削除完了: ${querySnapshot.docs.length}件を削除しました');
    } catch (e, stackTrace) {
      SecureLogger.debug('❌ 全通知削除エラー: $e');
      SecureLogger.debug('❌ スタックトレース: $stackTrace');
      rethrow;
    }
  }

  // コメント通知を送信
  static Future<void> sendCommentNotification({
    required String postAuthorId,
    required String postTitle,
    required String commentAuthorName,
    required String postId,
    required String commentId,
    String? fromUserId,
  }) async {
    SecureLogger.debug('🔔 sendCommentNotification開始');
    SecureLogger.debug('  - postAuthorId: $postAuthorId');
    SecureLogger.debug('  - postTitle: $postTitle');
    SecureLogger.debug('  - commentAuthorName: $commentAuthorName');
    SecureLogger.debug('  - postId: $postId');
    SecureLogger.debug('  - commentId: $commentId');
    SecureLogger.debug('  - fromUserId: $fromUserId');

    // 自分自身への通知は送らない
    if (fromUserId == postAuthorId) {
      SecureLogger.debug('🚫 自分自身への通知はスキップ: $postAuthorId');
      return;
    }

    SecureLogger.debug('🏗️ 通知オブジェクトを作成中...');
    final notification = NotificationFactory.createCommentNotification(
      postAuthorId: postAuthorId,
      postTitle: postTitle,
      commentAuthorName: commentAuthorName,
      postId: postId,
      commentId: commentId,
      fromUserId: fromUserId,
    );

    SecureLogger.debug('📝 作成された通知内容:');
    SecureLogger.debug('  - userId: ${notification.userId}');
    SecureLogger.debug('  - type: ${notification.type.displayName}');
    SecureLogger.debug('  - title: ${notification.title}');
    SecureLogger.debug('  - message: ${notification.message}');

    SecureLogger.debug('📤 通知送信処理開始...');
    await sendNotification(
      notification,
      preferenceKey: NotificationPreferenceKey.bulletinComment,
    );
    SecureLogger.debug('✅ sendCommentNotification完了');
  }

  // 返信通知を送信
  static Future<void> sendReplyNotification({
    required String commentAuthorId,
    required String replyAuthorName,
    required String postTitle,
    required String postId,
    required String commentId,
    required String replyId,
    String? fromUserId,
  }) async {
    SecureLogger.debug('🔔 sendReplyNotification開始');
    SecureLogger.debug('  - commentAuthorId: $commentAuthorId');
    SecureLogger.debug('  - replyAuthorName: $replyAuthorName');
    SecureLogger.debug('  - postTitle: $postTitle');
    SecureLogger.debug('  - postId: $postId');
    SecureLogger.debug('  - commentId: $commentId');
    SecureLogger.debug('  - replyId: $replyId');
    SecureLogger.debug('  - fromUserId: $fromUserId');

    // 自分自身への通知は送らない
    if (fromUserId == commentAuthorId) {
      SecureLogger.debug('🚫 自分自身への返信通知はスキップ: $commentAuthorId');
      return;
    }

    SecureLogger.debug('🏗️ 返信通知オブジェクトを作成中...');
    final notification = NotificationFactory.createReplyNotification(
      commentAuthorId: commentAuthorId,
      replyAuthorName: replyAuthorName,
      postTitle: postTitle,
      postId: postId,
      commentId: commentId,
      replyId: replyId,
      fromUserId: fromUserId,
    );

    SecureLogger.debug('📝 作成された返信通知内容:');
    SecureLogger.debug('  - userId: ${notification.userId}');
    SecureLogger.debug('  - type: ${notification.type.displayName}');
    SecureLogger.debug('  - title: ${notification.title}');
    SecureLogger.debug('  - message: ${notification.message}');

    SecureLogger.debug('📤 返信通知送信処理開始...');
    await sendNotification(
      notification,
      preferenceKey: NotificationPreferenceKey.bulletinReply,
    );
    SecureLogger.debug('✅ sendReplyNotification完了');
  }

  // 投稿承認通知を送信
  static Future<void> sendPostApprovedNotification({
    required String postAuthorId,
    required String postTitle,
    required String postId,
  }) async {
    SecureLogger.debug('🔔 sendPostApprovedNotification開始');
    SecureLogger.debug('  - postAuthorId: $postAuthorId');
    SecureLogger.debug('  - postTitle: $postTitle');
    SecureLogger.debug('  - postId: $postId');

    final notification = NotificationFactory.createPostApprovedNotification(
      postAuthorId: postAuthorId,
      postTitle: postTitle,
      postId: postId,
    );

    SecureLogger.debug('📤 投稿承認通知送信処理開始...');
    await sendNotification(
      notification,
      preferenceKey: NotificationPreferenceKey.bulletinModeration,
    );
    SecureLogger.debug('✅ sendPostApprovedNotification完了');
  }

  // 投稿却下通知を送信
  static Future<void> sendPostRejectedNotification({
    required String postAuthorId,
    required String postTitle,
    required String postId,
    String? reason,
  }) async {
    SecureLogger.debug('🔔 sendPostRejectedNotification開始');
    SecureLogger.debug('  - postAuthorId: $postAuthorId');
    SecureLogger.debug('  - postTitle: $postTitle');
    SecureLogger.debug('  - postId: $postId');
    SecureLogger.debug('  - reason: $reason');

    final notification = NotificationFactory.createPostRejectedNotification(
      postAuthorId: postAuthorId,
      postTitle: postTitle,
      postId: postId,
      reason: reason,
    );

    SecureLogger.debug('📤 投稿却下通知送信処理開始...');
    await sendNotification(
      notification,
      preferenceKey: NotificationPreferenceKey.bulletinModeration,
    );
    SecureLogger.debug('✅ sendPostRejectedNotification完了');
  }

  // ピン留め承認通知を送信
  static Future<void> sendPinApprovedNotification({
    required String postAuthorId,
    required String postTitle,
    required String postId,
  }) async {
    SecureLogger.debug('🔔 sendPinApprovedNotification開始');
    SecureLogger.debug('  - postAuthorId: $postAuthorId');
    SecureLogger.debug('  - postTitle: $postTitle');
    SecureLogger.debug('  - postId: $postId');

    final notification = NotificationFactory.createPinApprovedNotification(
      postAuthorId: postAuthorId,
      postTitle: postTitle,
      postId: postId,
    );

    SecureLogger.debug('📤 ピン留め承認通知送信処理開始...');
    await sendNotification(
      notification,
      preferenceKey: NotificationPreferenceKey.bulletinModeration,
    );
    SecureLogger.debug('✅ sendPinApprovedNotification完了');
  }

  static Future<void> sendCwitterReplyNotification({
    required String postAuthorId,
    required String postId,
    required String replyId,
    required String fromUserName,
    required String fromCwitterId,
    String? fromUserId,
    String? postBodyPreview,
  }) async {
    if (fromUserId != null && fromUserId == postAuthorId) return;

    final notification = NotificationFactory.createCwitterReplyNotification(
      postAuthorId: postAuthorId,
      postId: postId,
      replyId: replyId,
      fromUserName: fromUserName,
      fromCwitterId: fromCwitterId,
      fromUserId: fromUserId,
      postBodyPreview: postBodyPreview,
    );
    await sendNotification(
      notification,
      preferenceKey: NotificationPreferenceKey.cwitterReply,
    );
  }

  static Future<void> sendCwitterLikeNotification({
    required String postAuthorId,
    required String postId,
    required String fromUserName,
    required String fromCwitterId,
    String? fromUserId,
    String? postBodyPreview,
  }) async {
    if (fromUserId != null && fromUserId == postAuthorId) return;

    final notification = NotificationFactory.createCwitterLikeNotification(
      postAuthorId: postAuthorId,
      postId: postId,
      fromUserName: fromUserName,
      fromCwitterId: fromCwitterId,
      fromUserId: fromUserId,
      postBodyPreview: postBodyPreview,
    );
    await sendNotification(
      notification,
      preferenceKey: NotificationPreferenceKey.cwitterLike,
    );
  }

  static Future<void> sendCwitterFollowNotification({
    required String followeeId,
    required String fromUserName,
    required String fromCwitterId,
    String? fromUserId,
  }) async {
    if (fromUserId != null && fromUserId == followeeId) return;

    final notification = NotificationFactory.createCwitterFollowNotification(
      followeeId: followeeId,
      fromUserName: fromUserName,
      fromCwitterId: fromCwitterId,
      fromUserId: fromUserId,
    );
    await sendNotification(
      notification,
      preferenceKey: NotificationPreferenceKey.cwitterFollow,
    );
  }

  static Future<void> sendChibaChannelThreadReplyNotification({
    required String threadAuthorId,
    required String threadId,
    required String threadTitle,
    required String commentId,
    required String fromUserId,
    String? bodyPreview,
  }) async {
    if (fromUserId == threadAuthorId) return;

    final notification =
        NotificationFactory.createChibaChannelThreadReplyNotification(
          threadAuthorId: threadAuthorId,
          threadId: threadId,
          threadTitle: threadTitle,
          commentId: commentId,
          bodyPreview: bodyPreview,
        );
    await sendNotification(
      notification,
      preferenceKey: NotificationPreferenceKey.chibaChannelThreadReply,
    );
  }

  static Future<void> sendChibaChannelCommentReplyNotification({
    required String commentAuthorId,
    required String threadId,
    required String threadTitle,
    required String commentId,
    required int replyToCommentNumber,
    required String fromUserId,
    String? bodyPreview,
  }) async {
    if (fromUserId == commentAuthorId) return;

    final notification =
        NotificationFactory.createChibaChannelCommentReplyNotification(
          commentAuthorId: commentAuthorId,
          threadId: threadId,
          threadTitle: threadTitle,
          commentId: commentId,
          replyToCommentNumber: replyToCommentNumber,
          bodyPreview: bodyPreview,
        );
    await sendNotification(
      notification,
      preferenceKey: NotificationPreferenceKey.chibaChannelCommentReply,
    );
  }

  // ピン留め却下通知を送信
  static Future<void> sendPinRejectedNotification({
    required String postAuthorId,
    required String postTitle,
    required String postId,
    String? reason,
  }) async {
    SecureLogger.debug('🔔 sendPinRejectedNotification開始');
    SecureLogger.debug('  - postAuthorId: $postAuthorId');
    SecureLogger.debug('  - postTitle: $postTitle');
    SecureLogger.debug('  - postId: $postId');
    SecureLogger.debug('  - reason: $reason');

    final notification = NotificationFactory.createPinRejectedNotification(
      postAuthorId: postAuthorId,
      postTitle: postTitle,
      postId: postId,
      reason: reason,
    );

    SecureLogger.debug('📤 ピン留め却下通知送信処理開始...');
    await sendNotification(
      notification,
      preferenceKey: NotificationPreferenceKey.bulletinModeration,
    );
    SecureLogger.debug('✅ sendPinRejectedNotification完了');
  }
}

// 通知管理StateNotifier
class NotificationNotifier extends StateNotifier<AsyncValue<void>> {
  NotificationNotifier() : super(const AsyncValue.data(null));

  Future<void> markAsRead(String notificationId) async {
    state = const AsyncValue.loading();
    try {
      await NotificationService.markAsRead(notificationId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> markAllAsRead(String userId) async {
    state = const AsyncValue.loading();
    try {
      await NotificationService.markAllAsRead(userId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    state = const AsyncValue.loading();
    try {
      await NotificationService.deleteNotification(notificationId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// NotificationNotifierプロバイダー
final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<void>>((ref) {
      return NotificationNotifier();
    });

// テスト用通知作成プロバイダー
final createTestNotificationProvider = FutureProvider.family<void, String>((
  ref,
  userId,
) async {
  await NotificationService.createTestNotification(userId);
});

// 全通知削除プロバイダー
final deleteAllNotificationsProvider = FutureProvider.family<void, String>((
  ref,
  userId,
) async {
  await NotificationService.deleteAllNotifications(userId);
});
