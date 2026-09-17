import 'package:flutter/material.dart';
import 'common/safe_cached_network_image.dart';

/// Bundled maps stay usable while online maps load or when a download fails.
class CampusMapImage extends StatelessWidget {
  const CampusMapImage({
    super.key,
    required this.campus,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final String campus;
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(
      'assets/images/campus_maps/${campus}_campus_map.png',
      width: width,
      height: height,
      fit: fit,
      gaplessPlayback: true,
    );
    if (imageUrl.isEmpty) return fallback;
    return SafeCachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: fallback,
      errorWidget: fallback,
    );
  }
}
