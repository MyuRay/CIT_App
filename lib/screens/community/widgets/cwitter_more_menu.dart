import 'package:flutter/material.dart';

/// Cweet・返信・プロフィールの ⋮ メニュー
class CwitterMoreMenu extends StatelessWidget {
  const CwitterMoreMenu({
    super.key,
    required this.isOwner,
    this.onDeletePost,
    this.onDeleteReply,
    this.onReport,
    this.onBlock,
    this.iconSize = 20,
    this.constraints = const BoxConstraints(minWidth: 32, minHeight: 32),
  });

  final bool isOwner;
  final Future<void> Function()? onDeletePost;
  final Future<void> Function()? onDeleteReply;
  final VoidCallback? onReport;
  final VoidCallback? onBlock;
  final double iconSize;
  final BoxConstraints constraints;

  bool get _hasDelete => onDeletePost != null || onDeleteReply != null;
  bool get _hasReport => onReport != null;
  bool get _hasBlock => onBlock != null;

  @override
  Widget build(BuildContext context) {
    if (!_hasDelete && !_hasReport && !_hasBlock) {
      return const SizedBox.shrink();
    }

    final iconColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);

    return SizedBox(
      width: constraints.minWidth,
      height: constraints.minHeight,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        splashRadius: 18,
        iconSize: iconSize,
        constraints: constraints,
        icon: Icon(Icons.more_vert, size: iconSize, color: iconColor),
        onSelected: (value) async {
          if (value == 'report') {
            onReport?.call();
            return;
          }
          if (value == 'block') {
            onBlock?.call();
            return;
          }
          if (value != 'delete') return;

          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('削除の確認'),
              content: Text(
                onDeleteReply != null
                    ? 'この返信を削除しますか？'
                    : 'このCweetを削除しますか？\n返信もすべて削除されます。',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('削除'),
                ),
              ],
            ),
          );
          if (confirmed != true || !context.mounted) return;

          try {
            if (onDeleteReply != null) {
              await onDeleteReply!();
            } else if (onDeletePost != null) {
              await onDeletePost!();
            }
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('削除しました')),
            );
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('削除に失敗しました: $e')),
            );
          }
        },
        itemBuilder: (context) {
          final items = <PopupMenuEntry<String>>[];
          if (_hasReport) {
            items.add(
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('通報'),
                  ],
                ),
              ),
            );
          }
          if (_hasBlock) {
            items.add(
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, size: 20),
                    SizedBox(width: 8),
                    Text('ブロック'),
                  ],
                ),
              ),
            );
          }
          if (_hasDelete) {
            items.add(
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('削除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            );
          }
          return items;
        },
      ),
    );
  }
}
