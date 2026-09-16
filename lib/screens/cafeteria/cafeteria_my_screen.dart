import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/cafeteria_favorite_provider.dart';
import '../../core/providers/my_cafeteria_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/cafeteria/cafeteria_favorite_model.dart';
import '../../models/cafeteria/cafeteria_favorite_target.dart';
import '../../models/cafeteria/cafeteria_menu_item_model.dart';
import '../../models/cafeteria/cafeteria_review_model.dart';
import '../../widgets/cafeteria/cafeteria_favorite_button.dart';
import '../../widgets/cafeteria/cafeteria_menu_item_image.dart';
import 'cafeteria_reviews_screen.dart';
import 'cafeteria_menu_reviews_screen.dart';
import 'cafeteria_review_form_screen.dart';

class MyCafeteriaScreen extends ConsumerStatefulWidget {
  const MyCafeteriaScreen({super.key});
  @override
  ConsumerState<MyCafeteriaScreen> createState() => _MyCafeteriaScreenState();
}

class _MyCafeteriaScreenState extends ConsumerState<MyCafeteriaScreen> {
  final _search = TextEditingController();
  String? _campus;
  bool _reviews = false;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _browse() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CafeteriaReviewsScreen(initialCafeteriaId: _campus),
    ),
  );
  Future<void> _refresh() async {
    ref.invalidate(userCafeteriaFavoritesProvider);
    ref.invalidate(myCafeteriaReviewsProvider);
    ref.invalidate(favoriteMenuItemProvider);
    ref.invalidate(cafeteriaFavoriteCountProvider);
    try {
      await Future.wait([
        ref.read(userCafeteriaFavoritesProvider.future),
        ref.read(myCafeteriaReviewsProvider.future),
      ]);
    } catch (_) {
      /* Error states below keep retry available. */
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final uid = ref.watch(cafeteriaFavoriteUserIdProvider);
    final favorites = ref.watch(userCafeteriaFavoritesProvider);
    final reviews = ref.watch(myCafeteriaReviewsProvider);
    final query = normalizeMenuName(_search.text);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My食堂'),
        actions: [
          IconButton(
            tooltip: 'メニューを探す',
            onPressed: _browse,
            icon: const Icon(Icons.restaurant_menu),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child:
            uid == null
                ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('ログインすると、お気に入りや自分のレビューを確認できます。'),
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _CollectionButton(
                                      label: 'お気に入り',
                                      icon: Icons.favorite_outline,
                                      selected: !_reviews,
                                      count: favorites.asData?.value.length,
                                      onTap:
                                          () =>
                                              setState(() => _reviews = false),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _CollectionButton(
                                      label: '自分のレビュー',
                                      icon: Icons.rate_review_outlined,
                                      selected: _reviews,
                                      count: reviews.asData?.value.length,
                                      onTap:
                                          () => setState(() => _reviews = true),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _search,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: 'メニュー名で検索',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon:
                                      _search.text.isEmpty
                                          ? null
                                          : IconButton(
                                            tooltip: '検索をクリア',
                                            icon: const Icon(Icons.close),
                                            onPressed:
                                                () => setState(_search.clear),
                                          ),
                                  filled: true,
                                  fillColor: scheme.surfaceContainerLow,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    for (final campus in [
                                      null,
                                      ...Cafeterias.all,
                                    ])
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: ChoiceChip(
                                          label: Text(
                                            campus == null
                                                ? 'すべての食堂'
                                                : Cafeterias.displayName(
                                                  campus,
                                                ),
                                          ),
                                          selected: _campus == campus,
                                          onSelected:
                                              (_) => setState(
                                                () => _campus = campus,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ...(_reviews
                          ? reviews.when(
                            data:
                                (items) => _reviewSlivers(
                                  items
                                      .where(
                                        (r) =>
                                            (_campus == null ||
                                                _campus == r.cafeteriaId) &&
                                            (query.isEmpty ||
                                                normalizeMenuName(
                                                  r.menuName,
                                                ).contains(query)),
                                      )
                                      .toList(),
                                  items.isEmpty,
                                ),
                            loading: () => [_loading()],
                            error:
                                (_, __) => [
                                  _error(
                                    () => ref.invalidate(
                                      myCafeteriaReviewsProvider,
                                    ),
                                  ),
                                ],
                          )
                          : favorites.when(
                            data:
                                (items) => _favoriteSlivers(
                                  items
                                      .where(
                                        (f) =>
                                            (_campus == null ||
                                                _campus == f.cafeteriaId) &&
                                            (query.isEmpty ||
                                                normalizeMenuName(
                                                  f.menuName,
                                                ).contains(query) ||
                                                normalizeMenuName(
                                                  Cafeterias.displayName(
                                                    f.cafeteriaId ?? '',
                                                  ),
                                                ).contains(query)),
                                      )
                                      .toList(),
                                  items.isEmpty,
                                ),
                            loading: () => [_loading()],
                            error:
                                (_, __) => [
                                  _error(
                                    () => ref.invalidate(
                                      userCafeteriaFavoritesProvider,
                                    ),
                                  ),
                                ],
                          )),
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _loading() => const SliverToBoxAdapter(
    child: Padding(
      padding: EdgeInsets.all(40),
      child: Center(child: CircularProgressIndicator()),
    ),
  );
  Widget _error(VoidCallback retry) => SliverToBoxAdapter(
    child: _EmptyState(
      icon: Icons.cloud_off_outlined,
      title: '読み込めませんでした',
      message: '通信状態を確認して、もう一度お試しください。',
      action: '再読み込み',
      onTap: retry,
    ),
  );
  Widget _empty(bool noRecords) => SliverToBoxAdapter(
    child: _EmptyState(
      icon: _reviews ? Icons.rate_review_outlined : Icons.favorite_border,
      title:
          !noRecords
              ? '条件に合うメニューがありません'
              : _reviews
              ? '自分のレビューはありません'
              : 'お気に入りはありません',
      message:
          !noRecords
              ? '食堂や検索キーワードを変えてみてください。'
              : _reviews
              ? 'メニュー画面からレビューを投稿できます。'
              : 'メニューのハートを押すと、ここに保存されます。',
      action: noRecords ? 'メニューを探す' : '条件をリセット',
      onTap:
          noRecords
              ? _browse
              : () => setState(() {
                _campus = null;
                _search.clear();
              }),
    ),
  );
  List<Widget> _favoriteSlivers(
    List<CafeteriaFavorite> items,
    bool noRecords,
  ) =>
      items.isEmpty
          ? [_empty(noRecords)]
          : [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: items.length,
                itemBuilder:
                    (_, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _FavoriteCard(
                        key: ValueKey(items[index].id),
                        favorite: items[index],
                      ),
                    ),
              ),
            ),
          ];
  List<Widget> _reviewSlivers(List<CafeteriaReview> items, bool noRecords) =>
      items.isEmpty
          ? [_empty(noRecords)]
          : [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: items.length,
                itemBuilder:
                    (_, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MyReviewCard(review: items[index]),
                    ),
              ),
            ),
          ];
}

class _CollectionButton extends StatelessWidget {
  const _CollectionButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.count,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final int? count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color:
                      selected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color:
                        selected ? scheme.onPrimaryContainer : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  count == null ? '—' : '$count件',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color:
                        selected ? scheme.onPrimaryContainer : scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteCard extends ConsumerWidget {
  const _FavoriteCard({super.key, required this.favorite});
  final CafeteriaFavorite favorite;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = favorite;
    final AsyncValue<CafeteriaMenuItem?> itemAsync =
        f.menuItemId?.isNotEmpty == true
            ? ref.watch(favoriteMenuItemProvider(f.menuItemId!))
            : const AsyncData(null);
    final item = itemAsync.asData?.value;
    final campus = item?.cafeteriaId ?? f.cafeteriaId ?? '';
    final name =
        f.type == 'cafeteria'
            ? Cafeterias.displayName(campus)
            : item?.menuName ?? f.menuName ?? 'メニュー';
    final target =
        f.type == 'cafeteria'
            ? CafeteriaFavoriteTarget.cafeteria(campus)
            : CafeteriaFavoriteTarget.menu(
              cafeteriaId: campus,
              menuName: name,
              menuItemId: f.menuItemId,
            );
    final canOpen = campus.isNotEmpty;
    void open() =>
        _openMenu(context, campus, f.type == 'cafeteria' ? null : name);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: canOpen ? open : null,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CafeteriaMenuItemImage(
                      imageUrl: item?.photoUrl,
                      placeholder:
                          f.type == 'cafeteria'
                              ? '食'
                              : name.characters.firstOrNull ?? '食',
                      width: 76,
                      height: 76,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CampusLabel(campus: campus),
                        const SizedBox(height: 6),
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (item?.price != null) ...[
                          const SizedBox(height: 5),
                          Text(
                            '¥${item!.price}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (itemAsync.hasError)
              TextButton.icon(
                onPressed:
                    () =>
                        ref.invalidate(favoriteMenuItemProvider(f.menuItemId!)),
                icon: const Icon(Icons.refresh),
                label: const Text('メニュー情報を再取得'),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: canOpen ? open : null,
                      icon: const Icon(Icons.restaurant_menu, size: 18),
                      label: Text(
                        f.type == 'cafeteria' ? '食堂のメニューを見る' : 'レビューを見る',
                      ),
                    ),
                  ),
                ),
                CafeteriaFavoriteButton(target: target, compact: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MyReviewCard extends StatelessWidget {
  const _MyReviewCard({required this.review});
  final CafeteriaReview review;
  @override
  Widget build(BuildContext context) {
    final r = review;
    final name =
        r.menuName?.trim().isNotEmpty == true ? r.menuName! : '食堂のレビュー';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _CampusLabel(campus: r.cafeteriaId),
                Text(
                  '${r.createdAt.year}/${r.createdAt.month}/${r.createdAt.day}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in [
                  ('美味しさ', r.taste),
                  ('量', r.volume),
                  ('おすすめ', r.recommend),
                ])
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text('${value.$1} ${value.$2}/5'),
                  ),
              ],
            ),
            if (r.comment?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(r.comment!, maxLines: 4, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('レビューを編集'),
                  onPressed:
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) => CafeteriaReviewFormScreen(
                                editingReview: r,
                                fixed: true,
                              ),
                        ),
                      ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.chevron_right, size: 18),
                  label: const Text('メニューを見る'),
                  onPressed:
                      () => _openMenu(context, r.cafeteriaId, r.menuName),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CampusLabel extends StatelessWidget {
  const _CampusLabel({required this.campus});
  final String campus;
  @override
  Widget build(BuildContext context) {
    final accent = campus == Cafeterias.tsudanuma ? Colors.blue : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tintedSurface(context, accent),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        campus.isEmpty ? '食堂情報なし' : Cafeterias.displayName(campus),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.accent(context, accent),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    required this.onTap,
  });
  final IconData icon;
  final String title, message, action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
    child: Column(
      children: [
        Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 18),
        FilledButton(onPressed: onTap, child: Text(action)),
      ],
    ),
  );
}

void _openMenu(BuildContext context, String campus, String? menu) {
  final validMenu = menu?.trim().isNotEmpty == true && menu != 'メニュー未指定';
  Navigator.of(context).push(
    MaterialPageRoute(
      builder:
          (_) =>
              validMenu
                  ? CafeteriaMenuReviewsScreen(
                    cafeteriaId: campus,
                    menuName: menu!.trim(),
                  )
                  : CafeteriaReviewsScreen(initialCafeteriaId: campus),
    ),
  );
}
