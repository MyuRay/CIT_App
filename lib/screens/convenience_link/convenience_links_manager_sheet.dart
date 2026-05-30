import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/convenience_link_provider.dart';
import '../../models/convenience_link/convenience_link_model.dart';
import 'convenience_link_edit_screen.dart';

/// 便利リンク管理ボトムシート（並び替えはローカル状態で即時反映）
class ConvenienceLinksManagerSheet extends ConsumerStatefulWidget {
  const ConvenienceLinksManagerSheet({
    super.key,
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  ConsumerState<ConvenienceLinksManagerSheet> createState() =>
      _ConvenienceLinksManagerSheetState();
}

class _ConvenienceLinksManagerSheetState
    extends ConsumerState<ConvenienceLinksManagerSheet> {
  List<ConvenienceLink> _displayLinks = [];
  bool _initialized = false;
  bool _isPersistingReorder = false;

  void _syncFromProvider(List<ConvenienceLink> links) {
    if (_isPersistingReorder) return;
    setState(() {
      _displayLinks = List<ConvenienceLink>.from(links);
      _initialized = true;
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    final reordered = List<ConvenienceLink>.from(_displayLinks);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    // ReorderableListView は onReorder 内の同期的なリスト更新を要求する
    setState(() {
      _displayLinks = reordered;
      _isPersistingReorder = true;
    });

    _persistReorder(reordered);
  }

  Future<void> _persistReorder(List<ConvenienceLink> reordered) async {
    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser == null || currentUser.uid.isEmpty) {
      if (mounted) setState(() => _isPersistingReorder = false);
      return;
    }

    try {
      await ref
          .read(
            convenienceLinkProvider((
              userId: currentUser.uid,
              userEmail: currentUser.email,
            )).notifier,
          )
          .reorderLinks(reordered);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('並び替えに失敗しました: $e')),
        );
        // 失敗時はプロバイダーから再同期
        final linksAsync = ref.read(currentUserConvenienceLinksProvider);
        linksAsync.whenData(_syncFromProvider);
      }
    } finally {
      if (mounted) {
        setState(() => _isPersistingReorder = false);
      }
    }
  }

  ({String userId, String? userEmail})? get _userParams {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null || user.uid.isEmpty) return null;
    return (userId: user.uid, userEmail: user.email);
  }

  void _invalidateLinkProviders() {
    final params = _userParams;
    if (params == null) return;
    ref.invalidate(
      convenienceLinkProvider((
        userId: params.userId,
        userEmail: params.userEmail,
      )),
    );
    ref.invalidate(currentUserConvenienceLinksProvider);
    ref.invalidate(enabledConvenienceLinksProvider);
  }

  Future<void> _addNewLink() async {
    final params = _userParams;
    if (params == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ConvenienceLinkEditScreen(userId: params.userId),
      ),
    );

    if (result == true) _invalidateLinkProviders();
  }

  Future<void> _editLink(ConvenienceLink link) async {
    final params = _userParams;
    if (params == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ConvenienceLinkEditScreen(
          initialLink: link,
          userId: params.userId,
        ),
      ),
    );

    if (result == true) _invalidateLinkProviders();
  }

  Future<void> _toggleLinkEnabled(String linkId) async {
    final params = _userParams;
    if (params == null) return;

    try {
      await ref
          .read(
            convenienceLinkProvider((
              userId: params.userId,
              userEmail: params.userEmail,
            )).notifier,
          )
          .toggleLinkEnabled(linkId);
      _invalidateLinkProviders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('設定の変更に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('デフォルトにリセット'),
        content: const Text(
          'すべてのリンクをデフォルトの状態にリセットしますか？\nカスタムリンクは削除されます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('リセット'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final params = _userParams;
    if (params == null) return;

    try {
      await ref
          .read(
            convenienceLinkProvider((
              userId: params.userId,
              userEmail: params.userEmail,
            )).notifier,
          )
          .resetToDefaults();
      _invalidateLinkProviders();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('デフォルトにリセットしました'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('リセットに失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<ConvenienceLink>>>(
      currentUserConvenienceLinksProvider,
      (previous, next) {
        next.whenData(_syncFromProvider);
      },
    );

    final linksAsync = ref.watch(currentUserConvenienceLinksProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.link_outlined,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text('リンク管理', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                onPressed: _resetToDefaults,
                icon: const Icon(Icons.restore),
                tooltip: 'デフォルトにリセット',
              ),
              IconButton(
                onPressed: _addNewLink,
                icon: const Icon(Icons.add),
                tooltip: '新しいリンクを追加',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: linksAsync.when(
              data: (links) {
                if (!_initialized && links.isNotEmpty) {
                  _displayLinks = List<ConvenienceLink>.from(links);
                  _initialized = true;
                }

                if (links.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.link_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'リンクがありません',
                          style: TextStyle(
                            fontSize: 18,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _addNewLink,
                          icon: const Icon(Icons.add),
                          label: const Text('最初のリンクを追加'),
                        ),
                      ],
                    ),
                  );
                }

                final listLinks =
                    _initialized ? _displayLinks : List<ConvenienceLink>.from(links);

                return ReorderableListView.builder(
                  scrollController: widget.scrollController,
                  itemCount: listLinks.length,
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      elevation: 6,
                      color: Colors.transparent,
                      shadowColor: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                      child: child,
                    );
                  },
                  onReorder: _onReorder,
                  itemBuilder: (context, index) {
                    final link = listLinks[index];
                    return Card(
                      key: ValueKey('link_${link.id}'),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: LinkColors.getColor(link.color),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            LinkIcons.getIcon(link.iconName),
                            color: Theme.of(context).colorScheme.surface,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          link.title,
                          style: TextStyle(
                            decoration: link.isEnabled
                                ? null
                                : TextDecoration.lineThrough,
                            color: link.isEnabled
                                ? null
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                        ),
                        subtitle: Text(
                          Uri.parse(link.url).host,
                          style: TextStyle(
                            color: link.isEnabled
                                ? Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: link.isEnabled,
                              onChanged: (_) => _toggleLinkEnabled(link.id),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            IconButton(
                              onPressed: () => _editLink(link),
                              icon: const Icon(Icons.edit),
                              iconSize: 20,
                              tooltip: '編集',
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(Icons.drag_handle, size: 22),
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _editLink(link),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text('エラーが発生しました: $error'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
