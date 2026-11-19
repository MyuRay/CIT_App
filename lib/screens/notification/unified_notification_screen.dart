import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/providers/global_notification_provider.dart';
import 'notification_list_screen.dart';
import 'global_notification_list_screen.dart';
import 'notification_settings_screen.dart';

class UnifiedNotificationScreen extends ConsumerStatefulWidget {
  const UnifiedNotificationScreen({super.key, this.initialPersonalTab = false});
  final bool initialPersonalTab;

  @override
  ConsumerState<UnifiedNotificationScreen> createState() =>
      _UnifiedNotificationScreenState();
}

class _UnifiedNotificationScreenState
    extends ConsumerState<UnifiedNotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this,
      initialIndex: widget.initialPersonalTab ? 1 : 0);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          // ログインしていない場合はグローバル通知のみ表示
          return const GlobalNotificationListScreen();
        }

        // ログイン済みの場合はタブで分けて表示
        return Scaffold(
          appBar: AppBar(
            title: const Text('通知'),
            actions: [
              IconButton(
                tooltip: 'プッシュ通知設定',
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NotificationSettingsScreen(),
                    ),
                  );
                },
              ),
              if (_tabController.index == 1)
                IconButton(tooltip: '個人通知を全削除', icon: const Icon(Icons.delete_sweep_outlined),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
                      title: const Text('個人通知をすべて削除しますか？'),
                      content: const Text('削除した通知は元に戻せません。'),
                      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('キャンセル')),
                        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('全削除'))],
                    ));
                    if (confirmed != true || !context.mounted) return;
                    try {
                      ref.invalidate(deleteAllNotificationsProvider(user.uid));
                      await ref.read(deleteAllNotificationsProvider(user.uid).future);
                    } catch (_) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('通知を削除できませんでした。もう一度お試しください')));
                    }
                  }),
              IconButton(
                tooltip: '全て既読',
                icon: const Icon(Icons.done_all),
                onPressed: () async {
                  try {
                    if (_tabController.index == 0) {
                      await ref
                          .read(notificationActionsProvider)
                          .markAllAsViewed();
                    } else {
                      await ref
                          .read(notificationNotifierProvider.notifier)
                          .markAllAsRead(user.uid);
                    }
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
                        SnackBar(
                          content: Text('操作に失敗しました: $e'),
                          backgroundColor: AppColors.snackBarSurface(context, Colors.red),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'お知らせ', icon: Icon(Icons.campaign)),
                Tab(text: '個人通知', icon: Icon(Icons.notifications)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: const [
              GlobalNotificationListScreen(showAppBar: false),
              NotificationListScreen(showAppBar: false),
            ],
          ),
        );
      },
      loading:
          () => Scaffold(
            appBar: AppBar(title: const Text('通知')),
            body: const Center(child: CircularProgressIndicator()),
          ),
      error: (_, __) => const GlobalNotificationListScreen(),
    );
  }
}
