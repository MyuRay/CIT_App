import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/providers/global_notification_provider.dart';
import 'notification_list_screen.dart';
import 'global_notification_list_screen.dart';

class UnifiedNotificationScreen extends ConsumerStatefulWidget {
  const UnifiedNotificationScreen({super.key});

  @override
  ConsumerState<UnifiedNotificationScreen> createState() => _UnifiedNotificationScreenState();
}

class _UnifiedNotificationScreenState extends ConsumerState<UnifiedNotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
                tooltip: '全て既読',
                icon: const Icon(Icons.done_all),
                onPressed: () async {
                  try {
                    if (_tabController.index == 0) {
                      await ref.read(notificationActionsProvider).markAllAsViewed();
                    } else {
                      await ref.read(notificationNotifierProvider.notifier).markAllAsRead(user.uid);
                    }
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
                        SnackBar(content: Text('操作に失敗しました: $e'), backgroundColor: Colors.red),
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
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('通知')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const GlobalNotificationListScreen(),
    );
  }
}
