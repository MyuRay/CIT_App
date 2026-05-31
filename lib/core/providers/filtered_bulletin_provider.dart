import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/bulletin/bulletin_model.dart';
import '../../services/users/content_filter_service.dart';
import 'bulletin_provider.dart';
import 'user_block_provider.dart';

/// ブロックユーザーの投稿を除外した掲示板投稿プロバイダー
final filteredBulletinPostsProvider =
    Provider<AsyncValue<List<BulletinPost>>>((ref) {
  final postsAsync = ref.watch(bulletinPostsProvider);
  final hiddenAsync = ref.watch(hiddenUserIdsProvider);

  return postsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
    data: (posts) => hiddenAsync.when(
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
      data: (hiddenUserIds) => AsyncValue.data(
        ContentFilterService.filterPostsWithCachedIds(posts, hiddenUserIds),
      ),
    ),
  );
});

/// カテゴリ別かつブロックユーザー除外の投稿プロバイダー
final filteredBulletinPostsByCategoryProvider =
    Provider.family<AsyncValue<List<BulletinPost>>, String?>((ref, categoryId) {
  final postsAsync = ref.watch(bulletinPostsProvider);
  final hiddenAsync = ref.watch(hiddenUserIdsProvider);

  return postsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
    data: (posts) {
      final categoryPosts = categoryId == null
          ? posts
          : posts.where((post) => post.category.id == categoryId).toList();

      return hiddenAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (error, stack) => AsyncValue.error(error, stack),
        data: (hiddenUserIds) => AsyncValue.data(
          ContentFilterService.filterPostsWithCachedIds(
            categoryPosts,
            hiddenUserIds,
          ),
        ),
      );
    },
  );
});

final bulletinFeedHasMoreProvider = Provider<bool>((ref) {
  return ref.watch(bulletinFeedProvider).hasMore;
});

final bulletinFeedIsLoadingMoreProvider = Provider<bool>((ref) {
  return ref.watch(bulletinFeedProvider).isLoadingMore;
});
