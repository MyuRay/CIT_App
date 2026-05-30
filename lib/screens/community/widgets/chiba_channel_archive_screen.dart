import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/chiba_channel_provider.dart';
import '../../../models/community/chiba_channel_thread.dart';
import 'chiba_channel_thread_screen.dart';
import 'thread_card.dart';

/// 1ヶ月以上レスがないスレッドの一覧
class ChibaChannelArchiveScreen extends ConsumerWidget {
  const ChibaChannelArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final feedAsync = ref.watch(chibaChannelFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('格納庫'),
      ),
      body: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('読み込みに失敗しました: $error'),
        ),
        data: (feed) {
          final archived = feed.archivedThreads;
          if (archived.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '格納庫に入っているスレッドはありません。\n'
                  '1ヶ月間レスがないスレッドがここに表示されます。',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.65),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    '最終レスから1ヶ月以上経過したスレッドです。'
                    '新しくレスが付くと一覧に戻ります。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.45,
                      color: colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...archived.map(
                (thread) => ThreadCard(
                  thread: thread,
                  showArchivedBadge: true,
                  onTap: () => _openThread(context, thread),
                ),
              ),
            ],
          );
        },
      ),
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
