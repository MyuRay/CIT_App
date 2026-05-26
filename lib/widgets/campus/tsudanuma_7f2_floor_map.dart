import 'package:flutter/material.dart';

import 'narashino_local_floor_plan.dart';

const String kTsudanuma7F2FloorPlanAsset =
    'assets/images/classroom_map/tsudanuma_7_2f.png';

/// 7号館2階のフロア図（アセット画像）。
class Tsudanuma7F2SchematicMap extends StatelessWidget {
  const Tsudanuma7F2SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kTsudanuma7F2FloorPlanAsset);
  }
}

/// [FloorMapWidget] 用：7号館2階のサムネイル＋タップで全画面。
class Tsudanuma7F2FloorMapThumbnail extends StatelessWidget {
  const Tsudanuma7F2FloorMapThumbnail({
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
      assetPath: kTsudanuma7F2FloorPlanAsset,
      fullScreenTitle: '津田沼 · 7号館 2階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}
