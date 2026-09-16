import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/bulletin_provider.dart';
import '../../core/providers/filtered_bulletin_provider.dart';
import '../../models/bulletin/bulletin_model.dart';
import '../../widgets/bulletin/bulletin_feed_card.dart';
import 'bulletin_post_detail_screen.dart';
import 'bulletin_post_form_screen.dart';

class BulletinScreen extends ConsumerStatefulWidget {
  const BulletinScreen({super.key});
  @override
  ConsumerState<BulletinScreen> createState() => _BulletinScreenState();
}

class _BulletinScreenState extends ConsumerState<BulletinScreen> {
  String? _selectedCategoryId;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onPostsScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onPostsScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onPostsScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 240) {
      return;
    }
    // A failed next page needs an explicit retry instead of repeated requests.
    if (!ref.read(bulletinFeedHasMoreProvider) ||
        ref.read(bulletinFeedIsLoadingMoreProvider) ||
        ref.read(bulletinFeedErrorProvider) != null ||
        ref
            .read(filteredBulletinPostsByCategoryProvider(_selectedCategoryId))
            .isLoading) {
      return;
    }
    _loadMore();
  }

  Future<void> _loadMore() =>
      ref.read(bulletinFeedProvider.notifier).loadMore();
  Future<void> _refreshBulletinFeed() =>
      ref.read(bulletinFeedProvider.notifier).refresh();

  void _selectCategory(String? id) {
    if (_selectedCategoryId == id) return;
    setState(() => _selectedCategoryId = id);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compactAction =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(14) > 20;
    final posts = ref.watch(
      filteredBulletinPostsByCategoryProvider(_selectedCategoryId),
    );
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        centerTitle: false,
        scrolledUnderElevation: 0,
        title: Text(
          '掲示板',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openGuide,
            icon: const Icon(Icons.info_outline),
            tooltip: '掲示板投稿について',
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 16),
            child:
                compactAction
                    ? IconButton.filled(
                      onPressed: _addPost,
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: '投稿する',
                    )
                    : FilledButton.icon(
                      onPressed: _addPost,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('投稿する'),
                    ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Material(
              color: theme.colorScheme.surface,
              child: SingleChildScrollView(
                key: const ValueKey('bulletin-categories'),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Row(
                  children: [
                    _category(null, 'すべて', Icons.grid_view_rounded),
                    for (final category in BulletinCategories.all) ...[
                      const SizedBox(width: 8),
                      _category(
                        category.id,
                        category.name,
                        bulletinCategoryIcon(category.icon),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final contentWidth = math.min(constraints.maxWidth, 1120.0);
                  final horizontal =
                      (constraints.maxWidth - contentWidth) / 2 + 16;
                  // Keep two columns without reserving empty image/title rows.
                  const columns = 2;
                  return RefreshIndicator(
                    onRefresh: _refreshBulletinFeed,
                    child: CustomScrollView(
                      key: const PageStorageKey('bulletin-feed'),
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: posts.when(
                        data:
                            (items) => _postSlivers(items, horizontal, columns),
                        loading:
                            () => [
                              const SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ],
                        error:
                            (_, __) => [
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _stateMessage(
                                  icon: Icons.cloud_off_outlined,
                                  title: '投稿を読み込めませんでした',
                                  message: '通信状況を確認して、もう一度お試しください。',
                                  action: FilledButton.tonalIcon(
                                    onPressed: _refreshBulletinFeed,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('再読み込み'),
                                  ),
                                ),
                              ),
                            ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _category(String? id, String name, IconData icon) {
    final selected = _selectedCategoryId == id;
    final colors = Theme.of(context).colorScheme;
    return ChoiceChip(
      key: ValueKey('bulletin-category-${id ?? 'all'}'),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => _selectCategory(id),
      avatar: Icon(
        icon,
        size: 17,
        color: selected ? colors.onPrimary : colors.onSurfaceVariant,
      ),
      label: Text(name),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? colors.onPrimary : colors.onSurfaceVariant,
      ),
      selectedColor: colors.primary,
      backgroundColor: colors.surface,
      side: BorderSide(
        color: selected ? colors.primary : colors.outlineVariant,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  List<Widget> _postSlivers(
    List<BulletinPost> posts,
    double horizontal,
    int columns,
  ) {
    final hasMore = ref.watch(bulletinFeedHasMoreProvider);
    final loadingMore = ref.watch(bulletinFeedIsLoadingMoreProvider);
    final pageError = ref.watch(bulletinFeedErrorProvider);
    final category =
        BulletinCategories.all
            .where((item) => item.id == _selectedCategoryId)
            .firstOrNull;
    final theme = Theme.of(context);
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 10),
        sliver: SliverToBoxAdapter(
          child: Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                category == null ? 'すべての投稿' : '${category.name}の投稿',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (posts.isNotEmpty && !posts.any((item) => item.isPinned))
                Text(
                  '新着順',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
      if (posts.isEmpty)
        SliverToBoxAdapter(
          child: _stateMessage(
            icon:
                category == null
                    ? Icons.article_outlined
                    : bulletinCategoryIcon(category.icon),
            title: hasMore ? '投稿がまだ見つかりません' : '投稿がありません',
            message:
                hasMore
                    ? '以前の投稿も確認できます。'
                    : category == null
                    ? '右上のボタンから投稿できます。'
                    : 'このカテゴリにはまだ投稿がありません。',
            action:
                category != null
                    ? OutlinedButton(
                      onPressed: () => _selectCategory(null),
                      child: const Text('すべての投稿を見る'),
                    )
                    : hasMore
                    ? null
                    : FilledButton.icon(
                      onPressed: _addPost,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('投稿する'),
                    ),
          ),
        )
      else
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          sliver: SliverList.builder(
            itemCount: (posts.length / columns).ceil(),
            itemBuilder:
                (context, row) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var column = 0; column < columns; column++) ...[
                        if (column != 0) const SizedBox(width: 12),
                        Expanded(
                          child:
                              row * columns + column < posts.length
                                  ? _postCard(posts[row * columns + column])
                                  : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
          ),
        ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 24),
        sliver: SliverToBoxAdapter(
          child: Center(
            child:
                loadingMore
                    ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    )
                    : hasMore || pageError != null
                    ? Column(
                      children: [
                        if (pageError != null)
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              hasMore
                                  ? '続きの投稿を読み込めませんでした。'
                                  : '投稿の更新を確認できませんでした。',
                            ),
                          ),
                        OutlinedButton.icon(
                          onPressed: hasMore ? _loadMore : _refreshBulletinFeed,
                          icon: Icon(
                            pageError == null
                                ? Icons.expand_more
                                : Icons.refresh,
                          ),
                          label: Text(
                            pageError == null ? '以前の投稿を読み込む' : 'もう一度読み込む',
                          ),
                        ),
                      ],
                    )
                    : const SizedBox.shrink(),
          ),
        ),
      ),
    ];
  }

  Widget _postCard(BulletinPost post) => BulletinFeedCard(
    key: ValueKey('bulletin-post-${post.id}'),
    post: post,
    onTap:
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BulletinPostDetailScreen(post: post),
          ),
        ),
  );

  Widget _stateMessage({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Icon(
                icon,
                size: 32,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 20), action],
        ],
      ),
    );
  }

  Future<void> _addPost() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const BulletinPostFormScreen()),
    );
    if (result == true && mounted) await _refreshBulletinFeed();
  }

  Future<void> _openGuide() async {
    try {
      if (await launchUrl(
        Uri.parse('https://cit-app.com/features'),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {
      // A missing browser is reported in the same way as a rejected link.
    }
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('リンクを開けませんでした')));
    }
  }
}
