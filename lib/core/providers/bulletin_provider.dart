import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../models/bulletin/bulletin_model.dart';
import 'schedule_provider.dart';

class BulletinFeedState {
  const BulletinFeedState({
    this.posts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<BulletinPost> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  BulletinFeedState copyWith({
    List<BulletinPost>? posts,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return BulletinFeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class BulletinFeedNotifier extends StateNotifier<BulletinFeedState> {
  BulletinFeedNotifier(this._ref) : super(const BulletinFeedState()) {
    _ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous != next) {
        refresh();
      }
    });
    if (_ref.read(currentUserIdProvider) != null) {
      refresh();
    }
  }

  final Ref _ref;
  QueryDocumentSnapshot<Map<String, dynamic>>? _lastDocument;

  Future<void> refresh() async {
    if (_ref.read(currentUserIdProvider) == null) {
      _lastDocument = null;
      state = const BulletinFeedState();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    _lastDocument = null;

    try {
      final page = await _fetchPage();
      state = BulletinFeedState(
        posts: _sortPosts(page.posts),
        hasMore: page.hasMore,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  Future<void> loadMore() async {
    if (_ref.read(currentUserIdProvider) == null) return;
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final page = await _fetchPage();
      final merged = _mergePosts(state.posts, page.posts);
      state = state.copyWith(
        posts: _sortPosts(merged),
        isLoadingMore: false,
        hasMore: page.hasMore,
      );
    } catch (error) {
      state = state.copyWith(isLoadingMore: false, error: error);
    }
  }

  Future<({List<BulletinPost> posts, bool hasMore})> _fetchPage() async {
    var query = FirebaseFirestore.instance
        .collection('bulletin_posts')
        .where('approvalStatus', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.postPageSize + 1);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final snapshot = await query.get();
    final docs = snapshot.docs;
    final hasMore = docs.length > AppConstants.postPageSize;
    final pageDocs =
        hasMore ? docs.sublist(0, AppConstants.postPageSize) : docs;

    if (pageDocs.isNotEmpty) {
      _lastDocument = pageDocs.last;
    }

    final posts = <BulletinPost>[];
    for (final doc in pageDocs) {
      try {
        final post = BulletinPost.fromJson({'id': doc.id, ...doc.data()});
        if (post.isActive) {
          posts.add(post);
        }
      } catch (_) {
        // 壊れたドキュメントはスキップ
      }
    }

    return (posts: posts, hasMore: hasMore);
  }

  List<BulletinPost> _mergePosts(
    List<BulletinPost> current,
    List<BulletinPost> incoming,
  ) {
    if (incoming.isEmpty) return current;
    final seen = current.map((post) => post.id).toSet();
    final merged = List<BulletinPost>.from(current);
    for (final post in incoming) {
      if (seen.add(post.id)) {
        merged.add(post);
      }
    }
    return merged;
  }

  List<BulletinPost> _sortPosts(List<BulletinPost> posts) {
    final sorted = List<BulletinPost>.from(posts);
    sorted.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  }
}

final bulletinFeedProvider =
    StateNotifierProvider<BulletinFeedNotifier, BulletinFeedState>((ref) {
  return BulletinFeedNotifier(ref);
});

/// 読み込み済み掲示板投稿（ページネーション対応）
final bulletinPostsProvider = Provider<AsyncValue<List<BulletinPost>>>((ref) {
  final feed = ref.watch(bulletinFeedProvider);
  if (feed.isLoading && feed.posts.isEmpty) {
    return const AsyncValue.loading();
  }
  if (feed.error != null && feed.posts.isEmpty) {
    return AsyncValue.error(feed.error!, StackTrace.current);
  }
  return AsyncValue.data(feed.posts);
});

/// 掲示板 NEW バッジ用（最新1件）
final bulletinLatestPostCreatedAtProvider = StreamProvider<DateTime?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection('bulletin_posts')
      .where('approvalStatus', isEqualTo: 'approved')
      .orderBy('createdAt', descending: true)
      .limit(1)
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) return null;
    final createdAt = snapshot.docs.first.data()['createdAt'];
    if (createdAt is Timestamp) return createdAt.toDate();
    return null;
  });
});

final bulletinPostsByCategoryProvider =
    Provider.family<List<BulletinPost>, String?>((ref, categoryId) {
  final posts = ref.watch(bulletinPostsProvider).valueOrNull ?? const [];
  if (categoryId == null) return posts;
  return posts.where((post) => post.category.id == categoryId).toList();
});

final pinnedBulletinPostsProvider = Provider<List<BulletinPost>>((ref) {
  final posts = ref.watch(bulletinPostsProvider).valueOrNull ?? const [];
  return posts.where((post) => post.isPinned).toList();
});

final popularBulletinPostsProvider = Provider<List<BulletinPost>>((ref) {
  final posts = ref.watch(bulletinPostsProvider).valueOrNull ?? const [];
  final sortedPosts = List<BulletinPost>.from(posts);
  sortedPosts.sort((a, b) => b.viewCount.compareTo(a.viewCount));
  return sortedPosts.take(5).toList();
});
