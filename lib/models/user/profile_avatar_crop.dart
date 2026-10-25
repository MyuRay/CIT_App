import 'dart:math' as math;
import 'dart:ui';

/// 原画像は全体表示のまま、円形マスクの位置と大きさで切り抜く。
class ProfileAvatarCrop {
  const ProfileAvatarCrop({
    this.centerNormX = 0.5,
    this.centerNormY = 0.5,
    this.radiusFraction = defaultRadiusFraction,
  });

  /// 表示画像矩形内での円中心（0〜1）。
  final double centerNormX;
  final double centerNormY;

  /// 最大半径に対する比率（小さいほど狭い範囲を切り抜き）。
  static const double minRadiusFraction = 0.35;
  static const double maxRadiusFraction = 1.0;
  static const double defaultRadiusFraction = 1.0;

  final double radiusFraction;
}

/// 編集画面で原画像をやや大きく見せる倍率（比率は維持、はみ出しはクリップ）。
const double profileAvatarDisplayScaleBoost = 1.2;

Rect profileAvatarImageDisplayRect(Size viewport, Size image) {
  final base =
      math.min(
        viewport.width / image.width,
        viewport.height / image.height,
      ) *
      profileAvatarDisplayScaleBoost;
  final dw = image.width * base;
  final dh = image.height * base;
  return Rect.fromLTWH(
    (viewport.width - dw) / 2,
    (viewport.height - dh) / 2,
    dw,
    dh,
  );
}

double profileAvatarMaxCircleRadius(Rect displayRect) {
  return math.min(displayRect.width, displayRect.height) / 2;
}

Offset profileAvatarCircleCenter(Rect displayRect, ProfileAvatarCrop crop) {
  return Offset(
    displayRect.left + displayRect.width * crop.centerNormX,
    displayRect.top + displayRect.height * crop.centerNormY,
  );
}

double profileAvatarCircleRadius(Rect displayRect, ProfileAvatarCrop crop) {
  final fraction = crop.radiusFraction.clamp(
    ProfileAvatarCrop.minRadiusFraction,
    ProfileAvatarCrop.maxRadiusFraction,
  );
  return profileAvatarMaxCircleRadius(displayRect) * fraction;
}

Rect profileAvatarCropSquareRect(Rect displayRect, ProfileAvatarCrop crop) {
  final center = profileAvatarCircleCenter(displayRect, crop);
  final radius = profileAvatarCircleRadius(displayRect, crop);
  return Rect.fromCenter(
    center: center,
    width: radius * 2,
    height: radius * 2,
  );
}

enum ProfileAvatarCropCorner { topLeft, topRight, bottomLeft, bottomRight }

/// 四隅の太線付近タッチ判定（ビューポート座標）。
ProfileAvatarCropCorner? profileAvatarCropCornerAt(
  Offset viewportPoint,
  Rect displayRect,
  ProfileAvatarCrop crop, {
  double hitRadius = 40,
}) {
  final square = profileAvatarCropSquareRect(displayRect, crop);
  final corners = <ProfileAvatarCropCorner, Offset>{
    ProfileAvatarCropCorner.topLeft: square.topLeft,
    ProfileAvatarCropCorner.topRight: square.topRight,
    ProfileAvatarCropCorner.bottomLeft: square.bottomLeft,
    ProfileAvatarCropCorner.bottomRight: square.bottomRight,
  };
  for (final entry in corners.entries) {
    if ((viewportPoint - entry.value).distance <= hitRadius) {
      return entry.key;
    }
  }
  return null;
}

ProfileAvatarCrop profileAvatarCropWithRadiusFraction(
  ProfileAvatarCrop crop,
  double radiusFraction,
) {
  return ProfileAvatarCrop(
    centerNormX: crop.centerNormX,
    centerNormY: crop.centerNormY,
    radiusFraction: radiusFraction.clamp(
      ProfileAvatarCrop.minRadiusFraction,
      ProfileAvatarCrop.maxRadiusFraction,
    ),
  );
}

ProfileAvatarCrop profileAvatarCropWithCenter(
  Rect displayRect,
  ProfileAvatarCrop crop,
  Offset centerInViewport,
) {
  final radius = profileAvatarCircleRadius(displayRect, crop);
  final clampedX = centerInViewport.dx.clamp(
    displayRect.left + radius,
    displayRect.right - radius,
  );
  final clampedY = centerInViewport.dy.clamp(
    displayRect.top + radius,
    displayRect.top + displayRect.height - radius,
  );
  if (displayRect.width <= radius * 2 || displayRect.height <= radius * 2) {
    return crop;
  }
  return ProfileAvatarCrop(
    centerNormX: ((clampedX - displayRect.left) / displayRect.width).clamp(
      0.0,
      1.0,
    ),
    centerNormY: ((clampedY - displayRect.top) / displayRect.height).clamp(
      0.0,
      1.0,
    ),
    radiusFraction: crop.radiusFraction,
  );
}

/// 原画像座標系での切り抜き正方形（円に内接）。
Rect profileAvatarSourceSquareRect(
  Size imageSize,
  Size viewport,
  ProfileAvatarCrop crop,
) {
  final display = profileAvatarImageDisplayRect(viewport, imageSize);
  final scale = display.width / imageSize.width;
  final center = profileAvatarCircleCenter(display, crop);
  final radius = profileAvatarCircleRadius(display, crop);
  final side = radius * 2 / scale;
  final icx = (center.dx - display.left) / scale;
  final icy = (center.dy - display.top) / scale;
  var left = icx - side / 2;
  var top = icy - side / 2;
  left = left.clamp(0.0, math.max(0.0, imageSize.width - side));
  top = top.clamp(0.0, math.max(0.0, imageSize.height - side));
  final width = math.min(side, imageSize.width - left);
  final height = math.min(side, imageSize.height - top);
  final size = math.min(width, height);
  return Rect.fromLTWH(left, top, size, size);
}
