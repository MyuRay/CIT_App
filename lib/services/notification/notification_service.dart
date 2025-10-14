import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/notification/notification_model.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firebase Messaging初期化
  static Future<void> initialize() async {
    // 通知権限を要求
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('ユーザー通知権限: ${settings.authorizationStatus}');

    // FCMトークンを取得してFirestoreに保存
    await _saveFCMToken();

    // トークンリフレッシュ時の処理
    _messaging.onTokenRefresh.listen((fcmToken) async {
      print('FCMトークンがリフレッシュされました: $fcmToken');
      await _saveFCMToken();
    });

    // フォアグラウンド通知受信時の処理
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('フォアグラウンド通知を受信: ${message.notification?.title}');
      _handleForegroundMessage(message);
    });

    // バックグラウンド通知タップ時の処理
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('バックグラウンド通知がタップされました: ${message.data}');
      _handleBackgroundMessageTap(message);
    });

    // アプリ終了時の通知タップ時の処理（アプリ起動時にチェック）
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('アプリ終了時の通知がタップされました: ${initialMessage.data}');
      _handleBackgroundMessageTap(initialMessage);
    }
  }

  // FCMトークンを保存
  static Future<void> _saveFCMToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore
            .collection('user_tokens')
            .doc(user.uid)
            .set({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
          'platform': defaultTargetPlatform.name,
        }, SetOptions(merge: true));
        
        print('FCMトークンを保存: $token');
      }
    } catch (e) {
      print('FCMトークン保存エラー: $e');
    }
  }

  // フォアグラウンド通知処理
  static void _handleForegroundMessage(RemoteMessage message) {
    // アプリ内通知表示（SnackBarなど）
    // TODO: 実装
  }

  // バックグラウンド通知タップ処理
  static void _handleBackgroundMessageTap(RemoteMessage message) {
    // 適切な画面に遷移
    final data = message.data;
    if (data.containsKey('postId')) {
      // 投稿詳細画面に遷移
      // TODO: ナビゲーション実装
    }
  }

  // 通知を作成してFirestoreに保存
  static Future<void> createNotification(AppNotification notification) async {
    try {
      final docRef = _firestore.collection('notifications').doc();
      final notificationWithId = notification.copyWith(id: docRef.id);
      
      await docRef.set(notificationWithId.toJson());
      print('通知を作成: ${notification.title}');

      // プッシュ通知を送信
      await _sendPushNotification(notificationWithId);
    } catch (e) {
      print('通知作成エラー: $e');
    }
  }

  // プッシュ通知送信
  static Future<void> _sendPushNotification(AppNotification notification) async {
    try {
      // ユーザーのFCMトークンを取得
      final tokenDoc = await _firestore
          .collection('user_tokens')
          .doc(notification.userId)
          .get();

      if (!tokenDoc.exists) {
        print('ユーザーのFCMトークンが見つかりません: ${notification.userId}');
        return;
      }

      final fcmToken = tokenDoc.data()?['fcmToken'] as String?;
      if (fcmToken == null) {
        print('FCMトークンが空です');
        return;
      }

      // TODO: Firebase Functions経由でプッシュ通知を送信
      // または、FCM Admin SDKを使用してサーバーサイドで送信
      print('プッシュ通知を送信予定: ${notification.title} -> $fcmToken');
    } catch (e) {
      print('プッシュ通知送信エラー: $e');
    }
  }

  // ユーザーの通知一覧を取得
  static Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AppNotification.fromJson({
          ...data,
          'id': doc.id,
        });
      }).toList();
    });
  }

  // 通知を既読にする
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
      print('通知を既読にしました: $notificationId');
    } catch (e) {
      print('既読更新エラー: $e');
    }
  }

  // 未読通知数を取得
  static Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // 通知削除
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
      print('通知を削除しました: $notificationId');
    } catch (e) {
      print('通知削除エラー: $e');
    }
  }

  // 全通知を既読にする
  static Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      print('全通知を既読にしました');
    } catch (e) {
      print('一括既読エラー: $e');
    }
  }

  // 投稿承認通知を送信
  static Future<void> sendPostApprovedNotification({
    required String postAuthorId,
    required String postTitle,
    required String postId,
  }) async {
    final notification = NotificationFactory.createPostApprovedNotification(
      postAuthorId: postAuthorId,
      postTitle: postTitle,
      postId: postId,
    );
    await createNotification(notification);
  }

  // 投稿却下通知を送信
  static Future<void> sendPostRejectedNotification({
    required String postAuthorId,
    required String postTitle,
    required String postId,
    String? reason,
  }) async {
    final notification = NotificationFactory.createPostRejectedNotification(
      postAuthorId: postAuthorId,
      postTitle: postTitle,
      postId: postId,
      reason: reason,
    );
    await createNotification(notification);
  }

  // ピン留め承認通知を送信
  static Future<void> sendPinApprovedNotification({
    required String postAuthorId,
    required String postTitle,
    required String postId,
  }) async {
    final notification = NotificationFactory.createPinApprovedNotification(
      postAuthorId: postAuthorId,
      postTitle: postTitle,
      postId: postId,
    );
    await createNotification(notification);
  }

  // ピン留め却下通知を送信
  static Future<void> sendPinRejectedNotification({
    required String postAuthorId,
    required String postTitle,
    required String postId,
    String? reason,
  }) async {
    final notification = NotificationFactory.createPinRejectedNotification(
      postAuthorId: postAuthorId,
      postTitle: postTitle,
      postId: postId,
      reason: reason,
    );
    await createNotification(notification);
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
    // 自分への通知は送信しない
    if (postAuthorId == fromUserId) return;

    final notification = NotificationFactory.createCommentNotification(
      postAuthorId: postAuthorId,
      postTitle: postTitle,
      commentAuthorName: commentAuthorName,
      postId: postId,
      commentId: commentId,
      fromUserId: fromUserId,
    );
    await createNotification(notification);
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
    // 自分への通知は送信しない
    if (commentAuthorId == fromUserId) return;

    final notification = NotificationFactory.createReplyNotification(
      commentAuthorId: commentAuthorId,
      replyAuthorName: replyAuthorName,
      postTitle: postTitle,
      postId: postId,
      commentId: commentId,
      replyId: replyId,
      fromUserId: fromUserId,
    );
    await createNotification(notification);
  }
}

// バックグラウンド通知ハンドラー（トップレベル関数）
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('バックグラウンド通知を受信: ${message.messageId}');
  // 必要に応じて処理を追加
}