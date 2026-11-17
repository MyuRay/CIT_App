import 'package:flutter/material.dart';

import '../../models/user/profile_avatar_crop.dart';

class ProfileAvatarCropEditor extends StatefulWidget {
  const ProfileAvatarCropEditor({
    super.key,
    required this.image,
    required this.initialCrop,
    required this.viewportSize,
    this.onCropChanged,
  });

  final ImageProvider image;
  final ProfileAvatarCrop initialCrop;
  final double viewportSize;
  final ValueChanged<ProfileAvatarCrop>? onCropChanged;

  @override
  State<ProfileAvatarCropEditor> createState() =>
      _ProfileAvatarCropEditorState();
}

class _ProfileAvatarCropEditorState extends State<ProfileAvatarCropEditor> {
  late ProfileAvatarCrop _crop = widget.initialCrop;
  Size? _imageSize;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  bool _failed = false;
  Offset? _circleCenterAtStart;
  Offset? _focalAtStart;
  double _radiusAtStart = ProfileAvatarCrop.defaultRadiusFraction;
  ProfileAvatarCrop? _cropAtDragStart;
  bool _cornerResizeActive = false;
  Offset? _resizeCenter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stream != null) return;
    _listener = ImageStreamListener(
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
      },
      onError: (_, __) {
        if (mounted) setState(() => _failed = true);
      },
    );
    _stream = widget.image.resolve(createLocalImageConfiguration(context))
      ..addListener(_listener!);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener!);
    super.dispose();
  }

  void _updateCrop(ProfileAvatarCrop next) {
    setState(() => _crop = next);
    widget.onCropChanged?.call(next);
  }

  Rect? get _displayRect {
    final imageSize = _imageSize;
    if (imageSize == null) return null;
    return profileAvatarImageDisplayRect(
      Size.square(widget.viewportSize),
      imageSize,
    );
  }

  void _applyRadiusFromFocal(Rect display, ProfileAvatarCrop base, Offset focal) {
    final center = profileAvatarCircleCenter(display, base);
    final maxR = profileAvatarMaxCircleRadius(display);
    final dist = (focal - center).distance;
    final fraction = (dist / maxR).clamp(
      ProfileAvatarCrop.minRadiusFraction,
      ProfileAvatarCrop.maxRadiusFraction,
    );
    _updateCrop(profileAvatarCropWithRadiusFraction(base, fraction));
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.viewportSize;
    final display = _displayRect;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '丸の中がアイコンになります。四隅をドラッグまたはピンチで大きさ、ドラッグで位置を調整',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: size,
            height: size,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart:
                  display == null
                      ? null
                      : (details) {
                        _cropAtDragStart = _crop;
                        final corner = profileAvatarCropCornerAt(
                          details.localFocalPoint,
                          display,
                          _crop,
                        );
                        if (corner != null) {
                          _cornerResizeActive = true;
                          _resizeCenter = profileAvatarCircleCenter(
                            display,
                            _crop,
                          );
                          _circleCenterAtStart = null;
                          _focalAtStart = null;
                          return;
                        }
                        _cornerResizeActive = false;
                        _resizeCenter = null;
                        _circleCenterAtStart = profileAvatarCircleCenter(
                          display,
                          _crop,
                        );
                        _focalAtStart = details.localFocalPoint;
                        _radiusAtStart = _crop.radiusFraction;
                      },
              onScaleUpdate:
                  display == null
                      ? null
                      : (details) {
                        final base = _cropAtDragStart;
                        if (base == null) return;

                        if (_cornerResizeActive && _resizeCenter != null) {
                          _applyRadiusFromFocal(
                            display,
                            base,
                            details.localFocalPoint,
                          );
                          return;
                        }

                        final centerStart = _circleCenterAtStart;
                        final focalStart = _focalAtStart;
                        if (centerStart == null || focalStart == null) {
                          return;
                        }
                        if ((details.scale - 1.0).abs() > 0.01) {
                          final nextRadius =
                              (_radiusAtStart * details.scale).clamp(
                                ProfileAvatarCrop.minRadiusFraction,
                                ProfileAvatarCrop.maxRadiusFraction,
                              );
                          _updateCrop(
                            profileAvatarCropWithCenter(
                              display,
                              ProfileAvatarCrop(
                                centerNormX: base.centerNormX,
                                centerNormY: base.centerNormY,
                                radiusFraction: nextRadius,
                              ),
                              centerStart,
                            ),
                          );
                        } else {
                          _updateCrop(
                            profileAvatarCropWithCenter(
                              display,
                              base,
                              centerStart +
                                  (details.localFocalPoint - focalStart),
                            ),
                          );
                        }
                      },
              onScaleEnd: (_) {
                _circleCenterAtStart = null;
                _focalAtStart = null;
                _cropAtDragStart = null;
                _cornerResizeActive = false;
                _resizeCenter = null;
              },
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.hardEdge,
                children: [
                  if (display != null)
                    Positioned.fromRect(
                      rect: display,
                      child: Image(image: widget.image, fit: BoxFit.fill),
                    ),
                  if (display != null)
                    CustomPaint(
                      painter: _LineStyleCropMaskPainter(
                        displayRect: display,
                        crop: _crop,
                      ),
                    ),
                  if (_imageSize == null && !_failed)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ),
        ),
        if (_failed)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '画像を読み込めませんでした',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _updateCrop(const ProfileAvatarCrop()),
          icon: const Icon(Icons.restart_alt, size: 20),
          label: const Text('リセット'),
        ),
      ],
    );
  }
}

/// LINE風：円外を暗くし、円周＋四隅の太めコーナーで拡大縮小を示す。
class _LineStyleCropMaskPainter extends CustomPainter {
  _LineStyleCropMaskPainter({required this.displayRect, required this.crop});

  final Rect displayRect;
  final ProfileAvatarCrop crop;

  static const double _circleStroke = 2;
  static const double _cornerStroke = 5;
  static const double _cornerArm = 26;

  @override
  void paint(Canvas canvas, Size size) {
    final center = profileAvatarCircleCenter(displayRect, crop);
    final radius = profileAvatarCircleRadius(displayRect, crop);
    final cropSquare = profileAvatarCropSquareRect(displayRect, crop);

    final dim =
        Paint()
          ..color = Colors.black.withValues(alpha: 0.62)
          ..style = PaintingStyle.fill;
    final path =
        Path()
          ..addRect(Offset.zero & size)
          ..addOval(Rect.fromCircle(center: center, radius: radius))
          ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, dim);

    final ring =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = _circleStroke;
    canvas.drawCircle(center, radius, ring);

    _drawCornerBrackets(canvas, cropSquare);
  }

  void _drawCornerBrackets(Canvas canvas, Rect square) {
    final arm = _cornerArm.clamp(12.0, square.shortestSide / 2.5);
    final paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = _cornerStroke
          ..strokeCap = StrokeCap.square;

    final tl = square.topLeft;
    final tr = square.topRight;
    final bl = square.bottomLeft;
    final br = square.bottomRight;

    canvas.drawLine(tl, tl + Offset(arm, 0), paint);
    canvas.drawLine(tl, tl + Offset(0, arm), paint);

    canvas.drawLine(tr, tr + Offset(-arm, 0), paint);
    canvas.drawLine(tr, tr + Offset(0, arm), paint);

    canvas.drawLine(bl, bl + Offset(arm, 0), paint);
    canvas.drawLine(bl, bl + Offset(0, -arm), paint);

    canvas.drawLine(br, br + Offset(-arm, 0), paint);
    canvas.drawLine(br, br + Offset(0, -arm), paint);
  }

  @override
  bool shouldRepaint(covariant _LineStyleCropMaskPainter oldDelegate) {
    return oldDelegate.displayRect != displayRect ||
        oldDelegate.crop.centerNormX != crop.centerNormX ||
        oldDelegate.crop.centerNormY != crop.centerNormY ||
        oldDelegate.crop.radiusFraction != crop.radiusFraction;
  }
}
