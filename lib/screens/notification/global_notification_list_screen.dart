import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/notification/notification_model.dart';
import '../../core/providers/global_notification_provider.dart';

class GlobalNotificationListScreen extends ConsumerWidget {
  final bool showAppBar;
  
  const GlobalNotificationListScreen({
    super.key, 
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(globalNotificationsProvider);
    final unviewedCount = ref.watch(unviewedNotificationCountProvider);

    return Scaffold(
      appBar: showAppBar ? AppBar(
        title: const Text('お知らせ'),
        actions: [
          if (unviewedCount > 0)
            IconButton(
              tooltip: 'すべて既読',
              icon: const Icon(Icons.done_all),
              onPressed: () => _markAllAsViewed(ref),
            ),
        ],
      ) : null,
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'お知らせはありません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(context, ref, notification);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('エラーが発生しました: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(globalNotificationsProvider),
                child: const Text('再読み込み'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, WidgetRef ref, GlobalNotification notification) {
    final bool isImportant = [
      NotificationType.appUpdate,
      NotificationType.important,
      NotificationType.maintenance,
    ].contains(notification.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _handleNotificationTap(context, ref, notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー行
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 通知アイコン
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: _getNotificationColor(notification.type).withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        notification.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // 通知内容
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // タイトルと重要度バッジ
                        Row(
                          children: [
                            if (isImportant)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getNotificationColor(notification.type),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  notification.type.displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                notification.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // メッセージ
                        Text(
                          notification.message,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        
                        // アプリアップデートの場合はバージョン表示
                        if (notification.type == NotificationType.appUpdate && 
                            notification.version != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'v${notification.version!}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 12),
                        
                        // フッター（日付と状態）
                        Row(
                          children: [
                            Text(
                              _formatDate(notification.createdAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            if (notification.expiresAt != null) ...[
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${notification.expiresAt!.month}/${notification.expiresAt!.day}まで',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // 矢印アイコン（重要通知のみ）
                  if (isImportant || notification.url != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.appUpdate:
        return Colors.blue;
      case NotificationType.maintenance:
        return Colors.orange;
      case NotificationType.important:
        return Colors.red;
      case NotificationType.feature:
        return Colors.purple;
      case NotificationType.general:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    
    if (targetDate == today) {
      return '今日 ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (targetDate == today.subtract(const Duration(days: 1))) {
      return '昨日 ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(date).inDays < 7) {
      final weekdays = ['', '月', '火', '水', '木', '金', '土', '日'];
      return '${weekdays[date.weekday]}曜日 ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  void _handleNotificationTap(BuildContext context, WidgetRef ref, GlobalNotification notification) {
    // 通知を既読にマーク
    ref.read(notificationActionsProvider).markAsViewed(notification.id);

    // 通知タイプに応じた処理
    switch (notification.type) {
      case NotificationType.appUpdate:
        _showAppUpdateDialog(context, notification);
        break;
      case NotificationType.feature:
        if (notification.url != null) {
          _openUrl(context, notification.url!);
        } else {
          _showNotificationDialog(context, notification);
        }
        break;
      case NotificationType.maintenance:
      case NotificationType.important:
      case NotificationType.general:
        _showNotificationDialog(context, notification);
        break;
      default:
        _showNotificationDialog(context, notification);
    }
  }

  void _showAppUpdateDialog(BuildContext context, GlobalNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(notification.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(child: Text(notification.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notification.version != null) ...[
              Text(
                '最新バージョン: ${notification.version!}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(notification.message),
            const SizedBox(height: 16),
            const Text(
              'App Store または Google Play Store からアップデートしてください。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('後で'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ストア連携機能は近日実装予定です'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.system_update),
            label: const Text('アップデート'),
          ),
        ],
      ),
    );
  }

  void _showNotificationDialog(BuildContext context, GlobalNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(notification.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(child: Text(notification.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(notification.message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'URLを開けませんでした';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('リンクを開けませんでした: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _markAllAsViewed(WidgetRef ref) {
    ref.read(notificationActionsProvider).markAllAsViewed();
    ScaffoldMessenger.of(ref.context).showSnackBar(
      const SnackBar(
        content: Text('すべてのお知らせを既読にしました'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// 拡張機能: NotificationTypeの表示名
extension NotificationTypeDisplay on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.appUpdate:
        return 'アップデート';
      case NotificationType.maintenance:
        return 'メンテナンス';
      case NotificationType.important:
        return '重要';
      case NotificationType.general:
        return 'お知らせ';
      case NotificationType.feature:
        return '新機能';
      default:
        return 'その他';
    }
  }
}
