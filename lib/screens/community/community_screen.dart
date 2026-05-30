import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/cwitter_provider.dart';
import 'widgets/chiba_channel_archive_screen.dart';
import 'widgets/chiba_channel_info_dialog.dart';
import 'widgets/chiba_channel_tab.dart';
import 'widgets/cwitter_profile_screen.dart';
import 'widgets/cwitter_ranking_screen.dart';
import 'widgets/cwitter_search_screen.dart';
import 'widgets/cwitter_tab.dart';

/// 交流タブのメイン画面（Cwitter / ちばちゃんねる）
class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tabController.index == 0) {
        markCwitterFeedSeen(ref);
      }
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && _tabController.index == 0) {
      markCwitterFeedSeen(ref);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasNewCwitter = ref.watch(hasNewCwitterPostsProvider);
    final showCwitterTabNew = hasNewCwitter && _tabController.index != 0;
    final hasCwitterId = ref.watch(hasCwitterIdProvider);
    final onCwitterTab = _tabController.index == 0;
    final onChibaChannelTab = _tabController.index == 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('交流'),
        actions: [
          if (onCwitterTab) ...[
            IconButton(
              tooltip: 'ランキング',
              icon: const Icon(Icons.leaderboard_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CwitterRankingScreen(),
                  ),
                );
              },
            ),
            if (hasCwitterId) ...[
              IconButton(
                tooltip: '検索',
                icon: const Icon(Icons.search),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CwitterSearchScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'マイページ',
                icon: const Icon(Icons.person_outline),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CwitterProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ],
          if (onChibaChannelTab) ...[
            IconButton(
              tooltip: 'ご利用について',
              icon: const Icon(Icons.info_outline),
              onPressed: () => showChibaChannelInfoDialog(context),
            ),
            IconButton(
              tooltip: '格納庫',
              icon: const Icon(Icons.inventory_2_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ChibaChannelArchiveScreen(),
                  ),
                );
              },
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF4CAF50),
          labelColor: const Color(0xFF2E7D32),
          unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
          tabs: [
            Tab(
              child: _TabLabel(
                label: 'Cwitter',
                showNew: showCwitterTabNew,
              ),
            ),
            const Tab(text: 'ちばちゃんねる'),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: TabBarView(
          controller: _tabController,
          children: [
            CwitterTab(isActiveTab: onCwitterTab),
            const ChibaChannelTab(),
          ],
        ),
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.showNew,
  });

  final String label;
  final bool showNew;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (showNew) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'New Cweet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
