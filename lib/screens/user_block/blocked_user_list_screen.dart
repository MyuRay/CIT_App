import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/users/blocked_user_model.dart';
import '../../core/providers/user_block_provider.dart';

class BlockedUserListScreen extends ConsumerWidget {
  const BlockedUserListScreen({super.key});

  Future<void> _unblockUser(
    BuildContext context,
    WidgetRef ref,
    BlockedUser blockedUser,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ブロック解除の確認'),
            content: Text('${blockedUser.blockedUserName}のブロックを解除しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('解除する'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(userBlockProvider.notifier)
          .unblockUser(blockedUserId: blockedUser.blockedUserId);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${blockedUser.blockedUserName}のブロックを解除しました'),
          backgroundColor: AppColors.snackBarSurface(context, Colors.green),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ブロック解除に失敗しました: ${e.toString()}'),
          backgroundColor: AppColors.snackBarSurface(context, Colors.red),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedUsersAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ブロック済みユーザー'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: blockedUsersAsync.when(
        data: (blockedUsers) {
          if (blockedUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 80, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    'ブロック済みユーザーはいません',
                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // 情報カード
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.tintedSurface(context, Colors.blue),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.accent(context, Colors.blue[700])),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ブロックしたユーザーの投稿やコメントは表示されません',
                        style: TextStyle(fontSize: 13, color: AppColors.accent(context, Colors.blue[900])),
                      ),
                    ),
                  ],
                ),
              ),

              // ユーザー一覧
              Expanded(
                child: ListView.separated(
                  itemCount: blockedUsers.length,
                  separatorBuilder:
                      (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final blockedUser = blockedUsers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        blockedUser.blockedUserName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '理由: ${blockedUser.reason.displayName}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (blockedUser.notes != null &&
                              blockedUser.notes!.isNotEmpty)
                            Text(
                              'メモ: ${blockedUser.notes}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 4),
                          Text(
                            'ブロック日時: ${blockedUser.timeAgo}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      trailing: TextButton.icon(
                        onPressed:
                            () => _unblockUser(context, ref, blockedUser),
                        icon: const Icon(Icons.block, size: 18),
                        label: const Text('解除'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                      isThreeLine: true,
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: AppColors.accent(context, Colors.red[300])),
                  const SizedBox(height: 16),
                  Text(
                    'データの取得に失敗しました',
                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(blockedUsersProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('再読み込み'),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
