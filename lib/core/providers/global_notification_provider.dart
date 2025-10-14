import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/notification/notification_model.dart';
import '../../services/notification/global_notification_service.dart';

// アクティブな全体通知のストリームプロバイダー
final globalNotificationsProvider = StreamProvider<List<GlobalNotification>>((ref) {
  return GlobalNotificationService.getActiveGlobalNotifications();
});

// すべての全体通知のストリームプロバイダー（管理者用）
final allGlobalNotificationsProvider = StreamProvider<List<GlobalNotification>>((ref) {
  return GlobalNotificationService.getAllGlobalNotifications();
});

// 未表示の通知を取得するプロバイダー
final unviewedNotificationsProvider = FutureProvider<List<GlobalNotification>>((ref) {
  return GlobalNotificationService.getUnviewedNotifications();
});

// 未表示通知の数を取得するプロバイダー
final unviewedNotificationCountProvider = Provider<int>((ref) {
  final unviewedAsync = ref.watch(unviewedNotificationsProvider);
  return unviewedAsync.when(
    data: (notifications) => notifications.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// 未表示通知の数を取得するプロバイダー（リアルタイム更新）
final realtimeUnviewedCountProvider = StreamProvider<int>((ref) {
  return ref.watch(globalNotificationsProvider).when(
    data: (notifications) async* {
      final unviewedNotifications = await GlobalNotificationService.getUnviewedNotifications();
      yield unviewedNotifications.length;
    },
    loading: () => Stream.value(0),
    error: (_, __) => Stream.value(0),
  );
});

// 最新の重要な通知を取得するプロバイダー（ポップアップ表示用）
final latestImportantNotificationProvider = Provider<GlobalNotification?>((ref) {
  final notificationsAsync = ref.watch(globalNotificationsProvider);
  
  return notificationsAsync.when(
    data: (notifications) {
      // 重要度の高い通知タイプを優先
      final importantTypes = [
        NotificationType.appUpdate,
        NotificationType.important,
        NotificationType.maintenance,
      ];
      
      for (final type in importantTypes) {
        final filtered = notifications.where((n) => n.type == type);
        if (filtered.isNotEmpty) return filtered.first;
      }
      
      // 重要でない通知も含めて最新のものを返す
      return notifications.isNotEmpty ? notifications.first : null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// 通知管理用のサービスプロバイダー
final globalNotificationServiceProvider = Provider<GlobalNotificationService>((ref) {
  throw UnimplementedError('GlobalNotificationServiceは静的メソッドを使用してください');
});

// 通知アクション（表示済みマーク等）を実行するためのプロバイダー
final notificationActionsProvider = Provider<NotificationActions>((ref) {
  return NotificationActions(ref);
});

class NotificationActions {
  final ProviderRef ref;
  
  NotificationActions(this.ref);
  
  // 通知を表示済みにマーク
  Future<void> markAsViewed(String notificationId) async {
    await GlobalNotificationService.markNotificationAsViewed(notificationId);
    // 未表示通知プロバイダーを更新
    ref.invalidate(unviewedNotificationsProvider);
  }
  
  // 複数の通知を表示済みにマーク
  Future<void> markMultipleAsViewed(List<String> notificationIds) async {
    await GlobalNotificationService.markNotificationsAsViewed(notificationIds);
    // 未表示通知プロバイダーを更新
    ref.invalidate(unviewedNotificationsProvider);
  }
  
  // すべての未表示通知を表示済みにマーク
  Future<void> markAllAsViewed() async {
    final unviewedAsync = ref.read(unviewedNotificationsProvider);
    final unviewed = await unviewedAsync.when(
      data: (notifications) => notifications,
      loading: () => <GlobalNotification>[],
      error: (_, __) => <GlobalNotification>[],
    );
    
    if (unviewed.isNotEmpty) {
      final ids = unviewed.map((n) => n.id).toList();
      await markMultipleAsViewed(ids);
    }
  }
  
  // 表示済み履歴をクリア（デバッグ用）
  Future<void> clearViewedHistory() async {
    await GlobalNotificationService.clearViewedHistory();
    ref.invalidate(unviewedNotificationsProvider);
  }
}

// 管理者向けの通知作成アクションプロバイダー
final notificationCreationProvider = Provider<NotificationCreation>((ref) {
  return NotificationCreation(ref);
});

class NotificationCreation {
  final ProviderRef ref;
  
  NotificationCreation(this.ref);
  
  // アプリアップデート通知を作成
  Future<String> createAppUpdateNotification({
    required String version,
    required String message,
    DateTime? expiresAt,
  }) async {
    final id = await GlobalNotificationService.createAppUpdateNotification(
      version: version,
      message: message,
      expiresAt: expiresAt,
    );
    
    // 通知リストを更新
    ref.invalidate(globalNotificationsProvider);
    ref.invalidate(allGlobalNotificationsProvider);
    ref.invalidate(unviewedNotificationsProvider);
    
    return id;
  }
  
  // メンテナンス通知を作成
  Future<String> createMaintenanceNotification({
    required String message,
    DateTime? expiresAt,
  }) async {
    final id = await GlobalNotificationService.createMaintenanceNotification(
      message: message,
      expiresAt: expiresAt,
    );
    
    // 通知リストを更新
    ref.invalidate(globalNotificationsProvider);
    ref.invalidate(allGlobalNotificationsProvider);
    ref.invalidate(unviewedNotificationsProvider);
    
    return id;
  }
  
  // 新機能通知を作成
  Future<String> createFeatureNotification({
    required String title,
    required String message,
    String? url,
    DateTime? expiresAt,
  }) async {
    final id = await GlobalNotificationService.createFeatureNotification(
      title: title,
      message: message,
      url: url,
      expiresAt: expiresAt,
    );
    
    // 通知リストを更新
    ref.invalidate(globalNotificationsProvider);
    ref.invalidate(allGlobalNotificationsProvider);
    ref.invalidate(unviewedNotificationsProvider);
    
    return id;
  }
  
  // 通知を無効化
  Future<void> deactivateNotification(String notificationId) async {
    await GlobalNotificationService.deactivateGlobalNotification(notificationId);
    
    // 通知リストを更新
    ref.invalidate(globalNotificationsProvider);
    ref.invalidate(allGlobalNotificationsProvider);
    ref.invalidate(unviewedNotificationsProvider);
  }

  // 通知を削除
  Future<void> deleteNotification(String notificationId) async {
    await GlobalNotificationService.deleteGlobalNotification(notificationId);
    
    // 通知リストを更新
    ref.invalidate(globalNotificationsProvider);
    ref.invalidate(allGlobalNotificationsProvider);
    ref.invalidate(unviewedNotificationsProvider);
  }
}
