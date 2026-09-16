import '../../widgets/cafeteria/cafeteria_rating_star.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../widgets/common/interactive_viewer_double_tap_zoom.dart';
import '../../widgets/common/safe_cached_network_image.dart';
import '../../widgets/cafeteria/cafeteria_menu_item_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/providers/cafeteria_review_provider.dart';
import '../../models/cafeteria/cafeteria_review_model.dart';
import '../../core/providers/cafeteria_menu_provider.dart';
import '../../core/providers/cafeteria_popularity_provider.dart';
import '../../models/cafeteria/cafeteria_menu_item_model.dart';
import '../../core/providers/firebase_menu_provider.dart';
import 'cafeteria_menu_reviews_screen.dart';
import 'cafeteria_menu_item_form_screen.dart';
import '../../core/providers/in_app_ad_provider.dart';
import '../../models/ads/in_app_ad_model.dart';
import '../../widgets/ads/in_app_ad_card.dart';
import '../../core/providers/settings_provider.dart';

import '../../models/cafeteria/cafeteria_favorite_target.dart';
import '../../widgets/cafeteria/cafeteria_favorite_button.dart';

String? _campusCodeFromCafeteriaId(String cafeteriaId) {
  switch (cafeteriaId) {
    case Cafeterias.tsudanuma:
      return 'td';
    case Cafeterias.narashino1F:
      return 'sd1';
    case Cafeterias.narashino2F:
      return 'sd2';
    default:
      return null;
  }
}

Future<void> _showCampusMenuImage(
  BuildContext context,
  WidgetRef ref, {
  required String campusCode,
  required String campusName,
}) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final imageUrl = await ref.read(
      firebaseTodayMenuProvider(campusCode).future,
    );
    if (!context.mounted) {
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();

    if (imageUrl == null || imageUrl.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$campusNameのメニュー画像が見つかりませんでした')));
      return;
    }

    final placeholder =
        campusName.characters.isNotEmpty
            ? campusName.characters.first
            : campusName;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => _FullScreenImagePage(
              imageUrl: imageUrl,
              placeholder: placeholder,
            ),
      ),
    );
  } catch (e) {
    if (!context.mounted) {
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('メニュー画像の取得に失敗しました: $e')));
  }
}

class CafeteriaReviewsScreen extends ConsumerStatefulWidget {
  const CafeteriaReviewsScreen({super.key, this.initialCafeteriaId});

  final String? initialCafeteriaId;

  @override
  ConsumerState<CafeteriaReviewsScreen> createState() =>
      _CafeteriaReviewsScreenState();
}

class _CafeteriaReviewsScreenState extends ConsumerState<CafeteriaReviewsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _initialTabSet = false;

  int _indexForCafeteria(String? id) {
    switch (id) {
      case Cafeterias.tsudanuma:
        return 0;
      case Cafeterias.narashino1F:
        return 1;
      case Cafeterias.narashino2F:
        return 2;
      default:
        return 0;
    }
  }

  String _cafeteriaForIndex(int idx) {
    switch (idx) {
      case 0:
        return Cafeterias.tsudanuma;
      case 1:
        return Cafeterias.narashino1F;
      case 2:
        return Cafeterias.narashino2F;
      default:
        return Cafeterias.tsudanuma;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final initial = _indexForCafeteria(widget.initialCafeteriaId);
    _tabController.index = initial;
    _tabController.addListener(() {
      if (!mounted) return;
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // initialCafeteriaIdが指定されていない場合、メインキャンパス設定を確認
    if (!_initialTabSet && widget.initialCafeteriaId == null) {
      final preferredCampus = ref.read(preferredBusCampusProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && preferredCampus == 'narashino') {
          _tabController.animateTo(1); // 新習志野1F
          _initialTabSet = true;
        }
      });
    } else {
      _initialTabSet = true;
    }

    final campusId = _cafeteriaForIndex(_tabController.index);
    final campusCode = _campusCodeFromCafeteriaId(campusId);
    final campusName = Cafeterias.displayName(campusId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('学食レビュー'),
        actions: [
          if (campusCode != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton.icon(
                icon: Icon(
                  Icons.photo_library_outlined,
                  size: 18,
                  color: buttonColor,
                ),
                label: Text('メニューを確認', style: TextStyle(color: buttonColor)),
                onPressed:
                    () => _showCampusMenuImage(
                      context,
                      ref,
                      campusCode: campusCode,
                      campusName: campusName,
                    ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '津田沼'),
            Tab(text: '新習志野 1F'),
            Tab(text: '新習志野 2F'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MenuCardsList(cafeteriaId: Cafeterias.tsudanuma),
          _MenuCardsList(cafeteriaId: Cafeterias.narashino1F),
          _MenuCardsList(cafeteriaId: Cafeterias.narashino2F),
        ],
      ),
    );
  }
}

class _ReviewsList extends ConsumerStatefulWidget {
  const _ReviewsList({required this.cafeteriaId});
  final String cafeteriaId;

  @override
  ConsumerState<_ReviewsList> createState() => _ReviewsListState();
}

class _ReviewsListState extends ConsumerState<_ReviewsList> {
  final _searchController = TextEditingController();
  String _query = '';

  Future<void> _refresh() async {
    await ref.refresh(cafeteriaReviewsProvider(widget.cafeteriaId).future);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(
      cafeteriaReviewsProvider(widget.cafeteriaId),
    );
    final campusName = Cafeterias.displayName(widget.cafeteriaId);
    final campusCode = _campusCodeFromCafeteriaId(widget.cafeteriaId);
    return reviewsAsync.when(
      data: (reviews) {
        // メニュー名でフィルタ（同一キャンパス内のみ）
        final q = _query.trim().toLowerCase();
        final filtered =
            q.isEmpty
                ? reviews
                : reviews
                    .where((r) => (r.menuName ?? '').toLowerCase().contains(q))
                    .toList();

        return Column(
          children: [
            if (campusCode != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                child: Builder(
                  builder: (context) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    final buttonColor = isDark ? Colors.white : Colors.black;
                    return Row(
                      children: [
                        Text(
                          campusName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        TextButton.icon(
                          icon: Icon(
                            Icons.photo_library_outlined,
                            size: 18,
                            color: buttonColor,
                          ),
                          label: Text(
                            'メニューを確認',
                            style: TextStyle(fontSize: 12, color: buttonColor),
                          ),
                          onPressed:
                              () => _showCampusMenuImage(
                                context,
                                ref,
                                campusCode: campusCode,
                                campusName: campusName,
                              ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'メニュー名で検索（$campusNameのみ）',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _query.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _query = '';
                                _searchController.clear();
                              });
                            },
                          )
                          : null,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child:
                    filtered.isEmpty
                        ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          children: [
                            Center(
                              child: Text(
                                q.isEmpty
                                    ? 'まだレビューがありません'
                                    : '検索条件に一致するレビューがありません',
                              ),
                            ),
                          ],
                        )
                        : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 8),
                          itemCount: filtered.length,
                          itemBuilder:
                              (context, index) =>
                                  _ReviewCard(review: filtered[index]),
                        ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('隱ｭ縺ｿ霎ｼ縺ｿ縺ｫ螟ｱ謨励＠縺ｾ縺励◆: $e')),
    );
  }
}

class _MenuCardsList extends ConsumerStatefulWidget {
  const _MenuCardsList({required this.cafeteriaId});
  final String cafeteriaId;

  @override
  ConsumerState<_MenuCardsList> createState() => _MenuCardsListState();
}

class _MenuCardsListState extends ConsumerState<_MenuCardsList> {
  final _searchController = TextEditingController();
  String _query = '';
  String _sortOption = 'recommend_desc';
  String _popularityKeys = '';

  bool get _sortByFavorites =>
      _sortOption == 'popular_desc' || _sortOption == 'popular_asc';

  Future<void> _refresh() async {
    await Future.wait([
      ref.refresh(cafeteriaReviewsProvider(widget.cafeteriaId).future),
      ref.refresh(cafeteriaMenuItemsListProvider(widget.cafeteriaId).future),
      if (_sortByFavorites && _popularityKeys.isNotEmpty)
        ref.refresh(cafeteriaPopularityProvider(_popularityKeys).future),
    ]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(
      cafeteriaReviewsProvider(widget.cafeteriaId),
    );
    final menuItemsAsync = ref.watch(
      cafeteriaMenuItemsListProvider(widget.cafeteriaId),
    );
    final campusName = Cafeterias.displayName(widget.cafeteriaId);
    final cafeteriaAdAsync = ref.watch(inAppAdProvider(AdPlacement.cafeteria));

    return reviewsAsync.when(
      data: (reviews) {
        return menuItemsAsync.when(
          data:
              (menuItems) => _buildMenuList(
                context,
                reviews,
                menuItems,
                campusName,
                cafeteriaAdAsync,
              ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('メニュー情報の読み込みに失敗しました: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('レビューの読み込みに失敗しました: $e')),
    );
  }

  Widget _buildMenuList(
    BuildContext context,
    List<CafeteriaReview> reviews,
    List<CafeteriaMenuItem> menuItems,
    String campusName,
    AsyncValue<InAppAd?> adAsync,
  ) {
    final menuMap = <String, CafeteriaMenuItem>{};
    for (final item in menuItems) {
      final key = item.menuName.trim().toLowerCase();
      if (key.isEmpty) continue;
      menuMap[key] = item;
    }

    final aggregated = <String, _MenuAgg>{};

    Widget buildMenuRows(List<_MenuAgg> menus) {
      final ad = adAsync.valueOrNull;
      final rows = <({String key, _MenuAgg? menu})>[];
      for (var i = 0; i < menus.length; i++) {
        final key = menus[i].menuName.trim().toLowerCase();
        rows.add((key: 'menu:$key', menu: menus[i]));
        if (ad != null && (i + 1) % 7 == 0) {
          rows.add((key: 'ad:$key', menu: null));
        }
      }
      final indices = {for (var i = 0; i < rows.length; i++) rows[i].key: i};
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final row = rows[index];
            return Padding(
              key: ValueKey(row.key),
              padding: const EdgeInsets.only(bottom: 8),
              child:
                  row.menu != null
                      ? _MenuRowCard(
                        cafeteriaId: widget.cafeteriaId,
                        agg: row.menu!,
                      )
                      : InAppAdCard(
                        ad: ad!,
                        placement: AdPlacement.cafeteria,
                        margin: EdgeInsets.zero,
                      ),
            );
          },
          childCount: rows.length,
          findChildIndexCallback:
              (key) => key is ValueKey<String> ? indices[key.value] : null,
        ),
      );
    }

    for (final entry in menuMap.entries) {
      aggregated[entry.key] = _MenuAgg(
        entry.value.menuName,
        menuItem: entry.value,
      );
    }

    // 今日の日付を取得（時間は00:00:00に設定）
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    for (final review in reviews) {
      final name = (review.menuName ?? '').trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      final menuItem = menuMap[key];
      final displayName = menuItem?.menuName ?? name;
      final agg = aggregated.putIfAbsent(
        key,
        () => _MenuAgg(displayName, menuItem: menuItem),
      );
      agg.addReview(review);

      // 今日のレビューかどうかをチェック
      if (!review.createdAt.isBefore(todayStart) &&
          review.createdAt.isBefore(todayEnd)) {
        agg.hasReviewToday = true;
      }
    }

    final q = _query.trim().toLowerCase();
    final favoriteKeys = <_MenuAgg, String>{
      if (_sortByFavorites)
        for (final menu in aggregated.values)
          menu:
              CafeteriaFavoriteTarget.menu(
                cafeteriaId: widget.cafeteriaId,
                menuItemId: menu.menuItem?.id,
                menuName: menu.menuName,
              ).key,
    };
    final keys = favoriteKeys.values.toSet().toList()..sort();
    _popularityKeys = keys.join(',');
    final popularity =
        _sortByFavorites
            ? ref.watch(cafeteriaPopularityProvider(_popularityKeys))
            : const AsyncData<Map<String, int>>({});
    final favoriteCounts = popularity.valueOrNull ?? const <String, int>{};
    final filtered =
        aggregated.values
            .where((agg) => q.isEmpty || agg.menuName.toLowerCase().contains(q))
            .toList();

    // Apply the selected ordering to the entire list. Today's reviews remain
    // visible on each card instead of overriding the selected ranking.
    final sortByReviewCount = _sortOption == 'review_count_desc';
    final others = filtered.toList();

    // ソートロジック
    int compareMenus(_MenuAgg a, _MenuAgg b) {
      if (_sortOption == 'recommend_desc' || _sortOption == 'recommend_asc') {
        if (a.count == 0 && b.count > 0) return 1;
        if (b.count == 0 && a.count > 0) return -1;
      }
      final aDate =
          a.menuItem?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          b.menuItem?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      switch (_sortOption) {
        case 'popular_desc':
        case 'popular_asc':
          final aCount = favoriteCounts[favoriteKeys[a]];
          final bCount = favoriteCounts[favoriteKeys[b]];
          // Missing aggregate documents are uncounted, not zero favorites.
          if (aCount == null && bCount != null) return 1;
          if (bCount == null && aCount != null) return -1;
          if (aCount != null && bCount != null) {
            final countCmp =
                _sortOption == 'popular_desc'
                    ? bCount.compareTo(aCount)
                    : aCount.compareTo(bCount);
            if (countCmp != 0) return countCmp;
          }
          break;
        case 'review_count_desc':
          final countCmp = b.count.compareTo(a.count);
          if (countCmp != 0) return countCmp;
          final ratingCmp = b.avgRecommend.compareTo(a.avgRecommend);
          if (ratingCmp != 0) return ratingCmp;
          break;
        case 'created_asc':
          final cmp = aDate.compareTo(bDate);
          if (cmp != 0) return cmp;
          return a.menuName.toLowerCase().compareTo(b.menuName.toLowerCase());
        case 'created_desc':
          final cmp = bDate.compareTo(aDate);
          if (cmp != 0) return cmp;
          return a.menuName.toLowerCase().compareTo(b.menuName.toLowerCase());
        case 'recommend_asc':
          final ratingCmpAsc = a.avgRecommend.compareTo(b.avgRecommend);
          if (ratingCmpAsc != 0) return ratingCmpAsc;
          final countCmpAsc = a.count.compareTo(b.count);
          if (countCmpAsc != 0) return countCmpAsc;
          break;
        case 'recommend_desc':
        default:
          final ratingCmpDesc = b.avgRecommend.compareTo(a.avgRecommend);
          if (ratingCmpDesc != 0) return ratingCmpDesc;
          final countCmpDesc = b.count.compareTo(a.count);
          if (countCmpDesc != 0) return countCmpDesc;
          break;
      }

      final createdCmp = bDate.compareTo(aDate);
      if (createdCmp != 0) return createdCmp;
      return a.menuName.toLowerCase().compareTo(b.menuName.toLowerCase());
    }

    void sortMenus(List<_MenuAgg> menus) {
      menus.sort(compareMenus);
    }

    sortMenus(others);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'メニュー名で検索（$campusNameのみ）',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _query.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _query = '';
                            _searchController.clear();
                          });
                        },
                      )
                      : null,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) => CafeteriaMenuItemFormScreen(
                          cafeteriaId: widget.cafeteriaId,
                        ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('メニューを追加'),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.sort,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortOption,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'recommend_desc',
                        child: Text('おすすめ順（評価が高い順）'),
                      ),
                      DropdownMenuItem(
                        value: 'recommend_asc',
                        child: Text('おすすめ評価が低い順'),
                      ),
                      DropdownMenuItem(
                        value: 'popular_desc',
                        child: Text('人気順（お気に入りが多い順）'),
                      ),
                      DropdownMenuItem(
                        value: 'popular_asc',
                        child: Text('お気に入りが少ない順'),
                      ),
                      DropdownMenuItem(
                        value: 'review_count_desc',
                        child: Text('レビューの多い順'),
                      ),
                      DropdownMenuItem(
                        value: 'created_asc',
                        child: Text('追加日の古い順'),
                      ),
                      DropdownMenuItem(
                        value: 'created_desc',
                        child: Text('追加日の新しい順'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _sortOption = value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_sortByFavorites) ...[
          if (popularity.isLoading) const LinearProgressIndicator(minHeight: 2),
          if (popularity.hasError)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  const Text('お気に入り人数を取得できませんでした'),
                  TextButton(
                    onPressed:
                        () => ref.invalidate(
                          cafeteriaPopularityProvider(_popularityKeys),
                        ),
                    child: const Text('再試行'),
                  ),
                ],
              ),
            )
          else if (!popularity.isLoading &&
              filtered.any(
                (menu) => !favoriteCounts.containsKey(favoriteKeys[menu]),
              ))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '集計待ちのメニューは最後に表示しています',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
        ],
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child:
                filtered.isEmpty
                    ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      children: [
                        Center(
                          child: Text(
                            q.isEmpty
                                ? '表示できるメニューがありません'
                                : '検索条件に一致するメニューがありません',
                          ),
                        ),
                      ],
                    )
                    : CustomScrollView(
                      key: const ValueKey('cafeteria-menu-list'),
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          sliver: SliverMainAxisGroup(
                            slivers: [
                              // その他のメニューセクション
                              if (others.isNotEmpty) ...[
                                SliverToBoxAdapter(
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.outlineVariant,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.restaurant_menu,
                                          size: 18,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            sortByReviewCount
                                                ? 'レビュー件数順 (${others.length}件)'
                                                : _sortByFavorites
                                                ? 'お気に入り人数順 (${others.length}件)'
                                                : 'メニュー (${others.length}件)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 8),
                                ),
                                buildMenuRows(others),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ],
    );
  }
}

class _FullScreenImagePage extends StatefulWidget {
  const _FullScreenImagePage({
    required this.imageUrl,
    required this.placeholder,
  });

  final String? imageUrl;
  final String placeholder;

  @override
  State<_FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<_FullScreenImagePage> {
  double _dragOffset = 0;
  bool _isDismissing = false;
  late final TransformationController _transformationController;
  double _currentScale = 1.0; // 現在のスケールを追跡
  static const double _zoomedScale = 2.5;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    // スケール変更を監視
    _transformationController.addListener(_onTransformationChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if (_currentScale != scale) {
      setState(() {
        _currentScale = scale;
        // スケールが1.0に戻ったら、ドラッグオフセットもリセット
        if (scale <= 1.0 && _dragOffset != 0) {
          _dragOffset = 0;
        }
      });
    }
  }

  void _handleDoubleTap(TapDownDetails details) {
    interactiveViewerToggleZoomAtFocalPoint(
      _transformationController,
      details,
      zoomScale: _zoomedScale,
    );
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isDismissing) return;
    // 拡大中（スケール > 1.0）の場合は画面を閉じない
    if (_currentScale > 1.0) return;
    setState(() {
      _dragOffset += details.delta.dy;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isDismissing) return;
    // 拡大中（スケール > 1.0）の場合は画面を閉じない
    if (_currentScale > 1.0) {
      setState(() {
        _dragOffset = 0;
      });
      return;
    }
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (_dragOffset.abs() > 120 || velocity.abs() > 700) {
      _isDismissing = true;
      Navigator.of(context).pop();
    } else {
      setState(() {
        _dragOffset = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final opacity = (1 - (_dragOffset.abs() / 400)).clamp(0.3, 1.0).toDouble();
    // 拡大中（スケール > 1.0）の場合は画面を閉じない
    final bool canDismiss = _currentScale <= 1.0;
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: opacity),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: canDismiss ? () => Navigator.of(context).pop() : null,
        onVerticalDragUpdate: canDismiss ? _handleDragUpdate : null,
        onVerticalDragEnd: canDismiss ? _handleDragEnd : null,
        child: SizedBox.expand(
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: Hero(
              // Hero タグ衝突を避けるため、URL が未設定でも一意性を保つ
              // プレフィックスを付ける
              tag:
                  'cafeteria_full_image:'
                  '${widget.imageUrl ?? widget.placeholder}',
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTapDown: _handleDoubleTap,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.8,
                  maxScale: 3.0,
                  panEnabled: true,
                  scaleEnabled: true,
                  clipBehavior: Clip.hardEdge,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  child: CafeteriaMenuItemImage(
                    imageUrl: widget.imageUrl,
                    placeholder: widget.placeholder,
                    fontSize: 48,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _openFullScreenImage(
  BuildContext context, {
  required String placeholder,
  String? imageUrl,
}) {
  if (imageUrl == null || imageUrl.isEmpty) {
    return;
  }
  double dragOffsetY = 0;
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.82),
    builder:
        (_) => StatefulBuilder(
          builder: (dialogContext, setState) {
            final dismissProgress = (dragOffsetY / 220).clamp(0.0, 1.0);
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragUpdate: (details) {
                if (details.delta.dy <= 0) {
                  return;
                }
                setState(() {
                  dragOffsetY = (dragOffsetY + details.delta.dy).clamp(
                    0.0,
                    320.0,
                  );
                });
              },
              onVerticalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (dragOffsetY > 120 || velocity > 950) {
                  Navigator.of(dialogContext).pop();
                  return;
                }
                setState(() {
                  dragOffsetY = 0;
                });
              },
              child: Transform.translate(
                offset: Offset(0, dragOffsetY),
                child: Opacity(
                  opacity: 1 - (dismissProgress * 0.35),
                  child: Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: InteractiveViewer(
                            minScale: 1.0,
                            maxScale: 4.0,
                            child: SafeCachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.contain,
                              placeholder: Container(
                                color: Colors.black,
                                alignment: Alignment.center,
                                child: const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: Container(
                                color: Colors.black,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.white70,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close),
                            color: Colors.white,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
  );
}

class _MenuAgg {
  _MenuAgg(this.menuName, {this.menuItem});
  final String menuName;
  final CafeteriaMenuItem? menuItem;
  int count = 0;
  int sumRecommend = 0;
  bool hasReviewToday = false;

  double get avgRecommend => count == 0 ? 0 : sumRecommend / count;

  void addReview(CafeteriaReview review) {
    count += 1;
    sumRecommend += review.recommend;
  }
}

class _MenuRowCard extends ConsumerStatefulWidget {
  const _MenuRowCard({required this.cafeteriaId, required this.agg});
  final String cafeteriaId;
  final _MenuAgg agg;

  @override
  ConsumerState<_MenuRowCard> createState() => _MenuRowCardState();
}

class _MenuRowCardState extends ConsumerState<_MenuRowCard> {
  String _formatPrice() {
    final price = widget.agg.menuItem?.price;
    if (price == null) {
      return '価格未設定';
    }
    return '¥${price.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final menuItem = widget.agg.menuItem;
    final priceText = _formatPrice();
    // 絵文字や合字などサロゲートペアを含むメニュー名でも安全に1文字取り出すため
    // String.substring ではなく characters パッケージの first を使用する。
    // （iOS のテキストレンダリングが lone surrogate でクラッシュするのを防ぐ）
    final placeholder =
        widget.agg.menuName.characters.isNotEmpty
            ? widget.agg.menuName.characters.first
            : '?';
    // Hero タグは画面間で一意になるよう cafeteriaId + menuName から生成する
    // （photoUrl が null かつ placeholder が同じメニューが複数あると Hero タグが衝突するため）
    final heroTag =
        'cafeteria_menu_image:${widget.cafeteriaId}:${widget.agg.menuName}';
    return Card(
      child: InkWell(
        onTap: () {
          if (menuItem != null && menuItem.id.isNotEmpty) {
            ref
                .read(cafeteriaMenuItemActionsProvider)
                .incrementViewCount(menuItem.id);
          }

          Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (context) => CafeteriaMenuReviewsScreen(
                    cafeteriaId: widget.cafeteriaId,
                    menuName: widget.agg.menuName,
                  ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 100,
                  height: 72,
                  child: GestureDetector(
                    onTap:
                        () => _openFullScreenImage(
                          context,
                          placeholder: placeholder,
                          imageUrl: menuItem?.photoUrl,
                        ),
                    child: Hero(
                      tag: heroTag,
                      child: CafeteriaMenuItemImage(
                        imageUrl: menuItem?.photoUrl,
                        placeholder: placeholder,
                        width: 100,
                        height: 72,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.agg.menuName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Stars(rating: widget.agg.avgRecommend),
                        const SizedBox(width: 6),
                        if (widget.agg.count == 0)
                          Text(
                            'レビューなし',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          )
                        else
                          Text(
                            '(${widget.agg.count}件)',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    if (widget.agg.hasReviewToday) ...[
                      const SizedBox(height: 4),
                      Text(
                        '今日のレビューあり',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.accent(
                            context,
                            Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    priceText,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  CafeteriaFavoriteButton(
                    compact: true,
                    target: CafeteriaFavoriteTarget.menu(
                      cafeteriaId: widget.cafeteriaId,
                      menuName: widget.agg.menuName,
                      menuItemId: menuItem?.id,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});
  final double rating; // 0..5

  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final hasHalf = (rating - full) >= 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          if (i < full) {
            return const CafeteriaRatingStar(size: 16);
          } else if (i == full && hasHalf) {
            return const CafeteriaRatingStar(size: 16, half: true);
          } else {
            return Icon(
              Icons.star_border,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            );
          }
        }),
      ],
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({required this.review});
  final CafeteriaReview review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnReview = currentUser != null && currentUser.uid == review.userId;
    final campusName = Cafeterias.displayName(review.cafeteriaId);
    final campusCode = _campusCodeFromCafeteriaId(review.cafeteriaId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    campusName,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    review.menuName?.isNotEmpty == true
                        ? review.menuName!
                        : 'メニュー未指定',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (campusCode != null)
                  TextButton.icon(
                    icon: Icon(
                      Icons.photo_library_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    label: Text(
                      'メニューを確認',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    onPressed:
                        () => _showCampusMenuImage(
                          context,
                          ref,
                          campusCode: campusCode,
                          campusName: campusName,
                        ),
                  ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(review.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                // 編集/削除メニューは表示しない
              ],
            ),
            const SizedBox(height: 8),

            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    review.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment!),
            ],
            const SizedBox(height: 8),
            _RatingRow(label: '美味しさ', value: review.taste),
            _RatingRow(label: '量', value: review.volume),
            _RatingRow(label: 'おすすめ', value: review.recommend),
            const SizedBox(height: 8),
            _ReviewLikeRow(review: review),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    if (diff.inDays < 7) return '${diff.inDays}日前';
    return '${d.month}/${d.day}';
  }
}

class _ReviewLikeRow extends ConsumerWidget {
  const _ReviewLikeRow({required this.review});

  final CafeteriaReview review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final actions = ref.read(cafeteriaReviewActionsProvider);
    final isLiked = uid != null && (review.likedBy?[uid] == true);
    final likeCount = review.likeCount;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.pinkAccent : Colors.grey,
          ),
          onPressed:
              (uid == null || review.id.isEmpty)
                  ? null
                  : () async {
                    try {
                      if (isLiked) {
                        await actions.unlike(review.id);
                      } else {
                        await actions.like(review.id);
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('いいねに失敗しました: $e')));
                    }
                  },
        ),
        Text(
          likeCount.toString(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.label, required this.value});
  final String label;
  final int value; // 1-5

  String _getVolumeDescription(int rating) {
    switch (rating) {
      case 1:
        return '少ない';
      case 2:
        return 'やや少ない';
      case 3:
        return '適量';
      case 4:
        return 'やや多い';
      case 5:
        return '多い';
      default:
        return '';
    }
  }

  String _getTasteDescription(int rating) {
    switch (rating) {
      case 1:
        return 'イマイチ';
      case 2:
        return 'もう少し';
      case 3:
        return '普通';
      case 4:
        return '美味しい';
      case 5:
        return 'とても美味しい';
      default:
        return '';
    }
  }

  String _getRecommendDescription(int rating) {
    switch (rating) {
      case 1:
        return 'おすすめしない';
      case 2:
        return 'あまりおすすめしない';
      case 3:
        return '普通';
      case 4:
        return 'おすすめ';
      case 5:
        return 'とてもおすすめ';
      default:
        return '';
    }
  }

  Color _getVolumeColor(int rating) {
    switch (rating) {
      case 1:
      case 2:
        return Colors.orange; // 少ない
      case 3:
        return Colors.green; // 適量
      case 4:
      case 5:
        return Colors.blue; // 多い
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    String description = '';
    if (label == '量') {
      description = _getVolumeDescription(value);
    } else if (label == '美味しさ') {
      description = _getTasteDescription(value);
    } else if (label == 'おすすめ') {
      description = _getRecommendDescription(value);
    }

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ...List.generate(5, (i) {
          final on = i < value;
          return CafeteriaRatingStar(filled: on);
        }),
        const SizedBox(width: 8),
        Text(
          '$value/5',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color:
                  label == '量'
                      ? _getVolumeColor(value)
                      : Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color:
                    label == '量'
                        ? Colors.white
                        : Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
