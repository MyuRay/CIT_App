import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/providers/cafeteria_favorite_provider.dart';
import '../../models/cafeteria/cafeteria_review_model.dart';
import '../../models/cafeteria/cafeteria_menu_item_model.dart';
import '../../services/cafeteria/cafeteria_menu_item_service.dart';

/// My食堂画面
/// - 自分のレビュー一覧
/// - お気に入りメニュー / 食堂一覧
class MyCafeteriaScreen extends ConsumerStatefulWidget {
  const MyCafeteriaScreen({super.key});

  @override
  ConsumerState<MyCafeteriaScreen> createState() => _MyCafeteriaScreenState();
}

class _MyCafeteriaScreenState extends ConsumerState<MyCafeteriaScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My食堂'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '自分のレビュー'),
            Tab(text: 'お気に入り'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MyReviewsTab(),
          _FavoritesTab(),
        ],
      ),
    );
  }
}

/// 自分のレビュー一覧タブ
class _MyReviewsTab extends ConsumerWidget {
  const _MyReviewsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('ログインが必要です'));
    }

    // インデックス不要にするため、whereのみで取得してメモリ内でソート
    final reviewsStream = FirebaseFirestore.instance
        .collection('cafeteria_reviews')
        .where('userId', isEqualTo: uid)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: reviewsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('読み込みエラー: ${snapshot.error}'));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('まだレビューがありません'));
        }

        // メモリ内でcreatedAtの降順にソート
        final reviews = docs
            .map((d) {
              final data = d.data();
              return CafeteriaReview.fromJson({'id': d.id, ...data});
            })
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: reviews.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final r = reviews[index];
            final campusName = Cafeterias.displayName(r.cafeteriaId);
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
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
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
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
                            r.menuName?.isNotEmpty == true
                                ? r.menuName!
                                : 'メニュー未指定',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(r.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    if (r.comment != null && r.comment!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(r.comment!),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '美味しさ: ${r.taste} / 量: ${r.volume} / おすすめ: ${r.recommend}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    return '${d.month}/${d.day}';
  }
}

/// お気に入りメニュー / 食堂一覧タブ
class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(userCafeteriaFavoritesProvider);

    return favoritesAsync.when(
      data: (favorites) {
        if (favorites.isEmpty) {
          return const Center(child: Text('お気に入りが登録されていません'));
        }

        final cafeteriaFavorites =
            favorites.where((f) => f.type == 'cafeteria').toList();
        final menuFavorites = favorites.where((f) => f.type == 'menu').toList();

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (cafeteriaFavorites.isNotEmpty) ...[
              const Text(
                'お気に入り食堂',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...cafeteriaFavorites.map((f) {
                final name =
                    f.cafeteriaId != null
                        ? Cafeterias.displayName(f.cafeteriaId!)
                        : '不明な食堂';
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.restaurant),
                    title: Text(name),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
            if (menuFavorites.isNotEmpty) ...[
              const Text(
                'お気に入りメニュー',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...menuFavorites.map(
                (f) {
                  if (f.menuItemId != null) {
                    return FutureBuilder<CafeteriaMenuItem?>(
                      future: CafeteriaMenuItemService.getMenuItem(f.menuItemId!),
                      builder: (context, snapshot) {
                        final item = snapshot.data;
                        final title =
                            item?.menuName ??
                            f.menuName ??
                            'メニュー名未設定';
                        final subtitle =
                            item != null
                                ? Cafeterias.displayName(item.cafeteriaId)
                                : (f.cafeteriaId != null
                                    ? Cafeterias.displayName(f.cafeteriaId!)
                                    : null);
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.ramen_dining),
                            title: Text(title),
                            subtitle:
                                subtitle != null ? Text(subtitle) : null,
                          ),
                        );
                      },
                    );
                  } else {
                    final title = f.menuName ?? 'メニュー名未設定';
                    final subtitle = f.cafeteriaId != null
                        ? Cafeterias.displayName(f.cafeteriaId!)
                        : null;
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.ramen_dining),
                        title: Text(title),
                        subtitle: subtitle != null ? Text(subtitle) : null,
                      ),
                    );
                  }
                },
              ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('読み込みエラー: $e')),
    );
  }
}

