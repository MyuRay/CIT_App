import 'package:flutter/material.dart';

import 'narashino_local_floor_plan.dart';

const String kTsudanuma7F6FloorPlanAsset =
    'assets/images/classroom_map/tsudanuma_7_6f.png';

/// 7号館6階のフロア図（アセット画像）。
class Tsudanuma7F6SchematicMap extends StatelessWidget {
  const Tsudanuma7F6SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kTsudanuma7F6FloorPlanAsset);
  }
}

/// [FloorMapWidget] 用：7号館6階のサムネイル＋タップで全画面。
class Tsudanuma7F6FloorMapThumbnail extends StatelessWidget {
  const Tsudanuma7F6FloorMapThumbnail({
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
      assetPath: kTsudanuma7F6FloorPlanAsset,
      fullScreenTitle: '津田沼 · 7号館 6階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}
