import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/cwitter_provider.dart';
import '../../../core/providers/schedule_provider.dart';
import '../../../models/community/cwitter_ranking_entry.dart';
import 'cwitter_avatar.dart';
import 'cwitter_handle_text.dart';
import 'cwitter_profile_screen.dart';

class CwitterRankingScreen extends ConsumerStatefulWidget {
  const CwitterRankingScreen({super.key});

  @override
  ConsumerState<CwitterRankingScreen> createState() =>
      _CwitterRankingScreenState();
}

class _CwitterRankingScreenState extends ConsumerState<CwitterRankingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  CwitterRankingPeriod _period = CwitterRankingPeriod.allTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: CwitterRankingKind.values.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(cwitterRankingsProvider);
    await ref.read(cwitterRankingsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final boardAsync = ref.watch(cwitterRankingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ランキング'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF4CAF50),
          labelColor: const Color(0xFF2E7D32),
          unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
          tabs: CwitterRankingKind.values
              .map((kind) => Tab(text: kind.label))
              .toList(),
        ),
      ),
      body: boardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('読み込みに失敗しました: $error'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _refresh,
                  child: const Text('再読み込み'),
                ),
              ],
            ),
          ),
        ),
        data: (board) {
          final rankings = board.forPeriod(_period);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SegmentedButton<CwitterRankingPeriod>(
                  segments: CwitterRankingPeriod.values
                      .map(
                        (period) => ButtonSegment(
                          value: period,
                          label: Text(
                            period == CwitterRankingPeriod.monthly
                                ? '${board.monthLabel}${period.label}'
                                : period.label,
                          ),
                        ),
                      )
                      .toList(),
                  selected: {_period},
                  onSelectionChanged: (selection) {
                    setState(() => _period = selection.first);
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: CwitterRankingKind.values
                      .map(
                        (kind) => _RankingListView(
                          period: _period,
                          kind: kind,
                          entries: rankings.entriesFor(kind),
                          onRefresh: _refresh,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RankingListView extends ConsumerWidget {
  const _RankingListView({
    required this.period,
    required this.kind,
    required this.entries,
    required this.onRefresh,
  });

  final CwitterRankingPeriod period;
  final CwitterRankingKind kind;
  final List<CwitterRankingEntry> entries;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUid = ref.watch(currentUserIdProvider);

    if (entries.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.35,
              child: Center(
                child: Text(
                  'まだランキングデータがありません',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: entries.length + 1,
        separatorBuilder: (_, index) =>
            index == 0 ? const SizedBox(height: 10) : const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Text(
              kind.noteFor(period),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            );
          }

          final entry = entries[index - 1];
          return _RankingTile(
            entry: entry,
            kind: kind,
            currentUid: currentUid,
          );
        },
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  const _RankingTile({
    required this.entry,
    required this.kind,
    required this.currentUid,
  });

  final CwitterRankingEntry entry;
  final CwitterRankingKind kind;
  final String? currentUid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = entry.user;
    final isSelf = currentUid != null && currentUid == user.authorId;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isSelf) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CwitterProfileScreen(),
              ),
            );
            return;
          }

          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CwitterProfileScreen(user: user.toProfileUser()),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _RankBadge(rank: entry.rank),
              const SizedBox(width: 12),
              CwitterAvatar(
                authorId: user.authorId,
                displayName: user.displayName,
                cwitterId: user.cwitterId,
                profileImageUrl: user.profileImageUrl,
                radius: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    CwitterHandleText(
                      cwitterId: user.cwitterId,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                kind.formatValue(entry.value),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color background;
    Color foreground;
    if (rank == 1) {
      background = const Color(0xFFFFD54F);
      foreground = const Color(0xFF5D4037);
    } else if (rank == 2) {
      background = const Color(0xFFE0E0E0);
      foreground = const Color(0xFF424242);
    } else if (rank == 3) {
      background = const Color(0xFFFFCC80);
      foreground = const Color(0xFF5D4037);
    } else {
      background = const Color(0xFF4CAF50).withValues(alpha: 0.12);
      foreground = const Color(0xFF2E7D32);
    }

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rank',
        style: theme.textTheme.labelLarge?.copyWith(
          color: foreground,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
