import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/comment_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/bulletin/bulletin_image_draft.dart';
import '../../models/bulletin/bulletin_model.dart';
import '../ads/sponsor_presentation.dart';
import 'bulletin_thumbnail.dart';

IconData bulletinCategoryIcon(String name) => switch (name) {
  'event' => Icons.event_outlined,
  'group' => Icons.groups_outlined,
  'school' => Icons.school_outlined,
  'announcement' => Icons.campaign_outlined,
  'work' => Icons.work_outline,
  'local_offer' => Icons.local_offer_outlined,
  _ => Icons.more_horiz,
};

/// Compact feed summary; the detail screen retains the complete post.
class BulletinFeedCard extends ConsumerWidget {
  const BulletinFeedCard({super.key, required this.post, required this.onTap});
  final BulletinPost post;
  final VoidCallback onTap;

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
    final categorySeed = Color(
      int.tryParse(post.category.color.replaceFirst('#', 'ff'), radix: 16) ??
          colors.primary.toARGB32(),
    );
    final categorySurface = Color.alphaBlend(
      categorySeed.withValues(alpha: .10),
      background,
    );
    final categoryInk = AppColors.ensureContrast(categorySeed, categorySurface);
    final imageCount = post.galleryImageUrls.length;
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
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: post.isSponsored ? gold.border : colors.outlineVariant,
          width: post.isSponsored ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.isSponsored)
              SponsorBanner(name: post.sponsorName, compact: true),
            if (post.imageUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    BulletinThumbnail(
                      imageUrl: post.imageUrl,
                      crop: BulletinCrop(
                        x: post.thumbAlignX,
                        y: post.thumbAlignY,
                        scale: post.thumbScale,
                      ),
                      errorWidget: ColoredBox(
                        color: colors.surfaceContainerHighest,
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: colors.onSurfaceVariant,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    if (imageCount > 1)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.collections_outlined,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '$imageCount枚',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        child: _Label(
                          icon: bulletinCategoryIcon(post.category.icon),
                          text: post.category.name,
                          background: categorySurface,
                          foreground: categoryInk,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    post.title.trim().replaceAll(RegExp(r'\s+'), ' '),
                    key: ValueKey('bulletin-title-${post.id}'),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      color: ink,
                    ),
                  ),
                  if (post.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      post.description.trim().replaceAll(RegExp(r'\s+'), ' '),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: secondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          post.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        _date(post.createdAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: secondary,
                        ),
                      ),
                      _Metric(
                        icon: Icons.visibility_outlined,
                        text: '${post.viewCount}',
                        label: '閲覧 ${post.viewCount}回',
                        color: secondary,
                      ),
                      if (post.allowComments)
                        _Metric(
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
    );
  }

  String _date(DateTime value) =>
      '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';
}

class _Label extends StatelessWidget {
  const _Label({
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
  });
  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.text,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String text;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    ),
  );
}
