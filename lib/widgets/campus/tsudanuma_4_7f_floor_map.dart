import 'package:flutter/material.dart';

import 'narashino_local_floor_plan.dart';

const String kTsudanuma4F7FloorPlanAsset =
    'assets/images/classroom_map/tsudanuma_4_7f.png';

/// 津田沼4号館7階のフロア図（アセット画像）。
class Tsudanuma4F7SchematicMap extends StatelessWidget {
  const Tsudanuma4F7SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kTsudanuma4F7FloorPlanAsset);
  }
}

/// [FloorMapWidget] 用：4号館7階のサムネイル＋タップで全画面。
class Tsudanuma4F7FloorMapThumbnail extends StatelessWidget {
  const Tsudanuma4F7FloorMapThumbnail({
    super.key,
    this.width,
    this.height,
    this.onThumbnailTap,
  });

  final double? width;
  final double? height;
  final VoidCallback? onThumbnailTap;

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorMapThumbnail(
      assetPath: kTsudanuma4F7FloorPlanAsset,
      fullScreenTitle: '津田沼 · 4号館 7階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}
