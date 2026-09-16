import 'package:flutter/material.dart';
import '../../models/bulletin/bulletin_image_draft.dart';
import 'bulletin_thumbnail.dart';

class BulletinThumbnailEditor extends StatefulWidget {
  const BulletinThumbnailEditor({
    super.key,
    required this.image,
    required this.initialCrop,
  });
  final ImageProvider image;
  final BulletinCrop initialCrop;
  @override
  State<BulletinThumbnailEditor> createState() =>
      _BulletinThumbnailEditorState();
}

class _BulletinThumbnailEditorState extends State<BulletinThumbnailEditor> {
  late BulletinCrop _crop = widget.initialCrop;
  Size? _imageSize;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  bool _failed = false;
  Offset _startFocal = Offset.zero;
  Offset _startOffset = Offset.zero;
  double _startScale = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stream != null) return;
    _listener = ImageStreamListener(
      (info, _) {
        if (mounted) {
          setState(
            () =>
                _imageSize = Size(
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

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final previewWidth = (constraints.maxWidth - 80).clamp(0.0, 560.0);
      return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Text('サムネイルを調整'),
        scrollable: true,
        content: SizedBox(
          width: previewWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('画像をドラッグして位置を調整。2本指で拡大・縮小できます。'),
              const SizedBox(height: 16),
              SizedBox(
                width: previewWidth,
                height: previewWidth * 9 / 16,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final viewport = constraints.biggest;
                    return GestureDetector(
                      key: const ValueKey('bulletin-crop-gesture'),
                      behavior: HitTestBehavior.opaque,
                      onScaleStart:
                          _imageSize == null
                              ? null
                              : (details) {
                                _startFocal = details.localFocalPoint;
                                _startScale = _crop.scale;
                                _startOffset = bulletinCropOffset(
                                  viewport,
                                  _imageSize!,
                                  _crop,
                                );
                              },
                      onScaleUpdate:
                          _imageSize == null
                              ? null
                              : (details) {
                                final scale = (_startScale * details.scale)
                                    .clamp(1.0, 4.0);
                                final center = viewport.center(Offset.zero);
                                final offset =
                                    details.localFocalPoint -
                                    center -
                                    (_startFocal - center - _startOffset) *
                                        (scale / _startScale);
                                setState(
                                  () =>
                                      _crop = bulletinCropFromOffset(
                                        viewport,
                                        _imageSize!,
                                        scale,
                                        offset,
                                      ),
                                );
                              },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          BulletinThumbnail(image: widget.image, crop: _crop),
                          const IgnorePointer(
                            child: CustomPaint(painter: _CropGuides()),
                          ),
                          if (_imageSize == null && !_failed)
                            const Center(child: CircularProgressIndicator()),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (_failed) const Text('画像を読み込めませんでした。閉じて再度お試しください。'),
              Row(
                children: [
                  const Icon(Icons.zoom_out),
                  Expanded(
                    child: Slider(
                      label: '${(_crop.scale * 100).round()}%',
                      value: _crop.scale,
                      min: 1,
                      max: 4,
                      onChanged:
                          _imageSize == null
                              ? null
                              : (value) => setState(
                                () =>
                                    _crop = BulletinCrop(
                                      x: _crop.x,
                                      y: _crop.y,
                                      scale: value,
                                    ),
                              ),
                    ),
                  ),
                  const Icon(Icons.zoom_in),
                ],
              ),
              Text('${(_crop.scale * 100).round()}%・一覧での表示範囲（16:9）'),
              TextButton.icon(
                onPressed: () => setState(() => _crop = const BulletinCrop()),
                icon: const Icon(Icons.restart_alt),
                label: const Text('中央・元の倍率に戻す'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed:
                _imageSize == null ? null : () => Navigator.pop(context, _crop),
            child: const Text('この範囲にする'),
          ),
        ],
      );
    },
  );
}

class _CropGuides extends CustomPainter {
  const _CropGuides();
  @override
  void paint(Canvas canvas, Size size) {
    final dark =
        Paint()
          ..color = Colors.black54
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
    final light =
        Paint()
          ..color = Colors.white70
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
    for (final paint in [dark, light]) {
      canvas.drawRect(Offset.zero & size, paint);
      for (var i = 1; i <= 2; i++) {
        canvas.drawLine(
          Offset(size.width * i / 3, 0),
          Offset(size.width * i / 3, size.height),
          paint,
        );
        canvas.drawLine(
          Offset(0, size.height * i / 3),
          Offset(size.width, size.height * i / 3),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
