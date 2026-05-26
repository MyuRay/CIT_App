import 'package:flutter/material.dart';

import 'narashino_local_floor_plan.dart';

const String kTsudanuma6F2FloorPlanAsset =
    'assets/images/classroom_map/tsudanuma_6_2f.png';

/// 6号館2階のフロア図（アセット画像）。
class Tsudanuma6F2SchematicMap extends StatelessWidget {
  const Tsudanuma6F2SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kTsudanuma6F2FloorPlanAsset);
  }
}

/// [FloorMapWidget] 用：6号館2階のサムネイル＋タップで全画面。
class Tsudanuma6F2FloorMapThumbnail extends StatelessWidget {
  const Tsudanuma6F2FloorMapThumbnail({
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
      assetPath: kTsudanuma6F2FloorPlanAsset,
      fullScreenTitle: '津田沼 · 6号館 2階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}
