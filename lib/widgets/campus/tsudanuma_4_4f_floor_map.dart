import 'package:flutter/material.dart';

import 'narashino_local_floor_plan.dart';

const String kTsudanuma4F4FloorPlanAsset =
    'assets/images/classroom_map/tsudanuma_4_4f.png';

/// 津田沼4号館4階のフロア図（アセット画像）。
class Tsudanuma4F4SchematicMap extends StatelessWidget {
  const Tsudanuma4F4SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kTsudanuma4F4FloorPlanAsset);
  }
}

/// [FloorMapWidget] 用：4号館4階のサムネイル＋タップで全画面。
class Tsudanuma4F4FloorMapThumbnail extends StatelessWidget {
  const Tsudanuma4F4FloorMapThumbnail({
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
      assetPath: kTsudanuma4F4FloorPlanAsset,
      fullScreenTitle: '津田沼 · 4号館 4階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}