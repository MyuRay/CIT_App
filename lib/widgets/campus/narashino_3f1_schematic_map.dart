import 'package:flutter/material.dart';

import 'narashino_local_floor_plan.dart';

const String kNarashino3F1FloorPlanAsset =
    'assets/images/classroom_map/narashino_3_1f.png';

/// 新習志野3号館2階（同梱アセット）。
const String kNarashino3F2FloorPlanAsset =
    'assets/images/classroom_map/narashino_3_2f.png';

const String kNarashino3F3FloorPlanAsset =
    'assets/images/classroom_map/narashino_3_3f.png';

bool narashinoBuilding3FloorUsesLocalAsset(int floor) =>
    floor == 1 || floor == 2 || floor == 3;

class Narashino3F1SchematicMap extends StatelessWidget {
  const Narashino3F1SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kNarashino3F1FloorPlanAsset);
  }
}

class Narashino3F1FloorMapThumbnail extends StatelessWidget {
  const Narashino3F1FloorMapThumbnail({
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
      assetPath: kNarashino3F1FloorPlanAsset,
      fullScreenTitle: '新習志野 · 3号館1階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}

/// 新習志野3号館2階のフロア図（アセット画像）。
class Narashino3F2SchematicMap extends StatelessWidget {
  const Narashino3F2SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kNarashino3F2FloorPlanAsset);
  }
}

class Narashino3F2FloorMapThumbnail extends StatelessWidget {
  const Narashino3F2FloorMapThumbnail({
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
      assetPath: kNarashino3F2FloorPlanAsset,
      fullScreenTitle: '新習志野 · 3号館2階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}

/// 新習志野3号館3階のフロア図（アセット画像）。
class Narashino3F3SchematicMap extends StatelessWidget {
  const Narashino3F3SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kNarashino3F3FloorPlanAsset);
  }
}

class Narashino3F3FloorMapThumbnail extends StatelessWidget {
  const Narashino3F3FloorMapThumbnail({
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
      assetPath: kNarashino3F3FloorPlanAsset,
      fullScreenTitle: '新習志野 · 3号館3階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}
