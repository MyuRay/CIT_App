import 'package:flutter/material.dart';

import 'narashino_local_floor_plan.dart';

const String kTsudanuma4F5FloorPlanAsset =
    'assets/images/classroom_map/tsudanuma_4_5f.png';

/// 津田沼4号館5階のフロア図（アセット画像）。
class Tsudanuma4F5SchematicMap extends StatelessWidget {
  const Tsudanuma4F5SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kTsudanuma4F5FloorPlanAsset);
  }
}

/// [FloorMapWidget] 用：4号館5階のサムネイル＋タップで全画面。
class Tsudanuma4F5FloorMapThumbnail extends StatelessWidget {
  const Tsudanuma4F5FloorMapThumbnail({
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
      assetPath: kTsudanuma4F5FloorPlanAsset,
      fullScreenTitle: '津田沼 · 4号館 5階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}
