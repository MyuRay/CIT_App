import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/comment/comment_model.dart';
import '../../services/users/content_filter_service.dart';
import '../../core/providers/user_block_provider.dart';

/// ブロックユーザーのコメントを除外するヘルパー関数
Future<List<BulletinComment>> filterComments(
  WidgetRef ref,
  List<BulletinComment> comments,
) async {
  // ブロックユーザーIDを取得
  final hiddenUserIds = await ref.read(hiddenUserIdsProvider.future);

  // フィルタリングして返す
  return ContentFilterService.filterCommentsWithCachedIds(
    comments,
    hiddenUserIds,
  );
}

/// コメント一覧をフィルタリングして返すプロバイダー
/// 注意: 既存のコメントプロバイダと組み合わせて使用する
final filteredCommentsProvider = FutureProvider.family<List<BulletinComment>, List<BulletinComment>>(
  (ref, comments) async {
    // ブロックユーザーIDを取得
    final blockedUserIds = await ref.watch(blockedUserIdsProvider.future);

    // フィルタリングして返す
    return ContentFilterService.filterCommentsWithCachedIds(
      comments,
      blockedUserIds,
    );
  },
);
