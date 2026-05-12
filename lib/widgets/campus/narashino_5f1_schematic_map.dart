import 'package:flutter/material.dart';

import 'narashino_local_floor_plan.dart';

const String kNarashino5F1FloorPlanAsset =
    'assets/images/classroom_map/narashino_5_1f.png';

const String kNarashino5F2FloorPlanAsset =
    'assets/images/classroom_map/narashino_5_2f.png';

const String kNarashino5F3FloorPlanAsset =
    'assets/images/classroom_map/narashino_5_3f.png';

bool narashinoBuilding5FloorUsesLocalAsset(int floor) =>
    floor == 1 || floor == 2 || floor == 3;

/// 新習志野5号館1階のフロア図（アセット画像）。
class Narashino5F1SchematicMap extends StatelessWidget {
  const Narashino5F1SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kNarashino5F1FloorPlanAsset);
  }
}

class Narashino5F1FloorMapThumbnail extends StatelessWidget {
  const Narashino5F1FloorMapThumbnail({
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
      assetPath: kNarashino5F1FloorPlanAsset,
      fullScreenTitle: '新習志野 · 5号館1階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}

/// 新習志野5号館2階のフロア図（アセット画像）。
class Narashino5F2SchematicMap extends StatelessWidget {
  const Narashino5F2SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kNarashino5F2FloorPlanAsset);
  }
}

class Narashino5F2FloorMapThumbnail extends StatelessWidget {
  const Narashino5F2FloorMapThumbnail({
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
      assetPath: kNarashino5F2FloorPlanAsset,
      fullScreenTitle: '新習志野 · 5号館2階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}

/// 新習志野5号館3階のフロア図（アセット画像）。
class Narashino5F3SchematicMap extends StatelessWidget {
  const Narashino5F3SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kNarashino5F3FloorPlanAsset);
  }
}

class Narashino5F3FloorMapThumbnail extends StatelessWidget {
  const Narashino5F3FloorMapThumbnail({
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
      assetPath: kNarashino5F3FloorPlanAsset,
      fullScreenTitle: '新習志野 · 5号館3階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}
