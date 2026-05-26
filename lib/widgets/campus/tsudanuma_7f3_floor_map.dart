import 'package:flutter/material.dart';

import 'narashino_local_floor_plan.dart';

const String kTsudanuma7F3FloorPlanAsset =
    'assets/images/classroom_map/tsudanuma_7_3f.png';

/// 7号館3階のフロア図（アセット画像）。
class Tsudanuma7F3SchematicMap extends StatelessWidget {
  const Tsudanuma7F3SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kTsudanuma7F3FloorPlanAsset);
  }
}

/// [FloorMapWidget] 用：7号館3階のサムネイル＋タップで全画面。
class Tsudanuma7F3FloorMapThumbnail extends StatelessWidget {
  const Tsudanuma7F3FloorMapThumbnail({
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
      assetPath: kTsudanuma7F3FloorPlanAsset,
      fullScreenTitle: '津田沼 · 7号館 3階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}
