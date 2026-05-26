import 'package:flutter/material.dart';

import 'narashino_local_floor_plan.dart';

const String kTsudanuma6F1FloorPlanAsset =
    'assets/images/classroom_map/tsudanuma_6_1f.png';

/// 6号館1階のフロア図（アセット画像）。
class Tsudanuma6F1SchematicMap extends StatelessWidget {
  const Tsudanuma6F1SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kTsudanuma6F1FloorPlanAsset);
  }
}

/// [FloorMapWidget] 用：6号館1階のサムネイル＋タップで全画面。
class Tsudanuma6F1FloorMapThumbnail extends StatelessWidget {
  const Tsudanuma6F1FloorMapThumbnail({
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
      assetPath: kTsudanuma6F1FloorPlanAsset,
      fullScreenTitle: '津田沼 · 6号館 1階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}
