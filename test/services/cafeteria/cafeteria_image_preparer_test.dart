import 'dart:typed_data';

import 'package:cit_app/services/cafeteria/cafeteria_image_preparer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('small JPEG is retained byte-for-byte without upscaling', () async {
    final source = img.encodeJpg(img.Image(width: 320, height: 240));
    final prepared = await CafeteriaImagePreparer.prepare(
      source,
      filename: 'a.jpg',
    );
    expect(identical(prepared.bytes, source), isTrue);
    expect(prepared.contentType, 'image/jpeg');
  });

  test(
    'PNG signature determines metadata even with a wrong filename',
    () async {
      final source = img.encodePng(
        img.Image(width: 20, height: 10, numChannels: 4),
      );
      final prepared = await CafeteriaImagePreparer.prepare(
        source,
        filename: 'a.jpg',
      );
      expect(identical(prepared.bytes, source), isTrue);
      expect(prepared.contentType, 'image/png');
      expect(prepared.extension, 'png');
    },
  );

  for (final portrait in [false, true]) {
    test(
      'oversized ${portrait ? 'portrait' : 'landscape'} resizes with its aspect ratio',
      () async {
        final source = img.encodeJpg(
          img.Image(
            width: portrait ? 1800 : 3200,
            height: portrait ? 3200 : 1800,
          ),
        );
        final prepared = await CafeteriaImagePreparer.prepare(
          source,
          filename: 'large.jpg',
        );
        final decoded = img.decodeJpg(prepared.bytes)!;
        expect(decoded.width, portrait ? 900 : 1600);
        expect(decoded.height, portrait ? 1600 : 900);
        expect(prepared.bytes.length, lessThan(source.length));
        expect(prepared.contentType, 'image/jpeg');
        expect(prepared.extension, 'jpg');
      },
    );
  }

  test('photos over 10 MB are resized instead of being rejected', () async {
    final source = img.encodeBmp(img.Image(width: 3200, height: 1200));
    expect(source.length, greaterThan(10 * 1024 * 1024));
    final prepared = await CafeteriaImagePreparer.prepare(
      source,
      filename: 'large.bmp',
    );
    final decoded = img.decodeJpg(prepared.bytes)!;
    expect(decoded.width, 1600);
    expect(decoded.height, 600);
    expect(prepared.bytes.length, lessThan(2 * 1024 * 1024));
  });

  test(
    'large file size alone triggers compression without upscaling',
    () async {
      final source = img.encodeBmp(img.Image(width: 1000, height: 1000));
      expect(
        source.length,
        greaterThan(CafeteriaImagePreparer.compressionThresholdBytes),
      );
      final prepared = await CafeteriaImagePreparer.prepare(
        source,
        filename: 'heavy.bmp',
      );
      final decoded = img.decodeJpg(prepared.bytes)!;
      expect(decoded.width, 1000);
      expect(decoded.height, 1000);
      expect(prepared.bytes.length, lessThan(source.length));
    },
  );

  test('transparent oversized PNG gets a white JPEG background', () async {
    final source = img.encodePng(
      img.Image(width: 1800, height: 900, numChannels: 4),
    );
    final prepared = await CafeteriaImagePreparer.prepare(
      source,
      filename: 'transparent.png',
    );
    final decoded = img.decodeJpg(prepared.bytes)!;
    final pixel = decoded.getPixel(10, 10);
    expect(decoded.width, 1600);
    expect(pixel.r, greaterThan(245));
    expect(pixel.g, greaterThan(245));
    expect(pixel.b, greaterThan(245));
  });

  test('unsupported conversion keeps the original for upload', () async {
    final source = Uint8List.fromList([0, 1, 2, 3, 4]);
    final prepared = await CafeteriaImagePreparer.prepare(
      source,
      filename: 'photo.heic',
    );
    expect(identical(prepared.bytes, source), isTrue);
    expect(prepared.contentType, 'image/heic');
    expect(prepared.extension, 'heic');
  });

  test('empty file reports an error rather than creating an empty upload', () {
    expect(
      CafeteriaImagePreparer.prepare(Uint8List(0), filename: 'empty.jpg'),
      throwsStateError,
    );
  });
}
