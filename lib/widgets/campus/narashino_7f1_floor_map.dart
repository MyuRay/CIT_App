import 'package:flutter/material.dart';

import 'narashino_local_floor_plan.dart';

const String kNarashino7F1FloorPlanAsset =
    'assets/images/classroom_map/narashino_7_1f.png';

const String kNarashino7F2FloorPlanAsset =
    'assets/images/classroom_map/narashino_7_2f.png';

bool narashinoBuilding7FloorUsesLocalAsset(int floor) => floor == 1 || floor == 2;

/// 新習志野7号館1階のフロア図（アセット画像）。
class Narashino7F1SchematicMap extends StatelessWidget {
  const Narashino7F1SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kNarashino7F1FloorPlanAsset);
  }
}

class Narashino7F1FloorMapThumbnail extends StatelessWidget {
  const Narashino7F1FloorMapThumbnail({
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
      assetPath: kNarashino7F1FloorPlanAsset,
      fullScreenTitle: '新習志野 · 7号館1階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}

/// 新習志野7号館2階のフロア図（アセット画像）。
class Narashino7F2SchematicMap extends StatelessWidget {
  const Narashino7F2SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kNarashino7F2FloorPlanAsset);
  }
}

class Narashino7F2FloorMapThumbnail extends StatelessWidget {
  const Narashino7F2FloorMapThumbnail({
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
      assetPath: kNarashino7F2FloorPlanAsset,
      fullScreenTitle: '新習志野 · 7号館2階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}
