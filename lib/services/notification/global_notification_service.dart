import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/notification/notification_model.dart';

class GlobalNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'global_notifications';
  static const String _viewedNotificationsKey = 'viewed_notification_ids';

  // 全体通知を作成（管理者用）
  static Future<String> createGlobalNotification(GlobalNotification notification) async {
    try {
      final docRef = await _firestore
          .collection(_collectionName)
          .add(notification.toJson());
      
      // IDを設定して再保存
      await docRef.update({'id': docRef.id});
      
      print('✅ 全体通知を作成しました: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ 全体通知作成エラー: $e');
      rethrow;
    }
  }

  // 全体通知を更新（管理者用）
  static Future<void> updateGlobalNotification(
    String notificationId,
    GlobalNotification notification,
  ) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(notificationId)
          .update(notification.toJson());
      
      print('✅ 全体通知を更新しました: $notificationId');
    } catch (e) {
      print('❌ 全体通知更新エラー: $e');
      rethrow;
    }
  }

  // 全体通知を無効化（管理者用）
  static Future<void> deactivateGlobalNotification(String notificationId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(notificationId)
          .update({'isActive': false});
      
      print('✅ 全体通知を無効化しました: $notificationId');
    } catch (e) {
      print('❌ 全体通知無効化エラー: $e');
      rethrow;
    }
  }

  // 全体通知を削除（管理者用）
  static Future<void> deleteGlobalNotification(String notificationId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(notificationId)
          .delete();
      
      print('✅ 全体通知を削除しました: $notificationId');
    } catch (e) {
      print('❌ 全体通知削除エラー: $e');
      rethrow;
    }
  }

  // アクティブな全体通知を取得
  static Stream<List<GlobalNotification>> getActiveGlobalNotifications() {
    return _firestore
        .collection(_collectionName)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => GlobalNotification.fromJson(doc.data()))
          .where((notification) => notification.isCurrentlyActive)
          .toList();
      
      print('🔔 アクティブな全体通知: ${notifications.length}件取得');
      return notifications;
    });
  }

  // すべての全体通知を取得（管理者用）
  static Stream<List<GlobalNotification>> getAllGlobalNotifications() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => GlobalNotification.fromJson(doc.data()))
          .toList();
      
      print('📋 全通知: ${notifications.length}件取得');
      return notifications;
    });
  }

  // 未表示の通知を取得（ユーザーがまだ見ていない通知）
  static Future<List<GlobalNotification>> getUnviewedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final viewedIds = prefs.getStringList(_viewedNotificationsKey) ?? [];
      
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      
      final unviewedNotifications = snapshot.docs
          .map((doc) => GlobalNotification.fromJson(doc.data()))
          .where((notification) => 
              notification.isCurrentlyActive && 
              !viewedIds.contains(notification.id))
          .toList();
      
      print('🔔 未表示通知: ${unviewedNotifications.length}件');
      return unviewedNotifications;
    } catch (e) {
      print('❌ 未表示通知取得エラー: $e');
      return [];
    }
  }

  // 通知を「表示済み」としてマーク
  static Future<void> markNotificationAsViewed(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final viewedIds = prefs.getStringList(_viewedNotificationsKey) ?? [];
      
      if (!viewedIds.contains(notificationId)) {
        viewedIds.add(notificationId);
        await prefs.setStringList(_viewedNotificationsKey, viewedIds);
        print('✅ 通知を表示済みにマーク: $notificationId');
      }
    } catch (e) {
      print('❌ 通知表示済みマークエラー: $e');
    }
  }

  // 複数の通知を「表示済み」としてマーク
  static Future<void> markNotificationsAsViewed(List<String> notificationIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final viewedIds = prefs.getStringList(_viewedNotificationsKey) ?? [];
      
      bool hasChanges = false;
      for (final id in notificationIds) {
        if (!viewedIds.contains(id)) {
          viewedIds.add(id);
          hasChanges = true;
        }
      }
      
      if (hasChanges) {
        await prefs.setStringList(_viewedNotificationsKey, viewedIds);
        print('✅ ${notificationIds.length}件の通知を表示済みにマーク');
      }
    } catch (e) {
      print('❌ 複数通知表示済みマークエラー: $e');
    }
  }

  // 表示済み通知履歴をクリア（デバッグ用）
  static Future<void> clearViewedHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_viewedNotificationsKey);
      print('🗑️ 表示済み通知履歴をクリアしました');
    } catch (e) {
      print('❌ 表示済み履歴クリアエラー: $e');
    }
  }

  // 便利なファクトリーメソッド
  static Future<String> createAppUpdateNotification({
    required String version,
    required String message,
    DateTime? expiresAt,
  }) async {
    final notification = GlobalNotificationFactory.createAppUpdateNotification(
      version: version,
      message: message,
      expiresAt: expiresAt,
    );
    return await createGlobalNotification(notification);
  }

  static Future<String> createMaintenanceNotification({
    required String message,
    DateTime? expiresAt,
  }) async {
    final notification = GlobalNotificationFactory.createMaintenanceNotification(
      message: message,
      expiresAt: expiresAt,
    );
    return await createGlobalNotification(notification);
  }

  static Future<String> createFeatureNotification({
    required String title,
    required String message,
    String? url,
    DateTime? expiresAt,
  }) async {
    final notification = GlobalNotificationFactory.createFeatureNotification(
      title: title,
      message: message,
      url: url,
      expiresAt: expiresAt,
    );
    return await createGlobalNotification(notification);
  }
}
