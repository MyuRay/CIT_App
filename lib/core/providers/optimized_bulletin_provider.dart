import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/bulletin/bulletin_model.dart';
import '../services/cache_service.dart';
import '../services/performance_monitor.dart';
import '../services/simple_offline_service.dart';

/// 最適化された掲示板プロバイダー
class OptimizedBulletinNotifier extends StateNotifier<AsyncValue<List<BulletinPost>>> 
    with PerformanceTrackingMixin, SimpleOfflineSupportMixin {
  OptimizedBulletinNotifier() : super(const AsyncValue.loading()) {
    _initialize();
  }

  static const Duration _cacheTTL = Duration(minutes: 5);
  static const String _cacheKey = 'bulletin_posts_optimized';
  static const int _batchSize = 20; // 一度に取得する投稿数

  /// 初期化
  Future<void> _initialize() async {
    await loadPosts();
  }

  /// 投稿を読み込み
  Future<void> loadPosts({bool forceRefresh = false}) async {
    state = const AsyncValue.loading();

    try {
      final posts = await trackAsync('load_bulletin_posts', () async {
        return await getDataOfflineAware<List<BulletinPost>>(
          cacheKey: _cacheKey,
          networkFetch: _fetchPostsFromFirestore,
          cacheTTL: _cacheTTL,
          forceRefresh: forceRefresh,
        );
      });

      if (posts != null) {
        state = AsyncValue.data(posts);
      } else {
        state = AsyncValue.data([]);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Firestoreから投稿を取得（最適化されたクエリ）
  Future<List<BulletinPost>> _fetchPostsFromFirestore() async {
    final firestore = FirebaseFirestore.instance;

    // 最適化されたクエリ: インデックスを活用
    final query = firestore
        .collection('bulletin_posts')
        .where('isActive', isEqualTo: true)
        .where('approvalStatus', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .limit(_batchSize);

    final snapshot = await query.get(const GetOptions(source: Source.server));
    
    final posts = <BulletinPost>[];
    
    // バッチ処理で効率的に変換
    final futures = snapshot.docs.map((doc) async {
      try {
        final data = {
          'id': doc.id,
          ...doc.data(),
        };
        return BulletinPost.fromJson(data);
      } catch (e) {
        print('❌ 投稿変換エラー (${doc.id}): $e');
        return null;
      }
    });

    final results = await Future.wait(futures);
    
    for (final post in results) {
      if (post != null) {
        posts.add(post);
      }
    }

    return posts;
  }

  /// より多くの投稿を読み込み（ページネーション）
  Future<void> loadMorePosts() async {
    if (state is! AsyncData<List<BulletinPost>>) return;

    final currentPosts = state.value!;
    if (currentPosts.isEmpty) return;

    try {
      final lastPost = currentPosts.last;
      final morePosts = await trackAsync('load_more_bulletin_posts', () async {
        return await _fetchMorePostsFromFirestore(lastPost.createdAt);
      });

      if (morePosts.isNotEmpty) {
        final updatedPosts = [...currentPosts, ...morePosts];
        state = AsyncValue.data(updatedPosts);
        
        // キャッシュを更新
        final cache = CacheService();
        await cache.setPersistentCache(_cacheKey, updatedPosts, ttl: _cacheTTL);
      }
    } catch (error, stackTrace) {
      // エラーでも現在の状態を維持
      print('❌ 追加投稿読み込みエラー: $error');
    }
  }

  /// より多くの投稿をFirestoreから取得
  Future<List<BulletinPost>> _fetchMorePostsFromFirestore(DateTime lastCreatedAt) async {
    final firestore = FirebaseFirestore.instance;

    final query = firestore
        .collection('bulletin_posts')
        .where('isActive', isEqualTo: true)
        .where('approvalStatus', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .startAfter([Timestamp.fromDate(lastCreatedAt)])
        .limit(_batchSize);

    final snapshot = await query.get();
    
    final posts = <BulletinPost>[];
    
    for (final doc in snapshot.docs) {
      try {
        final data = {
          'id': doc.id,
          ...doc.data(),
        };
        final post = BulletinPost.fromJson(data);
        posts.add(post);
      } catch (e) {
        print('❌ 追加投稿変換エラー (${doc.id}): $e');
      }
    }

    return posts;
  }

  /// カテゴリ別の投稿を取得
  List<BulletinPost> getPostsByCategory(String? categoryId) {
    if (state is! AsyncData<List<BulletinPost>>) return [];
    
    final posts = state.value!;
    
    if (categoryId == null) {
      return posts;
    }
    
    return posts.where((post) => post.category.id == categoryId).toList();
  }

  /// 検索機能
  List<BulletinPost> searchPosts(String query) {
    if (state is! AsyncData<List<BulletinPost>>) return [];
    
    final posts = state.value!;
    final lowercaseQuery = query.toLowerCase();
    
    return posts.where((post) {
      return post.title.toLowerCase().contains(lowercaseQuery) ||
          post.description.toLowerCase().contains(lowercaseQuery) ||
          post.category.name.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// ピン留めされた投稿を取得
  List<BulletinPost> getPinnedPosts() {
    if (state is! AsyncData<List<BulletinPost>>) return [];
    
    final posts = state.value!;
    return posts.where((post) => post.isPinned).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 新着投稿を取得（24時間以内）
  List<BulletinPost> getRecentPosts() {
    if (state is! AsyncData<List<BulletinPost>>) return [];
    
    final posts = state.value!;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    
    return posts.where((post) => post.createdAt.isAfter(yesterday)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// リフレッシュ
  Future<void> refresh() async {
    await loadPosts(forceRefresh: true);
  }
}

/// 最適化された掲示板プロバイダー
final optimizedBulletinProvider = StateNotifierProvider<OptimizedBulletinNotifier, AsyncValue<List<BulletinPost>>>((ref) {
  return OptimizedBulletinNotifier();
});

/// カテゴリ別投稿プロバイダー
final bulletinPostsByCategoryProvider = Provider.family<List<BulletinPost>, String?>((ref, categoryId) {
  final notifier = ref.read(optimizedBulletinProvider.notifier);
  return notifier.getPostsByCategory(categoryId);
});

/// ピン留め投稿プロバイダー
final pinnedBulletinPostsProvider = Provider<List<BulletinPost>>((ref) {
  final notifier = ref.read(optimizedBulletinProvider.notifier);
  return notifier.getPinnedPosts();
});

/// 検索プロバイダー
final bulletinSearchProvider = Provider.family<List<BulletinPost>, String>((ref, query) {
  final notifier = ref.read(optimizedBulletinProvider.notifier);
  return notifier.searchPosts(query);
});

/// 新着投稿プロバイダー
final recentBulletinPostsProvider = Provider<List<BulletinPost>>((ref) {
  final notifier = ref.read(optimizedBulletinProvider.notifier);
  return notifier.getRecentPosts();
});

/// 掲示板統計プロバイダー
final bulletinStatsProvider = Provider<BulletinStats?>((ref) {
  final state = ref.watch(optimizedBulletinProvider);
  
  return state.when(
    data: (posts) {
      final categoryStats = <String, int>{};
      int pinnedCount = 0;
      int recentCount = 0;
      
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      
      for (final post in posts) {
        // カテゴリ別統計
        categoryStats[post.category.name] = (categoryStats[post.category.name] ?? 0) + 1;
        
        // ピン留め統計
        if (post.isPinned) pinnedCount++;
        
        // 新着統計
        if (post.createdAt.isAfter(yesterday)) recentCount++;
      }
      
      return BulletinStats(
        totalPosts: posts.length,
        categoryStats: categoryStats,
        pinnedCount: pinnedCount,
        recentCount: recentCount,
      );
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// 掲示板統計モデル
class BulletinStats {
  final int totalPosts;
  final Map<String, int> categoryStats;
  final int pinnedCount;
  final int recentCount;

  BulletinStats({
    required this.totalPosts,
    required this.categoryStats,
    required this.pinnedCount,
    required this.recentCount,
  });
}