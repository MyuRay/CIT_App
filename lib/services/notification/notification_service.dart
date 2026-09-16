import 'package:cit_app/core/utils/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/notification/notification_model.dart';
import '../schedule/schedule_notification_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'device_token_store.dart';
import 'notification_target.dart';
import '../auth/session_work_guard.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// FCM リスナーの二重登録を防ぐためのガード。
  /// `initialize()` は起動時・ログイン時・復帰時など複数経路から呼ばれ得る。
  static bool _messagingHandlersRegistered = false;
  static Future<void> _registrationQueue = Future.value();
  static bool _loggingOut = false;
  static int _sessionGeneration = 0;
  static final taps = NotificationTapQueue();

  static bool get _supportsMessaging =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  static Future<String> _installationId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('push_installation_id');
    if (existing != null) return existing;
    final id = const Uuid().v4();
    await prefs.setString('push_installation_id', id);
    return id;
  }

  /// Freeze token refreshes, drain earlier writes, then remove this installation.
  /// Failure propagates so the UI keeps the account signed in and offers retry.
  static Future<void> unregisterCurrentDevice() async {
    _loggingOut = true;
    SessionWorkGuard.suspend();
    _sessionGeneration++;
    taps.clear();
    await _registrationQueue;
    final user = _auth.currentUser;
    if (user == null || !_supportsMessaging) return;
    if (!await _messaging.isSupported()) return;
    try {
      await DeviceTokenStore(
        _firestore,
      ).unregister(userId: user.uid, installationId: await _installationId());
    } on FirebaseException catch (error) {
      // A revoked Auth session cannot edit its registry; invalidating the FCM
      // token still prevents delivery. Other failures remain retryable errors.
      if (error.code != 'permission-denied' && error.code != 'unauthenticated')
        rethrow;
    }
    await _messaging.deleteToken();
  }

  static void finishLogout() {
    _loggingOut = false;
    SessionWorkGuard.resume();
  }

  // Firebase Messaging初期化（複数回呼ばれても安全）
  static Future<void> initialize() async {
    if (!_supportsMessaging || !await _messaging.isSupported()) return;
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

    SecureLogger.debug('ユーザー通知権限: ${settings.authorizationStatus}');

    // フォアグラウンド表示用にローカル通知サービスを初期化しておく。
    try {
      await ScheduleNotificationService.initialize();
    } catch (e) {
      SecureLogger.debug('ローカル通知初期化エラー（無視）: $e');
    }

    // FCMトークンを取得してFirestoreに保存
    await _saveFCMToken();

    // 以降のストリーム購読は 1 度だけ登録する（二重登録防止）。
    if (_messagingHandlersRegistered) {
      // トークンの再保存だけ済ませて戻る。
      return;
    }
    _messagingHandlersRegistered = true;

    // トークンリフレッシュ時の処理
    _messaging.onTokenRefresh.listen((fcmToken) async {
      SecureLogger.debug('通知トークンが更新されました');
      await _saveFCMToken();
    });

    // フォアグラウンド通知受信時の処理
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      SecureLogger.debug('通知イベントを受信しました');
      _handleForegroundMessage(message);
    });

    // バックグラウンド通知タップ時の処理
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      SecureLogger.debug('通知イベントを受信しました');
      _handleBackgroundMessageTap(message);
    });

    // アプリ終了時の通知タップ時の処理（アプリ起動時にチェック）
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      SecureLogger.debug('通知イベントを受信しました');
      _handleBackgroundMessageTap(initialMessage);
    }
  }

  /// 現在のユーザーの FCM トークンを Firestore に再登録する。
  /// アプリ復帰時などに呼び、古い/失効したトークンによる送信失敗を防ぐ。
  static Future<void> refreshTokenRegistration() async {
    await _saveFCMToken();
  }

  // FCMトークンを保存
  static Future<void> _saveFCMToken() {
    final generation = _sessionGeneration;
    final user = _auth.currentUser;
    if (_loggingOut ||
        user == null ||
        !user.emailVerified ||
        !_supportsMessaging)
      return Future.value();
    final task = _registrationQueue.then((_) async {
      if (!await _messaging.isSupported()) return;
      if (_loggingOut ||
          generation != _sessionGeneration ||
          _auth.currentUser?.uid != user.uid)
        return;
      final prefs = await SharedPreferences.getInstance();
      String? previousToken;
      if (prefs.getBool('push_registry_v2_migrated') != true) {
        // Revoke legacy associations left by earlier app versions on this phone.
        previousToken = await _messaging.getToken();
        await _messaging.deleteToken();
        await prefs.setBool('push_registry_v2_migrated', true);
      }
      // Read the current token, never a possibly stale queued refresh event.
      final resolvedToken = await _messaging.getToken();
      final installationId = await _installationId();
      if (resolvedToken == null ||
          _loggingOut ||
          generation != _sessionGeneration ||
          _auth.currentUser?.uid != user.uid)
        return;
      await DeviceTokenStore(_firestore).register(
        userId: user.uid,
        installationId: installationId,
        token: resolvedToken,
        platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
        previousToken: previousToken,
      );
    });
    _registrationQueue = task.catchError((Object _) {
      SecureLogger.debug('通知端末の登録に失敗しました');
    });
    return _registrationQueue;
  }

  // フォアグラウンド通知処理
  static void _handleForegroundMessage(RemoteMessage message) {
    final target = NotificationTarget.fromData(message.data);
    final user = _auth.currentUser;
    if (_loggingOut || user == null || !target.belongsTo(user.uid)) return;
    // フォアグラウンドでは OS がプッシュを自動表示しないため、
    // ローカル通知として明示的に表示する（「開いている時は通知が来ない」対策）。
    final notification = message.notification;
    final title =
        notification?.title ?? (message.data['title'] as String?) ?? 'お知らせ';
    final body =
        notification?.body ??
        (message.data['body'] as String?) ??
        (message.data['message'] as String?) ??
        '';

    if (title.trim().isEmpty && body.trim().isEmpty) return;

    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS))
      return;
    ScheduleNotificationService.showImmediateNotification(
      title: title,
      body: body,
      payload: target.encode(),
    ).catchError((Object _) {
      SecureLogger.debug('通知を表示できませんでした');
    });
  }

  // バックグラウンド通知タップ処理
  static void _handleBackgroundMessageTap(RemoteMessage message) {
    taps.add(NotificationTarget.fromData(message.data));
  }

  // 通知を作成してFirestoreに保存
  static Future<void> createNotification(AppNotification notification) async {
    try {
      final docRef = _firestore.collection('notifications').doc();
      final notificationWithId = notification.copyWith(id: docRef.id);

      await docRef.set(notificationWithId.toJson());
      SecureLogger.debug('通知を作成しました');
    } catch (e) {
      SecureLogger.debug('通知作成エラー: $e');
    }
  }

  // Push delivery is performed by the notifications Firestore trigger.

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
            return AppNotification.fromJson({...data, 'id': doc.id});
          }).toList();
        });
  }

  // 通知を既読にする
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
      SecureLogger.debug('通知を既読にしました: $notificationId');
    } catch (e) {
      SecureLogger.debug('既読更新エラー: $e');
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
      await _firestore.collection('notifications').doc(notificationId).delete();
      SecureLogger.debug('通知を削除しました: $notificationId');
    } catch (e) {
      SecureLogger.debug('通知削除エラー: $e');
    }
  }

  // 全通知を既読にする
  static Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .where('isRead', isEqualTo: false)
              .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      SecureLogger.debug('全通知を既読にしました');
    } catch (e) {
      SecureLogger.debug('一括既読エラー: $e');
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
  SecureLogger.debug('バックグラウンド通知を受信: ${message.messageId}');
  // 必要に応じて処理を追加
}
