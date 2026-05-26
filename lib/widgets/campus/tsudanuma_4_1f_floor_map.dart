import 'package:flutter/material.dart';

import 'narashino_local_floor_plan.dart';

const String kTsudanuma4F1FloorPlanAsset =
    'assets/images/classroom_map/tsudanuma_4_1f.png';

/// 4号館1階のフロア図（アセット画像）。
class Tsudanuma4F1SchematicMap extends StatelessWidget {
  const Tsudanuma4F1SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kTsudanuma4F1FloorPlanAsset);
  }
}

/// [FloorMapWidget] 用：4号館1階のサムネイル＋タップで全画面。
class Tsudanuma4F1FloorMapThumbnail extends StatelessWidget {
  const Tsudanuma4F1FloorMapThumbnail({
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
      assetPath: kTsudanuma4F1FloorPlanAsset,
      fullScreenTitle: '津田沼 · 4号館 1階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}
