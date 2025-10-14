import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notification/notification_model.dart';

// ユーザーの通知一覧プロバイダー
final userNotificationsProvider = StreamProvider.family<List<AppNotification>, String>((ref, userId) {
  print('🚀 userNotificationsProvider初期化 - ユーザーID: $userId');
  
  try {
    print('📢 Firestoreから通知監視開始: $userId');
    
    // まずはシンプルなクエリでテスト（orderByなし）
    final stream = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .limit(50) // 最新50件
        .snapshots();
    
    print('🔗 Firestoreストリームを作成しました');
    
    return stream.map((snapshot) {
      print('📢 通知データ受信: ${snapshot.docs.length}件 (ユーザー: $userId)');
      print('🔍 スナップショット情報: metadata=${snapshot.metadata}, fromCache=${snapshot.metadata.isFromCache}');
      
      if (snapshot.docs.isEmpty) {
        print('ℹ️ このユーザーの通知はありません: $userId');
        print('🔍 Firestoreクエリ確認: collection=notifications, where userId == $userId');
        return <AppNotification>[];
      }
      
      final notifications = <AppNotification>[];
      
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        try {
          print('🔍 通知ドキュメント ${i + 1}/${snapshot.docs.length} を処理中: ${doc.id}');
          final data = doc.data();
          data['id'] = doc.id;
          
          print('📋 通知データ内容: ${data.toString()}');
          final notification = AppNotification.fromJson(data);
          notifications.add(notification);
          print('✅ 通知データ変換成功: ${notification.title}');
        } catch (e, stackTrace) {
          print('❌ 通知データ変換エラー (docId: ${doc.id}): $e');
          print('❌ エラースタック: $stackTrace');
        }
      }
      
      // Dartコード側でソート
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('📢 通知データ処理完了: ${notifications.length}件');
      if (notifications.isNotEmpty) {
        print('📝 最新通知: ${notifications.first.title}');
      }
      
      return notifications;
    }).handleError((error, stackTrace) {
      print('❌ 通知ストリームエラー (ユーザー: $userId): $error');
      print('❌ エラースタック: $stackTrace');
      return <AppNotification>[];
    });
  } catch (e, stackTrace) {
    print('❌ 通知プロバイダー初期化エラー (ユーザー: $userId): $e');
    print('❌ 初期化エラースタック: $stackTrace');
    return Stream.value(<AppNotification>[]);
  }
});

// 未読通知数プロバイダー
final unreadNotificationCountProvider = StreamProvider.family<int, String>((ref, userId) {
  print('📊 unreadNotificationCountProvider初期化 - ユーザーID: $userId');
  
  try {
    print('📊 未読通知数監視開始: $userId');
    
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      try {
        print('📊 未読通知数計算中... (総通知数: ${snapshot.docs.length})');        
        // Dartコード側で未読をフィルタ
        final unreadCount = snapshot.docs.where((doc) {
          final data = doc.data();
          final isRead = data['isRead'] ?? false;
          return !isRead; // nullまたはfalseの場合は未読
        }).length;
        
        print('📊 未読通知数計算結果: $unreadCount (ユーザー: $userId)');
        return unreadCount;
      } catch (e, stackTrace) {
        print('❌ 未読通知数計算エラー (ユーザー: $userId): $e');
        print('❌ エラースタック: $stackTrace');
        return 0;
      }
    }).handleError((error, stackTrace) {
      print('❌ 未読通知数ストリームエラー (ユーザー: $userId): $error');
      print('❌ エラースタック: $stackTrace');
      return 0;
    });
  } catch (e, stackTrace) {
    print('❌ 未読通知数プロバイダー初期化エラー (ユーザー: $userId): $e');
    print('❌ 初期化エラースタック: $stackTrace');
    return Stream.value(0);
  }
});

// 通知サービス
class NotificationService {
  static Future<void> sendNotification(AppNotification notification) async {
    try {
      print('📢 sendNotification開始: ${notification.type.displayName}');
      print('🔍 通知送信対象ユーザーID: ${notification.userId}');
      
      final docRef = FirebaseFirestore.instance.collection('notifications').doc();
      print('🆔 生成された通知ID: ${docRef.id}');
      
      final notificationWithId = notification.copyWith(id: docRef.id);
      final jsonData = notificationWithId.toJson();
      
      print('📝 Firestoreに保存する通知データ:');
      jsonData.forEach((key, value) {
        print('  $key: $value');
      });
      
      print('💾 Firestoreに通知を保存中...');
      await docRef.set(jsonData);
      
      print('🔍 保存確認のため通知ドキュメントを読み込み中...');
      final savedDoc = await docRef.get();
      if (savedDoc.exists) {
        print('✅ 通知がFirestoreに正常に保存されました');
        final savedData = savedDoc.data();
        print('📋 保存された通知データ確認:');
        savedData?.forEach((key, value) {
          print('  $key: $value');
        });
      } else {
        print('❌ 通知の保存確認に失敗しました');
      }
      
      print('✅ 通知送信完了: ${notification.title}');
    } catch (e, stackTrace) {
      print('❌ 通知送信エラー: $e');
      print('❌ スタックトレース: $stackTrace');
      rethrow;
    }
  }

  static Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
      
      print('✅ 通知既読化完了: $notificationId');
    } catch (e) {
      print('❌ 通知既読化エラー: $e');
      rethrow;
    }
  }

  static Future<void> markAllAsRead(String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
      
      print('✅ 全通知既読化完了: ${querySnapshot.docs.length}件');
    } catch (e) {
      print('❌ 全通知既読化エラー: $e');
      rethrow;
    }
  }

  static Future<void> deleteNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();
      
      print('✅ 通知削除完了: $notificationId');
    } catch (e) {
      print('❌ 通知削除エラー: $e');
      rethrow;
    }
  }
  
  // テスト用のダミー通知作成メソッド
  static Future<void> createTestNotification(String userId) async {
    try {
      print('🧪 テスト通知を作成中... (ユーザー: $userId)');
      
      final notification = AppNotification(
        id: '', // Firestoreで自動生成
        userId: userId,
        type: NotificationType.system,
        title: 'テスト通知',
        message: 'これはテスト用の通知です。通知システムが正常に動作しています。',
        createdAt: DateTime.now(),
      );
      
      await sendNotification(notification);
      print('✅ テスト通知作成完了');
    } catch (e) {
      print('❌ テスト通知作成エラー: $e');
      rethrow;
    }
  }
  
  // 特定ユーザーの全通知を削除するメソッド
  static Future<void> deleteAllNotifications(String userId) async {
    try {
      print('🗑️ 全通知削除開始 - ユーザー: $userId');
      
      // ユーザーの全通知を取得
      final querySnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();
      
      print('📊 削除対象通知数: ${querySnapshot.docs.length}件');
      
      if (querySnapshot.docs.isEmpty) {
        print('ℹ️ 削除する通知がありません');
        return;
      }
      
      // バッチで一括削除
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
        print('🔄 削除キューに追加: ${doc.id}');
      }
      
      print('📦 バッチ削除実行中...');
      await batch.commit();
      
      print('✅ 全通知削除完了: ${querySnapshot.docs.length}件を削除しました');
    } catch (e, stackTrace) {
      print('❌ 全通知削除エラー: $e');
      print('❌ スタックトレース: $stackTrace');
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
    print('🔔 sendCommentNotification開始');
    print('  - postAuthorId: $postAuthorId');
    print('  - postTitle: $postTitle');
    print('  - commentAuthorName: $commentAuthorName');
    print('  - postId: $postId');
    print('  - commentId: $commentId');
    print('  - fromUserId: $fromUserId');
    
    // 自分自身への通知は送らない
    if (fromUserId == postAuthorId) {
      print('🚫 自分自身への通知はスキップ: $postAuthorId');
      return;
    }

    print('🏗️ 通知オブジェクトを作成中...');
    final notification = NotificationFactory.createCommentNotification(
      postAuthorId: postAuthorId,
      postTitle: postTitle,
      commentAuthorName: commentAuthorName,
      postId: postId,
      commentId: commentId,
      fromUserId: fromUserId,
    );
    
    print('📝 作成された通知内容:');
    print('  - userId: ${notification.userId}');
    print('  - type: ${notification.type.displayName}');
    print('  - title: ${notification.title}');
    print('  - message: ${notification.message}');

    print('📤 通知送信処理開始...');
    await sendNotification(notification);
    print('✅ sendCommentNotification完了');
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
    print('🔔 sendReplyNotification開始');
    print('  - commentAuthorId: $commentAuthorId');
    print('  - replyAuthorName: $replyAuthorName');
    print('  - postTitle: $postTitle');
    print('  - postId: $postId');
    print('  - commentId: $commentId');
    print('  - replyId: $replyId');
    print('  - fromUserId: $fromUserId');
    
    // 自分自身への通知は送らない
    if (fromUserId == commentAuthorId) {
      print('🚫 自分自身への返信通知はスキップ: $commentAuthorId');
      return;
    }

    print('🏗️ 返信通知オブジェクトを作成中...');
    final notification = NotificationFactory.createReplyNotification(
      commentAuthorId: commentAuthorId,
      replyAuthorName: replyAuthorName,
      postTitle: postTitle,
      postId: postId,
      commentId: commentId,
      replyId: replyId,
      fromUserId: fromUserId,
    );
    
    print('📝 作成された返信通知内容:');
    print('  - userId: ${notification.userId}');
    print('  - type: ${notification.type.displayName}');
    print('  - title: ${notification.title}');
    print('  - message: ${notification.message}');

    print('📤 返信通知送信処理開始...');
    await sendNotification(notification);
    print('✅ sendReplyNotification完了');
  }

  // 投稿承認通知を送信
  static Future<void> sendPostApprovedNotification({
    required String postAuthorId,
    required String postTitle,
    required String postId,
  }) async {
    print('🔔 sendPostApprovedNotification開始');
    print('  - postAuthorId: $postAuthorId');
    print('  - postTitle: $postTitle');
    print('  - postId: $postId');

    final notification = NotificationFactory.createPostApprovedNotification(
      postAuthorId: postAuthorId,
      postTitle: postTitle,
      postId: postId,
    );

    print('📤 投稿承認通知送信処理開始...');
    await sendNotification(notification);
    print('✅ sendPostApprovedNotification完了');
  }

  // 投稿却下通知を送信
  static Future<void> sendPostRejectedNotification({
    required String postAuthorId,
    required String postTitle,
    required String postId,
    String? reason,
  }) async {
    print('🔔 sendPostRejectedNotification開始');
    print('  - postAuthorId: $postAuthorId');
    print('  - postTitle: $postTitle');
    print('  - postId: $postId');
    print('  - reason: $reason');

    final notification = NotificationFactory.createPostRejectedNotification(
      postAuthorId: postAuthorId,
      postTitle: postTitle,
      postId: postId,
      reason: reason,
    );

    print('📤 投稿却下通知送信処理開始...');
    await sendNotification(notification);
    print('✅ sendPostRejectedNotification完了');
  }

  // ピン留め承認通知を送信
  static Future<void> sendPinApprovedNotification({
    required String postAuthorId,
    required String postTitle,
    required String postId,
  }) async {
    print('🔔 sendPinApprovedNotification開始');
    print('  - postAuthorId: $postAuthorId');
    print('  - postTitle: $postTitle');
    print('  - postId: $postId');

    final notification = NotificationFactory.createPinApprovedNotification(
      postAuthorId: postAuthorId,
      postTitle: postTitle,
      postId: postId,
    );

    print('📤 ピン留め承認通知送信処理開始...');
    await sendNotification(notification);
    print('✅ sendPinApprovedNotification完了');
  }

  // ピン留め却下通知を送信
  static Future<void> sendPinRejectedNotification({
    required String postAuthorId,
    required String postTitle,
    required String postId,
    String? reason,
  }) async {
    print('🔔 sendPinRejectedNotification開始');
    print('  - postAuthorId: $postAuthorId');
    print('  - postTitle: $postTitle');
    print('  - postId: $postId');
    print('  - reason: $reason');

    final notification = NotificationFactory.createPinRejectedNotification(
      postAuthorId: postAuthorId,
      postTitle: postTitle,
      postId: postId,
      reason: reason,
    );

    print('📤 ピン留め却下通知送信処理開始...');
    await sendNotification(notification);
    print('✅ sendPinRejectedNotification完了');
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
final notificationNotifierProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<void>>((ref) {
  return NotificationNotifier();
});

// テスト用通知作成プロバイダー
final createTestNotificationProvider = FutureProvider.family<void, String>((ref, userId) async {
  await NotificationService.createTestNotification(userId);
});

// 全通知削除プロバイダー
final deleteAllNotificationsProvider = FutureProvider.family<void, String>((ref, userId) async {
  await NotificationService.deleteAllNotifications(userId);
});