import 'package:flutter/material.dart';

import 'narashino_local_floor_plan.dart';

const String kTsudanuma7F5FloorPlanAsset =
    'assets/images/classroom_map/tsudanuma_7_5f.png';

/// 7号館5階のフロア図（アセット画像）。
class Tsudanuma7F5SchematicMap extends StatelessWidget {
  const Tsudanuma7F5SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kTsudanuma7F5FloorPlanAsset);
  }
}

/// [FloorMapWidget] 用：7号館5階のサムネイル＋タップで全画面。
class Tsudanuma7F5FloorMapThumbnail extends StatelessWidget {
  const Tsudanuma7F5FloorMapThumbnail({
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
      assetPath: kTsudanuma7F5FloorPlanAsset,
      fullScreenTitle: '津田沼 · 7号館 5階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}
