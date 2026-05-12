import 'package:flutter/material.dart';

import 'narashino_local_floor_plan.dart';

const String kTsudanuma7F8FloorPlanAsset =
    'assets/images/classroom_map/tsudanuma_7_8f.png';

/// 7号館8階のフロア図（アセット画像）。
class Tsudanuma7F8SchematicMap extends StatelessWidget {
  const Tsudanuma7F8SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kTsudanuma7F8FloorPlanAsset);
  }
}

/// [FloorMapWidget] 用：7号館8階のサムネイル＋タップで全画面。
class Tsudanuma7F8FloorMapThumbnail extends StatelessWidget {
  const Tsudanuma7F8FloorMapThumbnail({
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
      assetPath: kTsudanuma7F8FloorPlanAsset,
      fullScreenTitle: '津田沼 · 7号館 8階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}
