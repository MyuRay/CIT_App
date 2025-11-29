import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/common/animated_image_placeholder.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/providers/cafeteria_review_provider.dart';
import '../../models/cafeteria/cafeteria_review_model.dart';
import 'cafeteria_review_form_screen.dart';
import '../../core/providers/cafeteria_menu_provider.dart';
import '../../models/cafeteria/cafeteria_menu_item_model.dart';
import '../../core/providers/firebase_menu_provider.dart';
import 'cafeteria_menu_reviews_screen.dart';
import 'cafeteria_menu_item_form_screen.dart';
import '../../core/providers/in_app_ad_provider.dart';
import '../../models/ads/in_app_ad_model.dart';
import '../../widgets/ads/in_app_ad_card.dart';
import '../../core/providers/settings_provider.dart';

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
                  hintText: 'メニュー名で検索（${campusName}のみ）',
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
  String _sortOption = 'popular_desc';

  Future<void> _refresh() async {
    await Future.wait([
      ref.refresh(cafeteriaReviewsProvider(widget.cafeteriaId).future),
      ref.refresh(cafeteriaMenuItemsListProvider(widget.cafeteriaId).future),
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

    Widget? buildAdTile() {
      return adAsync.maybeWhen(
        data:
            (ad) =>
                ad == null
                    ? null
                    : InAppAdCard(
                      ad: ad,
                      placement: AdPlacement.cafeteria,
                      margin: EdgeInsets.zero,
                    ),
        orElse: () => null,
      );
    }

    List<Widget> buildMenuRows(List<_MenuAgg> menus) {
      final widgets = <Widget>[];
      for (var i = 0; i < menus.length; i++) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MenuRowCard(cafeteriaId: widget.cafeteriaId, agg: menus[i]),
          ),
        );
        if ((i + 1) % 7 == 0) {
          final adTile = buildAdTile();
          if (adTile != null) {
            widgets.add(
              Padding(padding: const EdgeInsets.only(bottom: 8), child: adTile),
            );
          }
        }
      }
      return widgets;
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
      if (review.createdAt.isAfter(todayStart) &&
          review.createdAt.isBefore(todayEnd)) {
        agg.hasReviewToday = true;
      }
    }

    final q = _query.trim().toLowerCase();
    final filtered =
        aggregated.values
            .where((agg) => q.isEmpty || agg.menuName.toLowerCase().contains(q))
            .toList();

    // 今日レビューされたメニューとその他のメニューに分離
    final todayReviewed = filtered.where((agg) => agg.hasReviewToday).toList();
    final others = filtered.where((agg) => !agg.hasReviewToday).toList();

    // ソートロジック
    int compareMenus(_MenuAgg a, _MenuAgg b) {
      final aDate =
          a.menuItem?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          b.menuItem?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      switch (_sortOption) {
        case 'created_asc':
          final cmp = aDate.compareTo(bDate);
          if (cmp != 0) return cmp;
          return a.menuName.toLowerCase().compareTo(b.menuName.toLowerCase());
        case 'created_desc':
          final cmp = bDate.compareTo(aDate);
          if (cmp != 0) return cmp;
          return a.menuName.toLowerCase().compareTo(b.menuName.toLowerCase());
        case 'popular_asc':
          final ratingCmpAsc = a.avgRecommend.compareTo(b.avgRecommend);
          if (ratingCmpAsc != 0) return ratingCmpAsc;
          final countCmpAsc = a.count.compareTo(b.count);
          if (countCmpAsc != 0) return countCmpAsc;
          break;
        case 'popular_desc':
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

    sortMenus(todayReviewed);
    sortMenus(others);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'メニュー名で検索（${campusName}のみ）',
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
              Icon(Icons.sort, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortOption,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'created_asc',
                        child: Text('メニュー追加順 (昇順)'),
                      ),
                      DropdownMenuItem(
                        value: 'created_desc',
                        child: Text('メニュー追加順 (降順)'),
                      ),
                      DropdownMenuItem(
                        value: 'popular_asc',
                        child: Text('人気順 (昇順)'),
                      ),
                      DropdownMenuItem(
                        value: 'popular_desc',
                        child: Text('人気順 (降順)'),
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
                    : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 本日レビューされたメニューセクション
                          if (todayReviewed.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.today,
                                    size: 18,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '本日レビューされたメニュー (${todayReviewed.length}件)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...buildMenuRows(todayReviewed),
                            const SizedBox(height: 16),
                          ],

                          // その他のメニューセクション
                          if (others.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.restaurant_menu,
                                    size: 18,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'その他のメニュー (${others.length}件)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...buildMenuRows(others),
                          ],
                        ],
                      ),
                    ),
          ),
        ),
      ],
    );
  }
}

Widget _buildMenuImage({
  String? imageUrl,
  required String placeholder,
  double fontSize = 28,
  double? width,
  double? height,
}) {
  if (imageUrl == null || imageUrl.isEmpty) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Center(
        child: Text(
          placeholder,
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  return CachedNetworkImage(
    imageUrl: imageUrl,
    fit: BoxFit.cover,
    placeholder:
        (context, url) =>
            AnimatedImagePlaceholder(width: width, height: height),
    errorWidget:
        (context, url, error) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(
              Icons.image_not_supported,
              size: 32,
              color: Colors.grey,
            ),
          ),
        ),
  );
}

class _FullScreenImagePage extends StatefulWidget {
  const _FullScreenImagePage({
    required this.imageUrl,
    required this.placeholder,
    super.key,
  });

  final String? imageUrl;
  final String placeholder;

  @override
  State<_FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<_FullScreenImagePage> {
  double _dragOffset = 0;
  bool _isDismissing = false;

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isDismissing) return;
    setState(() {
      _dragOffset += details.delta.dy;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isDismissing) return;
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
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(opacity),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        onVerticalDragUpdate: _handleDragUpdate,
        onVerticalDragEnd: _handleDragEnd,
        child: Center(
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: Hero(
              tag: widget.imageUrl ?? widget.placeholder,
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.0,
                child: _buildMenuImage(
                  imageUrl: widget.imageUrl,
                  placeholder: widget.placeholder,
                  fontSize: 48,
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
  Navigator.of(context).push(
    MaterialPageRoute(
      builder:
          (_) => _FullScreenImagePage(
            imageUrl: imageUrl,
            placeholder: placeholder,
          ),
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

class _MenuRowCard extends ConsumerWidget {
  const _MenuRowCard({required this.cafeteriaId, required this.agg});
  final String cafeteriaId;
  final _MenuAgg agg;

  String _formatPrice() {
    final price = agg.menuItem?.price;
    if (price == null) {
      return '価格未設定';
    }
    return '¥${price.toString()}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuItem = agg.menuItem;
    final priceText = _formatPrice();
    final placeholder =
        agg.menuName.isNotEmpty ? agg.menuName.substring(0, 1) : '?';
    final viewCount = menuItem?.viewCount ?? 0;

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
                    cafeteriaId: cafeteriaId,
                    menuName: agg.menuName,
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
                      tag: menuItem?.photoUrl ?? placeholder,
                      child: _buildMenuImage(
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
                      agg.menuName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Stars(rating: agg.avgRecommend),
                        const SizedBox(width: 6),
                        if (agg.count == 0)
                          const Text(
                            'レビューなし',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          )
                        else
                          Text(
                            '(${agg.count}件)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    if (menuItem != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$viewCount',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                priceText,
                style: const TextStyle(fontWeight: FontWeight.w600),
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
            return const Icon(Icons.star, size: 16, color: Colors.amber);
          } else if (i == full && hasHalf) {
            return const Icon(Icons.star_half, size: 16, color: Colors.amber);
          } else {
            return Icon(
              Icons.star_border,
              size: 16,
              color: Colors.grey.shade400,
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
                    ).colorScheme.primary.withOpacity(0.1),
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
                    icon: const Icon(
                      Icons.photo_library_outlined,
                      size: 18,
                      color: Colors.black,
                    ),
                    label: const Text(
                      'メニューを確認',
                      style: TextStyle(fontSize: 12, color: Colors.black),
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
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                // 編集/削除メニューは表示しない
              ],
            ),
            const SizedBox(height: 8),

            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    review.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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

    return Row(
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
          style: TextStyle(
            color: Colors.grey.shade600,
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
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        ...List.generate(5, (i) {
          final on = i < value;
          Color starColor;

          if (label == '量') {
            // 量の場合：星3が適量（緑）、星1-2が少ない（オレンジ）、星4-5が多い（青）
            if (i == 2) {
              // 星3（適量）
              starColor = on ? Colors.green : Colors.grey.shade400;
            } else if (i < 2) {
              // 星1-2（少ない）
              starColor = on ? Colors.orange : Colors.grey.shade400;
            } else {
              // 星4-5（多い）
              starColor = on ? Colors.blue : Colors.grey.shade400;
            }
          } else {
            // 他の評価は通常の色
            starColor = on ? Colors.amber : Colors.grey.shade400;
          }

          return Icon(Icons.star, color: starColor, size: 18);
        }),
        const SizedBox(width: 8),
        Text(
          '$value/5',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
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
