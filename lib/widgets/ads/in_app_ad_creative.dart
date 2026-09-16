import 'package:flutter/material.dart';
import '../../models/ads/in_app_ad_model.dart';
import 'sponsor_presentation.dart';

/// Pure presentation: admin previews do not log impressions or follow links.
class InAppAdCreative extends StatelessWidget {
  const InAppAdCreative({super.key, required this.ad, this.onTap, this.margin});
  final InAppAd ad;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = SponsorPalette.of(context);
    final hasImage = ad.imageUrl?.trim().isNotEmpty ?? false;
    return Card(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color:
          ad.isSponsored ? gold.surface : theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color:
              ad.isSponsored ? gold.border : theme.colorScheme.outlineVariant,
          width: ad.isSponsored ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ad.isSponsored) SponsorBanner(name: ad.sponsorName),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasImage) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        ad.imageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => SizedBox(
                              width: 56,
                              height: 56,
                              child: Icon(
                                Icons.image_outlined,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!ad.isSponsored)
                          Text('広告', style: theme.textTheme.labelSmall),
                        Text(
                          ad.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ad.isSponsored ? gold.ink : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ad.body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                ad.isSponsored
                                    ? gold.ink
                                    : theme.colorScheme.onSurfaceVariant,
                          ),
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
