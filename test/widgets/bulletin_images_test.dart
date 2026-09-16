import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cit_app/models/bulletin/bulletin_image_draft.dart';
import 'package:cit_app/widgets/bulletin/bulletin_image_picker.dart';
import 'package:cit_app/widgets/bulletin/bulletin_image_gallery.dart';
import 'package:cit_app/widgets/bulletin/bulletin_thumbnail_editor.dart';
import 'package:cit_app/widgets/bulletin/bulletin_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import '../support/theme_test_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Uint8List photo;
  late Map<Brightness, ThemeData> themes;
  final boundary = GlobalKey();
  setUpAll(() async {
    themes = await loadTestThemes();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 400, 800),
      Paint()..color = Colors.blue,
    );
    canvas.drawRect(
      const Rect.fromLTWH(0, 250, 400, 300),
      Paint()..color = Colors.amber,
    );
    canvas.drawCircle(const Offset(200, 400), 80, Paint()..color = Colors.teal);
    final picture = recorder.endRecording();
    final image = await picture.toImage(400, 800);
    photo =
        (await image.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List();
    image.dispose();
    picture.dispose();
  });
  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    Brightness brightness = Brightness.light,
    double width = 390,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: themes[brightness],
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                padding: const EdgeInsets.only(bottom: 48),
              ),
              child: RepaintBoundary(key: boundary, child: child!),
            ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  BulletinImageDraft draft() =>
      BulletinImageDraft()..add(
        List.generate(
          3,
          (i) => BulletinImageAttachment(id: '$i', bytes: photo),
        ),
      );

  testWidgets('adds multiple selected images in one operation', (tester) async {
    final images = BulletinImageDraft();
    await mount(
      tester,
      BulletinImagePicker(
        draft: images,
        pickImages:
            (_) async => [
              XFile.fromData(photo, name: 'a.png'),
              XFile.fromData(photo, name: 'b.png'),
            ],
      ),
    );
    await tester.tap(find.text('画像を追加'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('写真をまとめて選択'));
    await tester.pumpAndSettle();
    expect(images.images, hasLength(2));
    expect(
      images.images.every((image) => image.contentType == 'image/png'),
      isTrue,
    );
    expect(find.text('投稿画像 2/10枚'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('reports image loading until all selected files are ready', (
    tester,
  ) async {
    final images = BulletinImageDraft();
    final selection = Completer<List<XFile>>();
    final picking = <bool>[];
    await mount(
      tester,
      BulletinImagePicker(
        draft: images,
        pickImages: (_) => selection.future,
        onPickingChanged: picking.add,
      ),
    );
    await tester.tap(find.text('画像を追加'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('写真をまとめて選択'));
    await tester.pump();
    expect(picking, [true]);
    selection.complete([XFile.fromData(photo, name: 'photo.png')]);
    await tester.pumpAndSettle();
    expect(picking, [true, false]);
    expect(images.images, hasLength(1));
  });
  testWidgets('selects cover, preserves it while reordering, and removes it', (
    tester,
  ) async {
    final images = draft();
    await mount(tester, BulletinImagePicker(draft: images));
    await tester.tap(find.text('2枚目'));
    await tester.pumpAndSettle();
    expect(images.coverId, '1');
    final list = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    list.onReorderItem!(1, 0);
    await tester.pumpAndSettle();
    expect(images.images.first.id, '1');
    expect(images.coverId, '1');
    await tester.tap(find.byTooltip('1枚目を削除'));
    await tester.pumpAndSettle();
    expect(images.coverId, '0');
    expect(images.images, hasLength(2));
  });
  testWidgets(
    'crop editor drags in image pixels and cancel preserves the draft',
    (tester) async {
      final images = draft();
      await mount(tester, BulletinImagePicker(draft: images));
      await tester.ensureVisible(find.text('表示範囲を調整'));
      await tester.tap(find.text('表示範囲を調整'));
      await tester.pumpAndSettle();
      final region = find.byKey(const ValueKey('bulletin-crop-gesture'));
      await tester.drag(region, const Offset(0, 45));
      await tester.pumpAndSettle();
      final preview = tester.widget<BulletinThumbnail>(
        find.descendant(
          of: find.byType(BulletinThumbnailEditor),
          matching: find.byType(BulletinThumbnail),
        ),
      );
      expect(preview.crop.y, lessThan(0));
      expect(images.crop.y, 0);
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(images.crop.y, 0);
    },
  );
  testWidgets('pinch zoom applies and reset returns to the original crop', (
    tester,
  ) async {
    final images = draft();
    await mount(tester, BulletinImagePicker(draft: images));
    await tester.ensureVisible(find.text('表示範囲を調整'));
    await tester.tap(find.text('表示範囲を調整'));
    await tester.pumpAndSettle();
    final center = tester.getCenter(
      find.byKey(const ValueKey('bulletin-crop-gesture')),
    );
    final one = await tester.startGesture(
      center - const Offset(30, 0),
      pointer: 1,
    );
    final two = await tester.startGesture(
      center + const Offset(30, 0),
      pointer: 2,
    );
    await tester.pump();
    await one.moveTo(center - const Offset(65, 0));
    await two.moveTo(center + const Offset(65, 0));
    await tester.pump();
    await one.up();
    await two.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text('この範囲にする'));
    await tester.pumpAndSettle();
    expect(images.crop.scale, greaterThan(1));
    await tester.tap(find.text('表示範囲を調整'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('中央・元の倍率に戻す'));
    await tester.tap(find.text('この範囲にする'));
    await tester.pumpAndSettle();
    expect(images.crop.scale, 1);
    expect(images.crop.x, 0);
  });
  testWidgets('gallery switches pages with swipe and arrow buttons', (
    tester,
  ) async {
    await mount(
      tester,
      BulletinImageGallery(
        imageUrls: const ['a', 'b', 'c'],
        imageBuilder: (_) => Image.memory(photo),
      ),
    );
    expect(find.text('1/3'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);
    await tester.tap(find.byTooltip('次の画像'));
    await tester.pumpAndSettle();
    expect(find.text('3/3'), findsOneWidget);
    await tester.tap(find.byTooltip('前の画像'));
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);
  });
  for (final brightness in Brightness.values) {
    testWidgets(
      'media controls and crop editor fit 320px large text in ${brightness.name}',
      (tester) async {
        await mount(
          tester,
          BulletinImagePicker(draft: draft()),
          brightness: brightness,
          width: 320,
          scale: 2,
        );
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('表示範囲を調整'));
        await tester.tap(find.text('表示範囲を調整'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.widgetWithText(FilledButton, 'この範囲にする')).bottom,
          lessThanOrEqualTo(844 - 48),
        );
      },
    );
    if (themePreviewDirectory.isNotEmpty) {
      testWidgets('media and crop previews ${brightness.name}', (tester) async {
        await mount(
          tester,
          BulletinImagePicker(draft: draft()),
          brightness: brightness,
        );
        Future<void> capture(String name) async {
          await tester.runAsync(() async {
            final render =
                boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await render.toImage(pixelRatio: 1.5);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File(
              '$themePreviewDirectory/$name-${brightness.name}.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }

        await capture('bulletin-images');
        await tester.ensureVisible(find.text('表示範囲を調整'));
        await tester.tap(find.text('表示範囲を調整'));
        await tester.pumpAndSettle();
        await capture('bulletin-crop');
      });
    }
  }
}
