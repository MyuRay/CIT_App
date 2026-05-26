import 'package:flutter/material.dart';

import 'narashino_local_floor_plan.dart';

const String kTsudanuma4F8FloorPlanAsset =
    'assets/images/classroom_map/tsudanuma_4_8f.png';

/// 津田沼4号館8階のフロア図（アセット画像）。
class Tsudanuma4F8SchematicMap extends StatelessWidget {
  const Tsudanuma4F8SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kTsudanuma4F8FloorPlanAsset);
  }
}

/// [FloorMapWidget] 用：4号館8階のサムネイル＋タップで全画面。
class Tsudanuma4F8FloorMapThumbnail extends StatelessWidget {
  const Tsudanuma4F8FloorMapThumbnail({
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
      assetPath: kTsudanuma4F8FloorPlanAsset,
      fullScreenTitle: '津田沼 · 4号館 8階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}
