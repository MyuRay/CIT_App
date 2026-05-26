import 'package:flutter/material.dart';

import 'narashino_local_floor_plan.dart';

const String kTsudanuma4F3FloorPlanAsset =
    'assets/images/classroom_map/tsudanuma_4_3f.png';

/// 4号館3階のフロア図（アセット画像）。
class Tsudanuma4F3SchematicMap extends StatelessWidget {
  const Tsudanuma4F3SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kTsudanuma4F3FloorPlanAsset);
  }
}

/// [FloorMapWidget] 用：4号館3階のサムネイル＋タップで全画面。
class Tsudanuma4F3FloorMapThumbnail extends StatelessWidget {
  const Tsudanuma4F3FloorMapThumbnail({
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
      assetPath: kTsudanuma4F3FloorPlanAsset,
      fullScreenTitle: '津田沼 · 4号館 3階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}
