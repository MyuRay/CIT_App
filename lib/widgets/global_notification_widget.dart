import '../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/notification/notification_model.dart';
import '../core/providers/global_notification_provider.dart';
import '../screens/notification/global_notification_list_screen.dart';

class GlobalNotificationWidget extends ConsumerWidget {
  const GlobalNotificationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(globalNotificationsProvider);
    final unviewedCount = ref.watch(unviewedNotificationCountProvider);

    return notificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return const SizedBox.shrink(); // 通知がない場合は非表示
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(
                      Icons.campaign,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'お知らせ',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (unviewedCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unviewedCount件の新着',
                          style: TextStyle(
 color: Theme.of(context).colorScheme.onError,
 fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    TextButton(
                      onPressed: () => _showAllNotifications(context),
                      child: const Text('すべて見る'),
                    ),
                  ],
                ),
              ),

              // 通知リスト（最大3件）
              ...notifications
                  .take(3)
                  .map(
                    (notification) =>
                        _buildNotificationTile(context, ref, notification),
                  ),

              if (notifications.length > 3)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () => _showAllNotifications(context),
                      icon: const Icon(Icons.more_horiz),
                      label: Text('他 ${notifications.length - 3}件のお知らせ'),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading:
          () => const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      error: (error, _) => const SizedBox.shrink(), // エラー時は非表示
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    WidgetRef ref,
    GlobalNotification notification,
  ) {
    final bool isImportant = [
      NotificationType.appUpdate,
      NotificationType.important,
      NotificationType.maintenance,
    ].contains(notification.type);

    return InkWell(
      onTap: () => _handleNotificationTap(context, ref, notification),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 通知アイコン
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getNotificationColor(
                    notification.type,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getNotificationColor(
                      notification.type,
                    ).withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    notification.emoji,
                    style: const TextStyle(fontSize: 20),
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
                    Column(
 crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isImportant)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getNotificationColor(notification.type),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              notification.type.displayName,
                              style: TextStyle(
 color: AppColors.onColor(_getNotificationColor(notification.type)),
 fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Padding(
 padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            notification.title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // メッセージ
                    Text(
                      notification.message,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // アプリアップデートの場合はバージョン表示
                    if (notification.type == NotificationType.appUpdate &&
                        notification.version != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'v${notification.version!}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // 日付
                    Text(
                      _formatDate(notification.createdAt),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),

              // 重要通知の場合は矢印アイコン
              if (isImportant)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    } else {
      return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    GlobalNotification notification,
  ) {
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

  void _showAppUpdateDialog(
    BuildContext context,
    GlobalNotification notification,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                 Text(
                  'App Store または Google Play Store からアップデートしてください。',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                  // ストアページを開く処理は実際のストアURLが必要
                  _showComingSoonSnackBar(context, 'ストア連携');
                },
                icon: const Icon(Icons.system_update),
                label: const Text('アップデート'),
              ),
            ],
          ),
    );
  }

  void _showNotificationDialog(
    BuildContext context,
    GlobalNotification notification,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Text(notification.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(child: Text(notification.title)),
              ],
            ),
            content: SingleChildScrollView(child: Text(notification.message)),
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
            backgroundColor: AppColors.snackBarSurface(context, Colors.red),
          ),
        );
      }
    }
  }

  void _showAllNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GlobalNotificationListScreen(),
      ),
    );
  }

  void _showComingSoonSnackBar(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature機能は近日実装予定です'),
        backgroundColor: AppColors.snackBarSurface(context, Colors.orange),
      ),
    );
  }
}

// 拡張機能: NotificationTypeの表示名とemoji
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

  String get emoji {
    switch (this) {
      case NotificationType.appUpdate:
        return '🔄';
      case NotificationType.maintenance:
        return '🔧';
      case NotificationType.important:
        return '⚠️';
      case NotificationType.general:
        return '📢';
      case NotificationType.feature:
        return '✨';
      default:
        return '📱';
    }
  }
}
