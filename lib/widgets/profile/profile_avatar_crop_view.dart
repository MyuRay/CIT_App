import 'package:flutter/material.dart';

import '../../models/user/profile_avatar_crop.dart';

/// 切り抜き円に相当する原画像の範囲をプレビュー表示。
class ProfileAvatarCropView extends StatefulWidget {
  const ProfileAvatarCropView({
    super.key,
    required this.image,
    required this.crop,
    required this.viewportSize,
    this.previewSize = 160,
  });

  final ImageProvider image;
  final ProfileAvatarCrop crop;
  final double viewportSize;
  final double previewSize;

  @override
  State<ProfileAvatarCropView> createState() => _ProfileAvatarCropViewState();
}

class _ProfileAvatarCropViewState extends State<ProfileAvatarCropView> {
  Size? _imageSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_imageSize != null) return;
    final stream = widget.image.resolve(createLocalImageConfiguration(context));
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (mounted) {
          setState(
            () => _imageSize = Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            ),
          );
        }
        info.dispose();
        stream.removeListener(listener);
      },
      onError: (_, __) => stream.removeListener(listener),
    );
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final imageSize = _imageSize;
    final out = widget.previewSize;
    if (imageSize == null) {
      return SizedBox(
        width: out,
        height: out,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final viewport = Size.square(widget.viewportSize);
    final src = profileAvatarSourceSquareRect(
      imageSize,
      viewport,
      widget.crop,
    );
    final iw = imageSize.width;
    final ih = imageSize.height;
    final scale = out / src.width;

    return ClipOval(
      child: SizedBox(
        width: out,
        height: out,
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment(
            ((src.left + src.width / 2) / iw) * 2 - 1,
            ((src.top + src.height / 2) / ih) * 2 - 1,
          ),
          child: SizedBox(
            width: iw * scale,
            height: ih * scale,
            child: Image(image: widget.image, fit: BoxFit.fill),
          ),
        ),
      ),
    );
  }
}
