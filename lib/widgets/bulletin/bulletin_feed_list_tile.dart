import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/comment_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/bulletin/bulletin_image_draft.dart';
import '../../models/bulletin/bulletin_model.dart';
import '../ads/sponsor_presentation.dart';
import 'bulletin_category_image.dart';
import 'bulletin_feed_card.dart';
import 'bulletin_thumbnail.dart';

/// 1列のリスト表示で使う投稿の行。カード表示より多くの投稿を1画面に並べる。
class BulletinFeedListTile extends ConsumerWidget {
  const BulletinFeedListTile({
    super.key,
    required this.post,
    required this.onTap,
  });
  final BulletinPost post;
  final VoidCallback onTap;

  static const thumbnailSize = 72.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final gold = SponsorPalette.of(context);
    final background = post.isSponsored ? gold.surface : colors.surface;
    final ink = post.isSponsored ? gold.ink : colors.onSurface;
    final secondary = AppColors.ensureContrast(
      colors.onSurfaceVariant,
      background,
    );
    final (categorySurface, categoryInk) = bulletinCategoryLabelColors(
      post.category,
      background,
      colors.primary,
    );
    final commentCount =
        post.allowComments
            ? ref
                .watch(commentStatsProvider(post.id))
                .valueOrNull
                ?.totalComments
            : null;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: background,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: post.isSponsored ? gold.border : colors.outlineVariant,
          width: post.isSponsored ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (post.isSponsored)
              SponsorBanner(name: post.sponsorName, compact: true),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox.square(
                      dimension: thumbnailSize,
                      child:
                          post.imageUrl.isEmpty
                              ? BulletinCategoryImage(category: post.category)
                              : BulletinThumbnail(
                                imageUrl: post.imageUrl,
                                crop: BulletinCrop(
                                  x: post.thumbAlignX,
                                  y: post.thumbAlignY,
                                  scale: post.thumbScale,
                                ),
                                errorWidget: ColoredBox(
                                  color: colors.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            if (post.isPinned) ...[
                              Icon(
                                Icons.push_pin_outlined,
                                size: 16,
                                color: ink,
                                semanticLabel: 'ピン留め',
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: BulletinCategoryLabel(
                                icon: bulletinCategoryIcon(post.category.icon),
                                text: post.category.name,
                                background: categorySurface,
                                foreground: categoryInk,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          post.title.trim().replaceAll(RegExp(r'\s+'), ' '),
                          key: ValueKey('bulletin-title-${post.id}'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 140),
                              child: Text(
                                post.authorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: secondary,
                                ),
                              ),
                            ),
                            Text(
                              bulletinFeedDate(post.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: secondary,
                              ),
                            ),
                            BulletinMetric(
                              icon: Icons.visibility_outlined,
                              text: '${post.viewCount}',
                              label: '閲覧 ${post.viewCount}回',
                              color: secondary,
                            ),
                            if (post.allowComments)
                              BulletinMetric(
                                icon: Icons.chat_bubble_outline_rounded,
                                text: commentCount?.toString() ?? '—',
                                label:
                                    commentCount == null
                                        ? 'コメント件数を取得中'
                                        : 'コメント $commentCount件',
                                color: secondary,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
