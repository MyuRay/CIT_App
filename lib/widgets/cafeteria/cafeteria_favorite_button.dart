import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/cafeteria_favorite_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/cafeteria/cafeteria_favorite_target.dart';

class CafeteriaFavoriteButton extends ConsumerWidget {
  const CafeteriaFavoriteButton({
    super.key,
    required this.target,
    this.compact = false,
  });
  final CafeteriaFavoriteTarget target;
  final bool compact;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(cafeteriaFavoriteUserIdProvider);
    final favorite = ref.watch(cafeteriaFavoriteStateProvider(target));
    final mutation = ref.watch(cafeteriaFavoriteMutationProvider(target));
    final enabled = favorite.asData?.value ?? false;
    final busy = mutation.isLoading;
    final color =
        enabled
            ? AppColors.accent(context, Colors.pink)
            : Theme.of(context).colorScheme.onSurfaceVariant;
    return IconButton(
      // Keep the count inside the heart's tap target, not in an extra row
      // below the button that increases every menu card's height.
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.all(4),
      ),
      tooltip:
          uid == null
              ? 'お気に入りにはログインが必要です'
              : enabled
              ? 'お気に入りを解除'
              : 'お気に入りに追加',
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          busy
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : Icon(
                enabled ? Icons.favorite : Icons.favorite_border,
                color: color,
                size: compact ? 22 : 26,
              ),
          const SizedBox(height: 1),
          CafeteriaFavoriteCount(target: target, compact: compact),
        ],
      ),
      onPressed:
          uid == null || busy || favorite.isLoading
              ? null
              : () async {
                if (favorite.hasError) {
                  ref.invalidate(userCafeteriaFavoritesProvider);
                  return;
                }
                try {
                  await ref
                      .read(cafeteriaFavoriteMutationProvider(target).notifier)
                      .setEnabled(!enabled);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          enabled ? 'お気に入りを解除しました' : 'お気に入りに追加しました',
                        ),
                      ),
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('変更できませんでした。通信状態を確認して再試行してください。'),
                      ),
                    );
                  }
                }
              },
    );
  }
}

class CafeteriaFavoriteCount extends ConsumerWidget {
  const CafeteriaFavoriteCount({
    super.key,
    required this.target,
    this.compact = false,
  });
  final CafeteriaFavoriteTarget target;
  final bool compact;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cafeteriaFavoriteCountProvider(target));
    final text = count.when(
      data: (value) => value == null ? '集計待ち' : '$value人',
      loading: () => '…',
      error: (_, __) => '取得失敗',
    );
    return Tooltip(
      message:
          count.hasError
              ? '人数を再取得'
              : target.type == 'cafeteria'
              ? 'この食堂をお気に入りにしている人数'
              : 'このメニューをお気に入りにしている人数',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap:
            count.hasError
                ? () => ref.invalidate(cafeteriaFavoriteCountProvider(target))
                : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              height: 1.1,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
