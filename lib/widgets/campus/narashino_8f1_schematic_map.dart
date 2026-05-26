import 'package:flutter/material.dart';

import 'narashino_local_floor_plan.dart';

const String kNarashino8F1FloorPlanAsset =
    'assets/images/classroom_map/narashino_8_1f.png';

const String kNarashino8F2FloorPlanAsset =
    'assets/images/classroom_map/narashino_8_2f.png';

bool narashinoBuilding8FloorUsesLocalAsset(int floor) =>
    floor == 1 || floor == 2;

/// 新習志野8号館1階のフロア図（アセット画像）。
class Narashino8F1SchematicMap extends StatelessWidget {
  const Narashino8F1SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kNarashino8F1FloorPlanAsset);
  }
}

class Narashino8F1FloorMapThumbnail extends StatelessWidget {
  const Narashino8F1FloorMapThumbnail({
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
      assetPath: kNarashino8F1FloorPlanAsset,
      fullScreenTitle: '新習志野 · 8号館1階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}

/// 新習志野8号館2階のフロア図（アセット画像）。
class Narashino8F2SchematicMap extends StatelessWidget {
  const Narashino8F2SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kNarashino8F2FloorPlanAsset);
  }
}

class Narashino8F2FloorMapThumbnail extends StatelessWidget {
  const Narashino8F2FloorMapThumbnail({
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
      assetPath: kNarashino8F2FloorPlanAsset,
      fullScreenTitle: '新習志野 · 8号館2階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}
