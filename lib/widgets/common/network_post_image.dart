import 'package:flutter/material.dart';

import '../../utils/community/post_image_utils.dart';
import 'animated_image_placeholder.dart';
import 'safe_cached_network_image.dart';

/// 投稿画像用（Cwitter / ちばちゃんねる等）。学食メニューと同じ URL 表示方式。
class NetworkPostImage extends StatelessWidget {
  const NetworkPostImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    if (isGifUrl(imageUrl)) {
      return Image.network(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _defaultPlaceholder();
        },
        errorBuilder:
            (context, error, stackTrace) =>
                errorWidget ?? _defaultErrorWidget(),
      );
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = _cacheDimension(width, dpr);
    final cacheHeight = _cacheDimension(height, dpr);

    return SafeCachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      fadeInDuration: Duration.zero,
      placeholder: placeholder ?? _defaultPlaceholder(),
      errorWidget: errorWidget ?? _defaultErrorWidget(),
    );
  }

  int? _cacheDimension(double? logicalSize, double dpr) {
    if (logicalSize == null || !logicalSize.isFinite) return null;
    return (logicalSize * dpr).round().clamp(1, 1200);
  }

  Widget _defaultPlaceholder() {
    return ColoredBox(
      color: Colors.grey.shade200,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _defaultErrorWidget() {
    return ColoredBox(
      color: Colors.grey.shade300,
      child: const Icon(Icons.broken_image_outlined),
    );
  }
}

/// フルスクリーン表示用。GIF はアニメーション表示。
class NetworkPostImageFullscreen extends StatelessWidget {
  const NetworkPostImageFullscreen({
    super.key,
    required this.imageUrl,
    this.errorWidget,
  });

  final String imageUrl;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    if (isGifUrl(imageUrl)) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const AnimatedImagePlaceholder(
            width: 220,
            height: 220,
            borderRadius: 12,
            borderColor: Colors.white24,
          );
        },
        errorBuilder:
            (context, error, stackTrace) =>
                errorWidget ??
                const Icon(Icons.broken_image_outlined, color: Colors.white54),
      );
    }

    return SafeCachedNetworkImage(
      imageUrl: imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      placeholder: const AnimatedImagePlaceholder(
        width: 220,
        height: 220,
        borderRadius: 12,
        borderColor: Colors.white24,
      ),
      errorWidget:
          errorWidget ??
          const Icon(Icons.broken_image_outlined, color: Colors.white54),
    );
  }
}
