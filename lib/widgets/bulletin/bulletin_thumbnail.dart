import 'package:flutter/material.dart';
import '../../models/bulletin/bulletin_image_draft.dart';
import '../common/safe_cached_network_image.dart';

/// The same crop geometry is used for editing, feed cards and admin previews.
class BulletinThumbnail extends StatelessWidget {
  const BulletinThumbnail({
    super.key,
    this.image,
    this.imageUrl,
    this.crop = const BulletinCrop(),
    this.errorWidget,
  });
  final ImageProvider? image;
  final String? imageUrl;
  final BulletinCrop crop;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    final alignment = Alignment(crop.x, crop.y);
    return ClipRect(
      child: Transform.scale(
        scale: crop.scale,
        alignment: alignment,
        child:
            image != null
                ? Image(
                  image: image!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  alignment: alignment,
                  errorBuilder:
                      (_, __, ___) =>
                          errorWidget ??
                          const Center(
                            child: Icon(Icons.broken_image_outlined),
                          ),
                )
                : SafeCachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  alignment: alignment,
                  errorWidget: errorWidget,
                ),
      ),
    );
  }
}

/// The image displacement is measured in displayed image pixels, not viewport
/// width: a 20px drag must move the image 20px at every aspect ratio and zoom.
Offset bulletinCropOffset(Size viewport, Size image, BulletinCrop crop) {
  final coverScale =
      (viewport.width / image.width) > (viewport.height / image.height)
          ? viewport.width / image.width
          : viewport.height / image.height;
  final overflow = Size(
    image.width * coverScale * crop.scale - viewport.width,
    image.height * coverScale * crop.scale - viewport.height,
  );
  return Offset(-overflow.width * crop.x / 2, -overflow.height * crop.y / 2);
}

BulletinCrop bulletinCropFromOffset(
  Size viewport,
  Size image,
  double scale,
  Offset offset,
) {
  final coverScale =
      (viewport.width / image.width) > (viewport.height / image.height)
          ? viewport.width / image.width
          : viewport.height / image.height;
  final overflow = Size(
    image.width * coverScale * scale - viewport.width,
    image.height * coverScale * scale - viewport.height,
  );
  return BulletinCrop(
    x:
        overflow.width > 0.001
            ? (-2 * offset.dx / overflow.width).clamp(-1, 1)
            : 0,
    y:
        overflow.height > 0.001
            ? (-2 * offset.dy / overflow.height).clamp(-1, 1)
            : 0,
    scale: scale,
  );
}
