import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/notification/notification_model.dart';
import '../../core/providers/notification_provider.dart';
import '../bulletin/bulletin_post_detail_screen.dart';
import '../../core/providers/bulletin_provider.dart';
import '../../core/providers/auth_provider.dart';

class NotificationListScreen extends ConsumerWidget {
  final bool showAppBar;
  
  const NotificationListScreen({
    super.key, 
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('📱 NotificationListScreen build開始');
    final authState = ref.watch(authStateProvider);
    
    return authState.when(
      data: (user) {
        print('👤 認証データ取得: ${user?.uid ?? "null"}');
        if (user == null) {
          print('⚠️ ユーザーがログインしていません');
          return Scaffold(
            appBar: showAppBar ? AppBar(title: const Text('通知')) : null,
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('ログインが必要です'),
                ],
              ),
            ),
          );
        }
        
        print('✅ 通知画面を構築中 - ユーザーID: ${user.uid}');
        return _buildNotificationScreen(context, ref, user.uid);
      },
      loading: () {
        print('⏳ 認証データを読み込み中...');
        return Scaffold(
          appBar: showAppBar ? AppBar(title: const Text('通知')) : null,
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('認証情報を読み込み中...'),
              ],
            ),
          ),
        );
      },
      error: (error, stack) {
        print('❌ 認証エラー: $error');
        return Scaffold(
          appBar: showAppBar ? AppBar(title: const Text('通知')) : null,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('認証エラー: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    print('🔄 認証プロバイダーを再読み込み');
                    ref.invalidate(authStateProvider);
                  },
                  child: const Text('再試行'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildNotificationScreen(BuildContext context, WidgetRef ref, String userId) {
    print('🔔 _buildNotificationScreen開始 - ユーザーID: $userId');
    
    try {
      final notificationsAsync = ref.watch(userNotificationsProvider(userId));
      print('📋 通知プロバイダーを監視中...');

      return Scaffold(
        appBar: showAppBar ? AppBar(
          title: const Text('通知'),
          actions: [
            // テスト用ボタン
            IconButton(
              icon: const Icon(Icons.add_alert),
              onPressed: () => _createTestNotification(context, ref, userId),
              tooltip: 'テスト通知作成',
            ),
            IconButton(
              tooltip: '全て既読',
              icon: const Icon(Icons.done_all),
              onPressed: () => _markAllAsRead(context, ref, userId),
            ),
          ],
        ) : null,
        body: notificationsAsync.when(
          data: (notifications) {
            print('📋 通知データ受信成功: ${notifications.length}件');
            if (notifications.isNotEmpty) {
              print('📝 最初の通知: ${notifications.first.title}');
            }
            return _buildNotificationsList(context, ref, notifications);
          },
          loading: () {
            print('⏳ 通知データ読み込み中... (ユーザーID: $userId)');
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('通知を読み込み中...'),
                ],
              ),
            );
          },
          error: (error, stack) {
            print('❌ 通知読み込みエラー: $error');
            print('❌ エラースタック: $stack');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('通知の読み込みに失敗しました'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'エラー詳細: $error',
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      print('🔄 通知プロバイダーを再読み込み');
                      ref.invalidate(userNotificationsProvider(userId));
                    },
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } catch (e, stackTrace) {
      print('❌ _buildNotificationScreenで例外発生: $e');
      print('❌ スタックトレース: $stackTrace');
      return Scaffold(
        appBar: AppBar(title: const Text('通知')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('通知画面の読み込みでエラーが発生しました'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'エラー: $e',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildNotificationsList(BuildContext context, WidgetRef ref, List<AppNotification> notifications) {
    if (notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('通知はありません'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(context, ref, notification);
      },
    );
  }

  Widget _buildNotificationCard(BuildContext context, WidgetRef ref, AppNotification notification) {
    return Card(
      color: notification.isRead ? null : Colors.blue.shade50,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getNotificationColor(notification.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: _getNotificationColor(notification.type),
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: TextStyle(
                color: notification.isRead ? Colors.grey[600] : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              notification.timeAgo,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 既読/未読切り替えボタン
            if (!notification.isRead)
              IconButton(
                icon: const Icon(Icons.mark_email_read, color: Colors.blue),
                onPressed: () => _markAsRead(context, ref, notification.id),
                tooltip: '既読にする',
              ),
            // 削除ボタン
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmDialog(context, ref, notification),
              tooltip: '通知を削除',
            ),
          ],
        ),
        onTap: () => _handleNotificationTap(context, ref, notification),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.comment:
        return Icons.comment;
      case NotificationType.reply:
        return Icons.reply;
      case NotificationType.like:
        return Icons.thumb_up;
      case NotificationType.postApproved:
        return Icons.check_circle;
      case NotificationType.postRejected:
        return Icons.cancel;
      case NotificationType.pinApproved:
        return Icons.push_pin;
      case NotificationType.pinRejected:
        return Icons.push_pin_outlined;
      case NotificationType.system:
        return Icons.info;
      case NotificationType.appUpdate:
        return Icons.system_update;
      case NotificationType.maintenance:
        return Icons.build;
      case NotificationType.important:
        return Icons.priority_high;
      case NotificationType.general:
        return Icons.campaign;
      case NotificationType.feature:
        return Icons.new_releases;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.comment:
        return Colors.blue;
      case NotificationType.reply:
        return Colors.green;
      case NotificationType.like:
        return Colors.red;
      case NotificationType.postApproved:
        return Colors.green;
      case NotificationType.postRejected:
        return Colors.red;
      case NotificationType.pinApproved:
        return Colors.blue;
      case NotificationType.pinRejected:
        return Colors.orange;
      case NotificationType.system:
        return Colors.orange;
      case NotificationType.appUpdate:
        return Colors.purple;
      case NotificationType.maintenance:
        return Colors.amber;
      case NotificationType.important:
        return Colors.red;
      case NotificationType.general:
        return Colors.blue;
      case NotificationType.feature:
        return Colors.teal;
    }
  }

  Future<void> _handleNotificationTap(BuildContext context, WidgetRef ref, AppNotification notification) async {
    // 未読の場合は既読にする
    if (!notification.isRead) {
      await ref.read(notificationNotifierProvider.notifier).markAsRead(notification.id);
    }

    // 関連する投稿に移動
    if (notification.postId != null) {
      _navigateToPost(context, ref, notification.postId!);
    }
  }

  Future<void> _navigateToPost(BuildContext context, WidgetRef ref, String postId) async {
    try {
      // 投稿情報を取得
      final posts = await ref.read(bulletinPostsProvider.future);
      final post = posts.firstWhere((p) => p.id == postId);
      
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BulletinPostDetailScreen(post: post),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('投稿の表示に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(BuildContext context, WidgetRef ref, String notificationId) async {
    try {
      print('📝 通知を既読にします: $notificationId');
      await ref.read(notificationNotifierProvider.notifier).markAsRead(notificationId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('通知を既読にしました'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ 通知既読化エラー: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('既読化に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, AppNotification notification) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('通知を削除'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('この通知を削除しますか？'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getNotificationIcon(notification.type),
                        size: 16,
                        color: _getNotificationColor(notification.type),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notification.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.timeAgo,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteNotification(context, ref, notification.id);
    }
  }

  Future<void> _deleteNotification(BuildContext context, WidgetRef ref, String notificationId) async {
    try {
      print('🗑️ 通知を削除します: $notificationId');
      
      // ローディング表示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('通知を削除中...'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      await ref.read(notificationNotifierProvider.notifier).deleteNotification(notificationId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('通知を削除しました'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ 通知削除エラー: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white),
                    SizedBox(width: 8),
                    Text('通知の削除に失敗しました'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'エラー: $e',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: '再試行',
              textColor: Colors.white,
              onPressed: () => _deleteNotification(context, ref, notificationId),
            ),
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead(BuildContext context, WidgetRef ref, String userId) async {
    try {
      await ref.read(notificationNotifierProvider.notifier).markAllAsRead(userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('全ての通知を既読にしました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _createTestNotification(BuildContext context, WidgetRef ref, String userId) async {
    try {
      print('🧪 テスト通知作成ボタンが押されました - ユーザー: $userId');
      
      // ローディング表示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('テスト通知を作成中...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      await ref.read(createTestNotificationProvider(userId).future);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('テスト通知を作成しました！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ テスト通知作成エラー: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('テスト通知の作成に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleAppBarAction(BuildContext context, WidgetRef ref, String userId, String action) async {
    switch (action) {
      case 'mark_all_read':
        await _markAllAsRead(context, ref, userId);
        break;
      case 'delete_all':
        await _showDeleteAllConfirmDialog(context, ref, userId);
        break;
    }
  }

  Future<void> _showDeleteAllConfirmDialog(BuildContext context, WidgetRef ref, String userId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_sweep, color: Colors.red),
            SizedBox(width: 8),
            Text('全通知を削除'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'すべての通知を削除しますか？',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'この操作は元に戻せません。\n既読・未読を問わず、すべての通知が削除されます。',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('全て削除'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteAllNotifications(context, ref, userId);
    }
  }

  Future<void> _deleteAllNotifications(BuildContext context, WidgetRef ref, String userId) async {
    try {
      print('🗑️ 全通知を削除します: $userId');
      
      // ローディング表示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('全通知を削除中...'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 5),
          ),
        );
      }
      
      await ref.read(deleteAllNotificationsProvider(userId).future);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('全ての通知を削除しました'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ 全通知削除エラー: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white),
                    SizedBox(width: 8),
                    Text('全通知の削除に失敗しました'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'エラー: $e',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: '再試行',
              textColor: Colors.white,
              onPressed: () => _deleteAllNotifications(context, ref, userId),
            ),
          ),
        );
      }
    }
  }
}
