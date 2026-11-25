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

/// 1列のリスト表示で使う投稿の行。1画面に多く並ぶよう、縦幅を抑えている。
class BulletinFeedListTile extends ConsumerWidget {
  const BulletinFeedListTile({
    super.key,
    required this.post,
    required this.onTap,
  });
  final BulletinPost post;
  final VoidCallback onTap;

  static const thumbnailSize = 56.0;

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
    // 背景を敷かない文字だけのラベルなので、行の背景に対して色を決める。
    final (_, categoryInk) = bulletinCategoryLabelColors(
      post.category,
      background,
      colors.primary,
    );
    final small = theme.textTheme.bodySmall?.copyWith(color: secondary);
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
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: post.isSponsored ? gold.border : colors.outlineVariant,
          width: post.isSponsored ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
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
                                size: 20,
                              ),
                            ),
                          ),
                ),
              ),
              const SizedBox(width: 10),
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
                            size: 14,
                            color: ink,
                            semanticLabel: 'ピン留め',
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (post.isSponsored) ...[
                          Icon(
                            Icons.workspace_premium_outlined,
                            size: 13,
                            color: gold.ink,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '広告',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: gold.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Icon(
                          bulletinCategoryIcon(post.category.icon),
                          size: 13,
                          color: categoryInk,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            post.category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: categoryInk,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(bulletinFeedDate(post.createdAt), style: small),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      post.title.trim().replaceAll(RegExp(r'\s+'), ' '),
                      key: ValueKey('bulletin-title-${post.id}'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.isSponsored &&
                                    post.sponsorName.trim().isNotEmpty
                                ? post.sponsorName.trim()
                                : post.authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: small,
                          ),
                        ),
                        const SizedBox(width: 10),
                        BulletinMetric(
                          icon: Icons.visibility_outlined,
                          text: '${post.viewCount}',
                          label: '閲覧 ${post.viewCount}回',
                          color: secondary,
                        ),
                        if (post.allowComments) ...[
                          const SizedBox(width: 10),
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
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
