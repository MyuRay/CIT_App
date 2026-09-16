import 'package:flutter/material.dart';

import '../common/animated_image_placeholder.dart';
import '../common/safe_cached_network_image.dart';

/// 学食レビュー画面のメニュー画像（サムネイル / ヒーロー用）
class CafeteriaMenuItemImage extends StatelessWidget {
  const CafeteriaMenuItemImage({
    super.key,
    this.imageUrl,
    required this.placeholder,
    this.width,
    this.height,
    this.fontSize = 28,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final String placeholder;
  final double? width;
  final double? height;
  final double fontSize;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Text(
            placeholder,
            style: TextStyle(
              fontSize: fontSize,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth =
        width != null ? (width! * dpr).round().clamp(1, 1200) : null;
    final cacheHeight =
        height != null ? (height! * dpr).round().clamp(1, 1200) : null;

    return SafeCachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      fadeInDuration: Duration.zero,
      placeholder: AnimatedImagePlaceholder(width: width, height: height),
      errorWidget: Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.image_not_supported,
            size: fontSize + 4,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
