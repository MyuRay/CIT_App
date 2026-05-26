import 'package:flutter/material.dart';

import 'narashino_local_floor_plan.dart';

const String kTsudanuma7F4FloorPlanAsset =
    'assets/images/classroom_map/tsudanuma_7_4f.png';

/// 7号館4階のフロア図（アセット画像）。
class Tsudanuma7F4SchematicMap extends StatelessWidget {
  const Tsudanuma7F4SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kTsudanuma7F4FloorPlanAsset);
  }
}

/// [FloorMapWidget] 用：7号館4階のサムネイル＋タップで全画面。
class Tsudanuma7F4FloorMapThumbnail extends StatelessWidget {
  const Tsudanuma7F4FloorMapThumbnail({
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
      assetPath: kTsudanuma7F4FloorPlanAsset,
      fullScreenTitle: '津田沼 · 7号館 4階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}
