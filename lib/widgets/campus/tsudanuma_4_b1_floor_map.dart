import 'package:flutter/material.dart';

import 'narashino_local_floor_plan.dart';

const String kTsudanuma4B1FloorPlanAsset =
    'assets/images/classroom_map/tsudanuma_4_b1.png';

/// 4号館B1のフロア図（アセット画像）。
class Tsudanuma4B1SchematicMap extends StatelessWidget {
  const Tsudanuma4B1SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kTsudanuma4B1FloorPlanAsset);
  }
}

/// [FloorMapWidget] 用：4号館B1のサムネイル＋タップで全画面。
class Tsudanuma4B1FloorMapThumbnail extends StatelessWidget {
  const Tsudanuma4B1FloorMapThumbnail({
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
      assetPath: kTsudanuma4B1FloorPlanAsset,
      fullScreenTitle: '津田沼 · 4号館 B1',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}
