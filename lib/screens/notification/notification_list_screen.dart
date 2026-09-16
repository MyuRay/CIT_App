import '../../widgets/notification/notification_card.dart';
import '../../core/theme/app_colors.dart';
import 'package:cit_app/core/utils/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/notification/notification_model.dart';
import '../../core/providers/notification_provider.dart';
import '../bulletin/bulletin_post_detail_screen.dart';
import '../community/widgets/cwitter_profile_screen.dart';
import '../community/widgets/chiba_channel_thread_screen.dart';
import '../../models/community/cwitter_profile_user.dart';
import '../../models/community/chiba_channel_thread.dart';
import '../../models/bulletin/bulletin_model.dart';
import '../../core/providers/auth_provider.dart';

class NotificationListScreen extends ConsumerWidget {
  final bool showAppBar;

  const NotificationListScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SecureLogger.debug('📱 NotificationListScreen build開始');
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        SecureLogger.debug('👤 認証データ取得: ${user?.uid ?? "null"}');
        if (user == null) {
          SecureLogger.debug('⚠️ ユーザーがログインしていません');
          return Scaffold(
            appBar: showAppBar ? AppBar(title: const Text('通知')) : null,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  SizedBox(height: 16),
                  Text('ログインが必要です'),
                ],
              ),
            ),
          );
        }

        SecureLogger.debug('✅ 通知画面を構築中 - ユーザーID: ${user.uid}');
        return _buildNotificationScreen(context, ref, user.uid);
      },
      loading: () {
        SecureLogger.debug('⏳ 認証データを読み込み中...');
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
        SecureLogger.debug('❌ 認証エラー: $error');
        return Scaffold(
          appBar: showAppBar ? AppBar(title: const Text('通知')) : null,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Icon(Icons.error, size: 64, color: AppColors.accent(context, Colors.red)),
                const SizedBox(height: 16),
                Text('認証エラー: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    SecureLogger.debug('🔄 認証プロバイダーを再読み込み');
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

  Widget _buildNotificationScreen(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    SecureLogger.debug('🔔 _buildNotificationScreen開始 - ユーザーID: $userId');

    try {
      final notificationsAsync = ref.watch(userNotificationsProvider(userId));
      SecureLogger.debug('📋 通知プロバイダーを監視中...');

      return Scaffold(
        appBar:
            showAppBar
                ? AppBar(
                  title: const Text('通知'),
                  actions: [
                    // テスト用ボタン
                    IconButton(
                      icon: const Icon(Icons.add_alert),
                      onPressed:
                          () => _createTestNotification(context, ref, userId),
                      tooltip: 'テスト通知作成',
                    ),
                    IconButton(
                      tooltip: '全て既読',
                      icon: const Icon(Icons.done_all),
                      onPressed: () => _markAllAsRead(context, ref, userId),
                    ),
                  ],
                )
                : null,
        body: notificationsAsync.when(
          data: (notifications) {
            SecureLogger.debug('📋 通知データ受信成功: ${notifications.length}件');
            if (notifications.isNotEmpty) {
              SecureLogger.debug('📝 最初の通知: ${notifications.first.title}');
            }
            return _buildNotificationsList(context, ref, notifications);
          },
          loading: () {
            SecureLogger.debug('⏳ 通知データ読み込み中... (ユーザーID: $userId)');
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
            SecureLogger.debug('❌ 通知読み込みエラー: $error');
            SecureLogger.debug('❌ エラースタック: $stack');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.error, size: 64, color: AppColors.accent(context, Colors.red)),
                  const SizedBox(height: 16),
                  const Text('通知の読み込みに失敗しました'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'エラー詳細: $error',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      SecureLogger.debug('🔄 通知プロバイダーを再読み込み');
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
      SecureLogger.debug('❌ _buildNotificationScreenで例外発生: $e');
      SecureLogger.debug('❌ スタックトレース: $stackTrace');
      return Scaffold(
        appBar: AppBar(title: const Text('通知')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Icon(Icons.error, size: 64, color: AppColors.accent(context, Colors.red)),
              const SizedBox(height: 16),
              const Text('通知画面の読み込みでエラーが発生しました'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'エラー: $e',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildNotificationsList(
    BuildContext context,
    WidgetRef ref,
    List<AppNotification> notifications,
  ) {
    if (notifications.isEmpty) {
      return  Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
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

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    return NotificationCard(
      notification: notification,
      onTap: () => _handleNotificationTap(context, ref, notification),
      onMarkRead: () => _markAsRead(context, ref, notification.id),
      onDelete: () => _showDeleteConfirmDialog(context, ref, notification),
    );
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    // 未読の場合は既読にする
    if (!notification.isRead) {
      await ref
          .read(notificationNotifierProvider.notifier)
          .markAsRead(notification.id);
    }

    final source = notification.data?['source'] as String?;
    if (source == 'cwitter' &&
        (notification.type == NotificationType.follow ||
            notification.data?['type'] == 'follow')) {
      await _navigateToCwitterProfile(context, notification);
      return;
    }

    if (notification.postId == null) return;

    if (source == 'cwitter') {
      if (context.mounted) {
        context.go('/home?tab=community');
      }
      return;
    }

    if (source == 'chiba_channel' && notification.postId != null) {
      await _navigateToChibaChannelThread(context, notification.postId!);
      return;
    }

    _navigateToPost(context, ref, notification.postId!);
  }

  Future<void> _navigateToChibaChannelThread(
    BuildContext context,
    String threadId,
  ) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('chiba_channel_threads')
              .doc(threadId)
              .get();
      if (!doc.exists) {
        if (context.mounted) {
          context.go('/home?tab=community');
        }
        return;
      }

      final thread = ChibaChannelThread.fromFirestore(doc);
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChibaChannelThreadScreen(thread: thread),
        ),
      );
    } catch (_) {
      if (context.mounted) {
        context.go('/home?tab=community');
      }
    }
  }

  Future<void> _navigateToCwitterProfile(
    BuildContext context,
    AppNotification notification,
  ) async {
    final fromUserId = notification.fromUserId;
    if (fromUserId == null || fromUserId.isEmpty) {
      if (context.mounted) {
        context.go('/home?tab=community');
      }
      return;
    }

    final cwitterId =
        notification.data?['fromCwitterId']?.toString().trim() ?? '';
    if (cwitterId.isEmpty) {
      if (context.mounted) {
        context.go('/home?tab=community');
      }
      return;
    }

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => CwitterProfileScreen(
              user: CwitterProfileUser(
                authorId: fromUserId,
                displayName: notification.fromUserName ?? 'Unknown',
                cwitterId: cwitterId,
              ),
            ),
      ),
    );
  }

  Future<void> _navigateToPost(
    BuildContext context,
    WidgetRef ref,
    String postId,
  ) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('bulletin_posts')
              .doc(postId)
              .get();
      if (!doc.exists || doc.data() == null) {
        throw StateError('投稿が見つかりません');
      }
      final post = BulletinPost.fromJson({'id': doc.id, ...doc.data()!});

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
            backgroundColor: AppColors.snackBarSurface(context, Colors.red),
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(
    BuildContext context,
    WidgetRef ref,
    String notificationId,
  ) async {
    try {
      SecureLogger.debug('📝 通知を既読にします: $notificationId');
      await ref
          .read(notificationNotifierProvider.notifier)
          .markAsRead(notificationId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('通知を既読にしました'),
            backgroundColor: AppColors.snackBarSurface(context, Colors.green),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      SecureLogger.debug('❌ 通知既読化エラー: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('既読化に失敗しました: $e'),
            backgroundColor: AppColors.snackBarSurface(context, Colors.red),
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.delete, color: AppColors.accent(context, Colors.red)),
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
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            NotificationCard.iconFor(notification.type),
                            size: 16,
                            color: AppColors.accent(context, NotificationCard.colorFor(notification.type)),
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
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.timeAgo,
                        style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                  foregroundColor: AppColors.onColor(Colors.red),
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

  Future<void> _deleteNotification(
    BuildContext context,
    WidgetRef ref,
    String notificationId,
  ) async {
    try {
      SecureLogger.debug('🗑️ 通知を削除します: $notificationId');

      // ローディング表示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('通知を削除中...'),
              ],
            ),
            backgroundColor: AppColors.snackBarSurface(context, Colors.blue),
            duration: Duration(seconds: 2),
          ),
        );
      }

      await ref
          .read(notificationNotifierProvider.notifier)
          .deleteNotification(notificationId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onInverseSurface),
                SizedBox(width: 8),
                Text('通知を削除しました'),
              ],
            ),
            backgroundColor: AppColors.snackBarSurface(context, Colors.green),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      SecureLogger.debug('❌ 通知削除エラー: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Row(
                  children: [
                    Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onInverseSurface),
                    SizedBox(width: 8),
                    Text('通知の削除に失敗しました'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'エラー: $e',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onInverseSurface),
                ),
              ],
            ),
            backgroundColor: AppColors.snackBarSurface(context, Colors.red),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: '再試行',
              textColor: Theme.of(context).colorScheme.onInverseSurface,
              onPressed:
                  () => _deleteNotification(context, ref, notificationId),
            ),
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    try {
      await ref
          .read(notificationNotifierProvider.notifier)
          .markAllAsRead(userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('全ての通知を既読にしました'),
            backgroundColor: AppColors.snackBarSurface(context, Colors.green),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作に失敗しました: $e'), backgroundColor: AppColors.snackBarSurface(context, Colors.red)),
        );
      }
    }
  }

  Future<void> _createTestNotification(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    try {
      SecureLogger.debug('🧪 テスト通知作成ボタンが押されました - ユーザー: $userId');

      // ローディング表示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('テスト通知を作成中...'),
            backgroundColor: AppColors.snackBarSurface(context, Colors.blue),
            duration: Duration(seconds: 2),
          ),
        );
      }

      await ref.read(createTestNotificationProvider(userId).future);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('テスト通知を作成しました'),
            backgroundColor: AppColors.snackBarSurface(context, Colors.green),
          ),
        );
      }
    } catch (e) {
      SecureLogger.debug('❌ テスト通知作成エラー: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('テスト通知の作成に失敗しました: $e'),
            backgroundColor: AppColors.snackBarSurface(context, Colors.red),
          ),
        );
      }
    }
  }

  Future<void> _handleAppBarAction(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String action,
  ) async {
    switch (action) {
      case 'mark_all_read':
        await _markAllAsRead(context, ref, userId);
        break;
      case 'delete_all':
        await _showDeleteAllConfirmDialog(context, ref, userId);
        break;
    }
  }

  Future<void> _showDeleteAllConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.delete_sweep, color: AppColors.accent(context, Colors.red)),
                SizedBox(width: 8),
                Text('全通知を削除'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 Icon(Icons.warning, size: 48, color: AppColors.accent(context, Colors.orange)),
                const SizedBox(height: 16),
                const Text(
                  'すべての通知を削除しますか？',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'この操作は元に戻せません。\n既読・未読を問わず、すべての通知が削除されます。',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
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
                  foregroundColor: AppColors.onColor(Colors.red),
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

  Future<void> _deleteAllNotifications(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    try {
      SecureLogger.debug('🗑️ 全通知を削除します: $userId');

      // ローディング表示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('全通知を削除中...'),
              ],
            ),
            backgroundColor: AppColors.snackBarSurface(context, Colors.blue),
            duration: Duration(seconds: 5),
          ),
        );
      }

      await ref.read(deleteAllNotificationsProvider(userId).future);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onInverseSurface),
                SizedBox(width: 8),
                Text('全ての通知を削除しました'),
              ],
            ),
            backgroundColor: AppColors.snackBarSurface(context, Colors.green),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      SecureLogger.debug('❌ 全通知削除エラー: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Row(
                  children: [
                    Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onInverseSurface),
                    SizedBox(width: 8),
                    Text('全通知の削除に失敗しました'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'エラー: $e',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onInverseSurface),
                ),
              ],
            ),
            backgroundColor: AppColors.snackBarSurface(context, Colors.red),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: '再試行',
              textColor: Theme.of(context).colorScheme.onInverseSurface,
              onPressed: () => _deleteAllNotifications(context, ref, userId),
            ),
          ),
        );
      }
    }
  }
}
