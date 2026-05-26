import 'package:flutter/material.dart';

import 'narashino_local_floor_plan.dart';

const String kNarashino12F1FloorPlanAsset =
    'assets/images/classroom_map/narashino_12_1f.png';

const String kNarashino12F2FloorPlanAsset =
    'assets/images/classroom_map/narashino_12_2f.png';

const String kNarashino12F3FloorPlanAsset =
    'assets/images/classroom_map/narashino_12_3f.png';

const String kNarashino12F4FloorPlanAsset =
    'assets/images/classroom_map/narashino_12_4f.png';

const String kNarashino12F5FloorPlanAsset =
    'assets/images/classroom_map/narashino_12_5f.png';

const String kNarashino12F6FloorPlanAsset =
    'assets/images/classroom_map/narashino_12_6f.png';

const String kNarashino12F7FloorPlanAsset =
    'assets/images/classroom_map/narashino_12_7f.png';

const String kNarashino12F8FloorPlanAsset =
    'assets/images/classroom_map/narashino_12_8f.png';

bool narashinoBuilding12FloorUsesLocalAsset(int floor) =>
    floor == 1 ||
    floor == 2 ||
    floor == 3 ||
    floor == 4 ||
    floor == 5 ||
    floor == 6 ||
    floor == 7 ||
    floor == 8;

/// 新習志野12号館1階のフロア図（アセット画像）。
class Narashino12F1SchematicMap extends StatelessWidget {
  const Narashino12F1SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kNarashino12F1FloorPlanAsset);
  }
}

class Narashino12F1FloorMapThumbnail extends StatelessWidget {
  const Narashino12F1FloorMapThumbnail({
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
      assetPath: kNarashino12F1FloorPlanAsset,
      fullScreenTitle: '新習志野 · 12号館1階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}

/// 新習志野12号館2階のフロア図（アセット画像）。
class Narashino12F2SchematicMap extends StatelessWidget {
  const Narashino12F2SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kNarashino12F2FloorPlanAsset);
  }
}

class Narashino12F2FloorMapThumbnail extends StatelessWidget {
  const Narashino12F2FloorMapThumbnail({
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
      assetPath: kNarashino12F2FloorPlanAsset,
      fullScreenTitle: '新習志野 · 12号館2階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}

/// 新習志野12号館3階のフロア図（アセット画像）。
class Narashino12F3SchematicMap extends StatelessWidget {
  const Narashino12F3SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kNarashino12F3FloorPlanAsset);
  }
}

class Narashino12F3FloorMapThumbnail extends StatelessWidget {
  const Narashino12F3FloorMapThumbnail({
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
      assetPath: kNarashino12F3FloorPlanAsset,
      fullScreenTitle: '新習志野 · 12号館3階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}

/// 新習志野12号館4階のフロア図（アセット画像）。
class Narashino12F4SchematicMap extends StatelessWidget {
  const Narashino12F4SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kNarashino12F4FloorPlanAsset);
  }
}

class Narashino12F4FloorMapThumbnail extends StatelessWidget {
  const Narashino12F4FloorMapThumbnail({
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
      assetPath: kNarashino12F4FloorPlanAsset,
      fullScreenTitle: '新習志野 · 12号館4階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}

/// 新習志野12号館5階のフロア図（アセット画像）。
class Narashino12F5SchematicMap extends StatelessWidget {
  const Narashino12F5SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kNarashino12F5FloorPlanAsset);
  }
}

class Narashino12F5FloorMapThumbnail extends StatelessWidget {
  const Narashino12F5FloorMapThumbnail({
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
      assetPath: kNarashino12F5FloorPlanAsset,
      fullScreenTitle: '新習志野 · 12号館5階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}

/// 新習志野12号館6階のフロア図（アセット画像）。
class Narashino12F6SchematicMap extends StatelessWidget {
  const Narashino12F6SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kNarashino12F6FloorPlanAsset);
  }
}

class Narashino12F6FloorMapThumbnail extends StatelessWidget {
  const Narashino12F6FloorMapThumbnail({
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
      assetPath: kNarashino12F6FloorPlanAsset,
      fullScreenTitle: '新習志野 · 12号館6階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}

/// 新習志野12号館7階のフロア図（アセット画像）。
class Narashino12F7SchematicMap extends StatelessWidget {
  const Narashino12F7SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kNarashino12F7FloorPlanAsset);
  }
}

class Narashino12F7FloorMapThumbnail extends StatelessWidget {
  const Narashino12F7FloorMapThumbnail({
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
      assetPath: kNarashino12F7FloorPlanAsset,
      fullScreenTitle: '新習志野 · 12号館7階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}

/// 新習志野12号館8階のフロア図（アセット画像）。
class Narashino12F8SchematicMap extends StatelessWidget {
  const Narashino12F8SchematicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return NarashinoAssetFloorPlanImage(assetPath: kNarashino12F8FloorPlanAsset);
  }
}

class Narashino12F8FloorMapThumbnail extends StatelessWidget {
  const Narashino12F8FloorMapThumbnail({
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
      assetPath: kNarashino12F8FloorPlanAsset,
      fullScreenTitle: '新習志野 · 12号館8階',
      width: width,
      height: height,
      onThumbnailTap: onThumbnailTap,
    );
  }
}
