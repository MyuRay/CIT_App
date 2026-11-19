import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/cwitter_quote_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/user_block_provider.dart';
import '../../../models/community/cwitter_post.dart';
import '../../../widgets/common/firebase_storage_image.dart';
import 'cwitter_author_name_row.dart';
import 'cwitter_handle_text.dart';

/// コピーした本文ではなく、引用先を監視して削除・非表示も反映する。
/// 引用の中の引用は展開せず、元投稿を開いて読む。
class CwitterQuotedPost extends ConsumerWidget {
  const CwitterQuotedPost({super.key, required this.postId, this.onOpen});

  final String postId;
  final ValueChanged<CwitterPost>? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final source = ref.watch(visibleCwitterQuotedPostProvider(postId));
    return Material(
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: source.when(
        skipLoadingOnRefresh: false,
        skipLoadingOnReload: false,
        loading:
            () => const Padding(
              padding: EdgeInsets.all(12),
              child: Text('引用元を読み込み中…'),
            ),
        error:
            (_, __) => Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('引用元を読み込めませんでした'),
                  TextButton(
                    onPressed: () {
                      ref.invalidate(cwitterQuotedPostProvider(postId));
                      ref.invalidate(hiddenUserIdsProvider);
                    },
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            ),
        data: (post) {
          if (post == null) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: Text('元のCweetは削除されたか、表示できません'),
            );
          }
          final name = resolveAuthorDisplayName(
            ref.watch(
              authorDisplayNameProvider((
                authorId: post.authorId,
                fallback: post.displayName,
              )),
            ),
            post.displayName,
          );
          return InkWell(
            onTap: onOpen == null ? null : () => onOpen!(post),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CwitterAuthorNameRow(
                    displayName: name,
                    cwitterId: post.cwitterId,
                    compact: true,
                  ),
                  CwitterHandleText(
                    cwitterId: post.cwitterId,
                    showOfficialTag: false,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  if (post.body.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      post.body,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (post.hasImages) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: FirebaseStorageImage(
                        imageUrl: post.imageUrls.first,
                        width: double.infinity,
                        height: 120,
                      ),
                    ),
                    if (post.imageUrls.length > 1)
                      Text('画像 ${post.imageUrls.length}枚'),
                  ],
                  if (post.hasPoll) ...[
                    const SizedBox(height: 8),
                    const Text('投票付きのCweet'),
                  ],
                  if (post.isQuote) ...[
                    const SizedBox(height: 8),
                    const Text('引用recweet'),
                  ],
                  if (onOpen != null) ...[
                    const SizedBox(height: 8),
                    Text('元のCweetを見る', style: TextStyle(color: colors.primary)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
