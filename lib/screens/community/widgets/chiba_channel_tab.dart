import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/chiba_channel_provider.dart';
import '../../../models/community/chiba_channel_thread.dart';
import 'chiba_channel_create_thread_sheet.dart';
import 'chiba_channel_thread_screen.dart';
import 'thread_card.dart';

class ChibaChannelTab extends ConsumerWidget {
  const ChibaChannelTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final feedAsync = ref.watch(chibaChannelFeedProvider);
    final sortKey = ref.watch(chibaChannelThreadSortKeyProvider);
    final sortAscending = ref.watch(chibaChannelThreadSortAscendingProvider);

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(chibaChannelThreadsProvider);
            await ref.read(chibaChannelThreadsProvider.future);
          },
          child: feedAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                Text('読み込みに失敗しました: $error'),
              ],
            ),
            data: (feed) {
              final hasAnyActive =
                  feed.hotThreads.isNotEmpty || feed.activeThreads.isNotEmpty;

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                children: [
                  if (feed.hotThreads.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'ホットスレッド',
                      subtitle:
                          '24時間以内にレスがあったスレ (${feed.hotThreads.length})',
                    ),
                    const SizedBox(height: 10),
                    ...feed.hotThreads.map(
                      (thread) => ThreadCard(
                        thread: thread,
                        onTap: () => _openThread(context, thread),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _ThreadListSectionHeader(
                    threadCount: feed.activeThreads.length,
                    sortKey: sortKey,
                    sortAscending: sortAscending,
                    showSort: hasAnyActive && feed.activeThreads.isNotEmpty,
                    onSortKeyChanged: (key) {
                      ref.read(chibaChannelThreadSortKeyProvider.notifier).state =
                          key;
                    },
                    onSortDirectionToggle: () {
                      ref
                          .read(chibaChannelThreadSortAscendingProvider.notifier)
                          .state = !sortAscending;
                    },
                  ),
                  const SizedBox(height: 10),
                  if (!hasAnyActive)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'まだスレッドがありません。最初のスレを作成してみましょう。',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else if (feed.activeThreads.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'ホットスレッド以外のスレッドはありません。',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    )
                  else
                    ...feed.activeThreads.map(
                      (thread) => ThreadCard(
                        thread: thread,
                        onTap: () => _openThread(context, thread),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: SafeArea(
            child: FilledButton.icon(
              onPressed: () => ChibaChannelCreateThreadSheet.show(context),
              icon: const Icon(Icons.add),
              label: const Text('スレを作成'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openThread(BuildContext context, ChibaChannelThread thread) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ChibaChannelThreadScreen(thread: thread),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E7D32),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ],
    );
  }
}

class _ThreadListSectionHeader extends StatelessWidget {
  const _ThreadListSectionHeader({
    required this.threadCount,
    required this.sortKey,
    required this.sortAscending,
    required this.showSort,
    required this.onSortKeyChanged,
    required this.onSortDirectionToggle,
  });

  final int threadCount;
  final ChibaChannelThreadSortKey sortKey;
  final bool sortAscending;
  final bool showSort;
  final ValueChanged<ChibaChannelThreadSortKey> onSortKeyChanged;
  final VoidCallback onSortDirectionToggle;

  String get _directionLabel => sortAscending ? '昇順' : '降順';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'スレッド一覧',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              if (threadCount > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '${sortKey.displayName} ($_directionLabel) ($threadCount)',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ],
          ),
        ),
        if (showSort)
          PopupMenuButton<Object>(
            tooltip: '並び替え',
            onSelected: (value) {
              if (value == 'dir') {
                onSortDirectionToggle();
              } else if (value is ChibaChannelThreadSortKey) {
                onSortKeyChanged(value);
              }
            },
            itemBuilder: (context) => [
              ...ChibaChannelThreadSortKey.values.map(
                (key) => CheckedPopupMenuItem<Object>(
                  value: key,
                  checked: sortKey == key,
                  child: Text(key.displayName),
                ),
              ),
              PopupMenuItem<Object>(
                value: 'dir',
                child: Row(
                  children: [
                    Icon(
                      sortAscending ? Icons.north : Icons.south,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(_directionLabel),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sort, size: 18, color: muted),
                  const SizedBox(width: 4),
                  Text(
                    sortKey.displayName,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                  Icon(Icons.arrow_drop_down, color: muted),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
