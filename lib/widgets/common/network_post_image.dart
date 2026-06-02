import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../utils/community/post_image_utils.dart';
import 'animated_image_placeholder.dart';

/// 投稿画像用。GIF はアニメーション表示、それ以外はキャッシュ付き静止画。
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
        errorBuilder: (context, error, stackTrace) =>
            errorWidget ?? _defaultErrorWidget(),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, __) => placeholder ?? _defaultPlaceholder(),
      errorWidget: (_, __, ___) => errorWidget ?? _defaultErrorWidget(),
    );
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
        errorBuilder: (context, error, stackTrace) =>
            errorWidget ?? const Icon(Icons.broken_image_outlined, color: Colors.white54),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      placeholder: (context, url) => const AnimatedImagePlaceholder(
        width: 220,
        height: 220,
        borderRadius: 12,
        borderColor: Colors.white24,
      ),
      errorWidget: (context, url, error) =>
          errorWidget ?? const Icon(Icons.broken_image_outlined, color: Colors.white54),
    );
  }
}
