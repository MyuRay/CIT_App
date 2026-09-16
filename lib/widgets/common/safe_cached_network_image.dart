import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// release ビルドでは [CachedNetworkImage] のディスクキャッシュ初期化を避け、
/// [Image.network] で表示する（path_provider_android 2.3.0 の PathUtils 不具合回避）。
class SafeCachedNetworkImage extends StatelessWidget {
  const SafeCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.memCacheWidth,
    this.memCacheHeight,
    this.fadeInDuration = const Duration(milliseconds: 150),
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;

  /// デコード時の最大ピクセル幅（サムネイル表示の高速化に有効）
  final int? memCacheWidth;

  /// デコード時の最大ピクセル高さ
  final int? memCacheHeight;
  final Duration fadeInDuration;
  final Widget? placeholder;
  final Widget? errorWidget;

  /// Web / release では path_provider 経由のディスクキャッシュを使わない。
  static bool get _useDirectNetwork => kIsWeb || kReleaseMode;

  @override
  Widget build(BuildContext context) {
    if (_useDirectNetwork) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        cacheWidth: memCacheWidth,
        cacheHeight: memCacheHeight,
        filterQuality:
            memCacheWidth != null ? FilterQuality.medium : FilterQuality.low,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _defaultPlaceholder();
        },
        errorBuilder:
            (context, error, stackTrace) => errorWidget ?? _defaultError(),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      maxWidthDiskCache: memCacheWidth,
      maxHeightDiskCache: memCacheHeight,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: Duration.zero,
      placeholder: (context, url) => placeholder ?? _defaultPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _defaultError(),
    );
  }

  Widget _defaultPlaceholder() {
    return SizedBox(
      width: width,
      height: height,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _defaultError() {
    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: Colors.grey.shade300,
        child: const Icon(Icons.broken_image_outlined),
      ),
    );
  }
}
