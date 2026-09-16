import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../models/bulletin/bulletin_model.dart';
import '../../services/bulletin/bulletin_feed_service.dart';
import 'schedule_provider.dart';

final bulletinFeedServiceProvider = Provider(
  (ref) => BulletinFeedService(FirebaseFirestore.instance),
);

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
        state = const BulletinFeedState();
        refresh();
      }
    });
    if (_ref.read(currentUserIdProvider) != null) {
      refresh();
    }
  }

  final Ref _ref;
  StreamSubscription<BulletinFeedBatch>? _subscription;
  Completer<void>? _pending;
  int _generation = 0;
  int _recentLimit = AppConstants.postPageSize;

  Future<void> refresh() => _watch(AppConstants.postPageSize, refreshing: true);

  Future<void> loadMore() async {
    if (_ref.read(currentUserIdProvider) == null) return;
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    await _watch(_recentLimit + AppConstants.postPageSize, refreshing: false);
  }

  Future<void> _watch(int limit, {required bool refreshing}) {
    final generation = ++_generation;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _finishPending();

    if (_ref.read(currentUserIdProvider) == null) {
      _recentLimit = AppConstants.postPageSize;
      state = const BulletinFeedState(hasMore: false);
      return Future.value();
    }

    final pending = Completer<void>();
    _pending = pending;
    state = state.copyWith(
      isLoading: refreshing,
      isLoadingMore: !refreshing,
      clearError: true,
    );
    void fail(Object error) {
      if (!mounted || generation != _generation) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: error,
      );
      _finishPending();
    }

    try {
      _subscription = _ref
          .read(bulletinFeedServiceProvider)
          .watchFeed(recentLimit: limit)
          .listen((batch) {
            if (!mounted || generation != _generation) return;
            _recentLimit = limit;
            state = BulletinFeedState(
              posts: batch.posts,
              hasMore: batch.hasMore,
            );
            _finishPending();
          }, onError: (Object error, StackTrace stack) => fail(error));
    } catch (error) {
      fail(error);
    }
    return pending.future;
  }

  void _finishPending() {
    final pending = _pending;
    if (pending != null && !pending.isCompleted) pending.complete();
    _pending = null;
  }

  @override
  void dispose() {
    _generation++;
    unawaited(_subscription?.cancel());
    _finishPending();
    super.dispose();
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
