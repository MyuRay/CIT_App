import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

// Run from the project root: dart run scripts/generate_splash_assets.dart
// Extract the existing rabbit mark, preserving its silhouette and facial details.
// Native and Flutter launch surfaces all display it at 112 logical pixels.
void main() {
  final source = img
      .decodePng(File('assets/icons/app_launcher_icon.png').readAsBytesSync())!
      .convert(numChannels: 4);
  if (source.width != source.height) {
    throw StateError('The launcher source must be square.');
  }
  var left = source.width, top = source.height, right = 0, bottom = 0;
  for (final pixel in source) {
    final lightness = math.min(pixel.r, math.min(pixel.g, pixel.b));
    final alpha = ((lightness - 140) / 80).clamp(0, 1) * 255;
    if (alpha > 127) {
      left = math.min(left, pixel.x);
      top = math.min(top, pixel.y);
      right = math.max(right, pixel.x);
      bottom = math.max(bottom, pixel.y);
    }
    pixel
      ..r = 255
      ..g = 255
      ..b = 255
      ..a = alpha.round();
  }
  if (right <= left || bottom <= top) {
    throw StateError('No white rabbit mark found in the launcher source.');
  }
  final mark = img.copyCrop(
    source,
    x: left,
    y: top,
    width: right - left + 1,
    height: bottom - top + 1,
  );

  void writeIcon(String path, int size) {
    final file = File(path)..parent.createSync(recursive: true);
    final resized = img.copyResize(
      mark,
      width: (size * mark.width / mark.height).round(),
      height: size,
      interpolation: img.Interpolation.average,
    );
    final canvas = img.Image(width: size, height: size, numChannels: 4);
    img.compositeImage(canvas, resized, dstX: (size - resized.width) ~/ 2);
    file.writeAsBytesSync(img.encodePng(canvas));
    stdout.writeln('$path: ${size}x$size');
  }

  writeIcon('assets/icons/app_splash_icon.png', 336);
  for (final density
      in {
        'mdpi': 1.0,
        'hdpi': 1.5,
        'xhdpi': 2.0,
        'xxhdpi': 3.0,
        'xxxhdpi': 4.0,
      }.entries) {
    writeIcon(
      'android/app/src/main/res/drawable-${density.key}/splash_icon.png',
      (112 * density.value).round(),
    );
  }
  for (var scale = 1; scale <= 3; scale++) {
    final suffix = scale == 1 ? '' : '@${scale}x';
    writeIcon(
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage$suffix.png',
      112 * scale,
    );
  }
}
