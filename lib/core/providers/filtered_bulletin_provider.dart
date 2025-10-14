import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/bulletin/bulletin_model.dart';
import '../../services/users/content_filter_service.dart';
import 'bulletin_provider.dart';
import 'user_block_provider.dart';

/// ブロックユーザーの投稿を除外した掲示板投稿プロバイダー
final filteredBulletinPostsProvider = FutureProvider<List<BulletinPost>>((ref) async {
  // 元の投稿データを取得
  final postsAsync = await ref.watch(bulletinPostsProvider.future);

  // ブロックユーザーIDを取得
  final blockedUserIds = await ref.watch(blockedUserIdsProvider.future);

  // フィルタリングして返す
  return ContentFilterService.filterPostsWithCachedIds(
    postsAsync,
    blockedUserIds,
  );
});

/// カテゴリ別かつブロックユーザー除外の投稿プロバイダー
final filteredBulletinPostsByCategoryProvider =
    FutureProvider.family<List<BulletinPost>, String?>((ref, categoryId) async {
  // カテゴリ別の投稿データを取得
  final postsAsync = await ref.watch(bulletinPostsByCategoryProvider(categoryId).future);

  // ブロックユーザーIDを取得
  final blockedUserIds = await ref.watch(blockedUserIdsProvider.future);

  // フィルタリングして返す
  return ContentFilterService.filterPostsWithCachedIds(
    postsAsync,
    blockedUserIds,
  );
});
