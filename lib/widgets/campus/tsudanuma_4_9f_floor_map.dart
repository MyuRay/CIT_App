import 'package:flutter/material.dart';

import 'narashino_local_floor_plan.dart';

const String kTsudanuma4F9FloorPlanAsset =
    'assets/images/classroom_map/tsudanuma_4_9f.png';

/// 津田沼4号館9階のフロア図（アセット画像）。
class Tsudanuma4F9SchematicMap extends StatelessWidget {
  const Tsudanuma4F9SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kTsudanuma4F9FloorPlanAsset);
  }
}

/// [FloorMapWidget] 用：4号館9階のサムネイル＋タップで全画面。
class Tsudanuma4F9FloorMapThumbnail extends StatelessWidget {
  const Tsudanuma4F9FloorMapThumbnail({
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
      assetPath: kTsudanuma4F9FloorPlanAsset,
      fullScreenTitle: '津田沼 · 4号館 9階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}
