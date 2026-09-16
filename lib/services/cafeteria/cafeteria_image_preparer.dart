import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:mime/mime.dart';

class PreparedCafeteriaImage {
  const PreparedCafeteriaImage({
    required this.bytes,
    required this.contentType,
    required this.extension,
  });

  final Uint8List bytes;
  final String contentType;
  final String extension;
}

/// Optimizes oversized menu photos without introducing a size-based rejection.
/// Conversion failures retain the selected file; upload failures still surface.
class CafeteriaImagePreparer {
  static const maxDimension = 1600;
  static const jpegQuality = 85;
  static const compressionThresholdBytes = 2 * 1024 * 1024;

  static Future<PreparedCafeteriaImage> prepare(
    Uint8List bytes, {
    required String filename,
  }) async {
    if (bytes.isEmpty) throw StateError('選択した画像ファイルが空です');
    final contentType =
        lookupMimeType(filename, headerBytes: bytes) ??
        'application/octet-stream';
    final original = PreparedCafeteriaImage(
      bytes: bytes,
      contentType: contentType,
      extension: extensionFromMime(contentType) ?? 'bin',
    );
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? frame;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final longest =
          descriptor.width > descriptor.height
              ? descriptor.width
              : descriptor.height;
      final oversized = longest > maxDimension;
      if (!oversized && bytes.length <= compressionThresholdBytes) {
        return original;
      }
      final scale = oversized ? maxDimension / longest : 1.0;
      // Request a scaled decode so the original full-resolution RGBA bitmap
      // does not have to be materialized in Dart before resizing.
      codec = await descriptor.instantiateCodec(
        targetWidth: (descriptor.width * scale).round().clamp(1, maxDimension),
        targetHeight: (descriptor.height * scale).round().clamp(
          1,
          maxDimension,
        ),
      );
      frame = (await codec.getNextFrame()).image;
      final rgba = await frame.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      if (rgba == null) return original;
      final jpeg = await compute(_encodeMenuJpeg, (
        bytes: rgba.buffer.asUint8List(rgba.offsetInBytes, rgba.lengthInBytes),
        width: frame.width,
        height: frame.height,
      ));
      // Do not make an already suitably sized image heavier by recompressing.
      if (!oversized && jpeg.length >= bytes.length) return original;
      return PreparedCafeteriaImage(
        bytes: jpeg,
        contentType: 'image/jpeg',
        extension: 'jpg',
      );
    } catch (error) {
      debugPrint('Menu photo optimization skipped: $error');
      return original;
    } finally {
      frame?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
  }
}

Uint8List _encodeMenuJpeg(({Uint8List bytes, int width, int height}) input) {
  final pixels = img.Image.fromBytes(
    width: input.width,
    height: input.height,
    bytes: input.bytes.buffer,
    bytesOffset: input.bytes.offsetInBytes,
    numChannels: 4,
  );
  // JPEG has no alpha channel. Composite transparent pixels on white rather
  // than turning a transparent menu photograph or illustration black.
  final background = img.Image(width: input.width, height: input.height);
  img.fill(background, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(background, pixels);
  return img.encodeJpg(background, quality: CafeteriaImagePreparer.jpegQuality);
}
