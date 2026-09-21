import 'dart:async';
import 'dart:ui' as ui;

import 'package:cit_app/core/providers/user_provider.dart';
import 'package:cit_app/widgets/common/firebase_storage_image.dart';
import 'package:cit_app/widgets/profile/author_avatar.dart';
import 'package:cit_app/widgets/profile/user_avatar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _oldUrl =
    'https://firebasestorage.googleapis.com/v0/b/avatar-test/o/profile_images%2Ftest%2Favatar.jpg?alt=media&token=old';
// The object path stays the same when a profile image is replaced.
const _newUrl =
    'https://firebasestorage.googleapis.com/v0/b/avatar-test/o/profile_images%2Ftest%2Favatar.jpg?alt=media&token=new';
const _storageChannel =
    'dev.flutter.pigeon.firebase_storage_platform_interface.FirebaseStorageHostApi.referenceGetData';

class _FirebaseWithStorage extends MockFirebaseApp {
  @override
  Future<List<CoreInitializeResponse>> initializeCore() async {
    final apps = await super.initializeCore();
    for (final app in apps) {
      app.options.storageBucket = 'avatar-test';
    }
    return apps;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ui.Image oldPhoto;
  late ui.Image newPhoto;
  late Uint8List photoBytes;
  late List<Completer<List<Object?>>> sdkRequests;

  setUpAll(() async {
    TestFirebaseCoreHostApi.setUp(_FirebaseWithStorage());
    await Firebase.initializeApp();
    Future<ui.Image> photo(Color color) async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawColor(color, BlendMode.src);
      final picture = recorder.endRecording();
      final image = await picture.toImage(2, 2);
      picture.dispose();
      return image;
    }

    oldPhoto = await photo(Colors.red);
    newPhoto = await photo(Colors.blue);
    photoBytes =
        (await oldPhoto.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List();
  });

  setUp(() {
    sdkRequests = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(_storageChannel, (_) async {
          final request = Completer<List<Object?>>();
          sdkRequests.add(request);
          return const StandardMessageCodec().encodeMessage(
            await request.future,
          );
        });
  });

  tearDown(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(_storageChannel, null);
  });
  tearDownAll(() {
    oldPhoto.dispose();
    newPhoto.dispose();
  });

  // Control actual Image streams without network access or a test-only widget API.
  Completer<ImageInfo> network(String url) {
    final result = Completer<ImageInfo>();
    PaintingBinding.instance.imageCache.putIfAbsent(
      NetworkImage(url),
      () => OneFrameImageStreamCompleter(result.future),
      onError: (_, __) {},
    );
    return result;
  }

  Future<void> mount(WidgetTester tester, String url) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FirebaseStorageImage(
          imageUrl: url,
          width: 40,
          height: 40,
          placeholder: const Text('loading'),
          errorWidget: const Text('unavailable'),
        ),
      ),
    );
  }

  void expectPhoto(WidgetTester tester, ui.Image expected, {int count = 1}) {
    final photos =
        tester
            .widgetList<RawImage>(find.byType(RawImage))
            .where((widget) => widget.image != null)
            .toList();
    expect(photos, hasLength(count));
    expect(photos.every((widget) => widget.image!.isCloneOf(expected)), isTrue);
  }

  Future<void> failNetwork(
    WidgetTester tester,
    Completer<ImageInfo> request,
  ) async {
    request.completeError(StateError('HTTP request failed'));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('download URL stays active across rebuilds without SDK access', (
    tester,
  ) async {
    final request = network(_oldUrl);
    await mount(tester, _oldUrl);
    expect(find.text('loading'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await mount(tester, _oldUrl);
      expect(find.text('loading'), findsOneWidget);
      expect(sdkRequests, isEmpty);
    }
    request.complete(ImageInfo(image: oldPhoto.clone()));
    await tester.pumpAndSettle();
    expectPhoto(tester, oldPhoto);
    expect(sdkRequests, isEmpty);
  });

  testWidgets('profile and multiple author icons share the cached image', (
    tester,
  ) async {
    network(_oldUrl).complete(ImageInfo(image: oldPhoto.clone()));
    await mount(tester, _oldUrl);
    await tester.pump();
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            UserAvatar(imageUrl: _oldUrl, displayName: 'Profile'),
            UserAvatar(imageUrl: _oldUrl, displayName: 'Author', radius: 20),
            UserAvatar(imageUrl: _oldUrl, displayName: 'Author', radius: 16),
          ],
        ),
      ),
    );
    await tester.pump();
    expectPhoto(tester, oldPhoto, count: 3);
    expect(sdkRequests, isEmpty);
  });

  testWidgets('late HTTP response cannot replace the updated image', (
    tester,
  ) async {
    final oldRequest = network(_oldUrl);
    final newRequest = network(_newUrl);
    await mount(tester, _oldUrl);
    await mount(tester, _newUrl);
    newRequest.complete(ImageInfo(image: newPhoto.clone()));
    await tester.pumpAndSettle();
    oldRequest.complete(ImageInfo(image: oldPhoto.clone()));
    await tester.pump();
    expectPhoto(tester, newPhoto);
    expect(sdkRequests, isEmpty);
  });

  testWidgets('SDK fallback starts once and stays pending across rebuilds', (
    tester,
  ) async {
    final request = network(_oldUrl);
    await mount(tester, _oldUrl);
    await failNetwork(tester, request);
    expect(sdkRequests, hasLength(1));
    for (var i = 0; i < 3; i++) {
      await mount(tester, _oldUrl);
      expect(find.text('loading'), findsOneWidget);
      expect(sdkRequests, hasLength(1));
    }
    sdkRequests.single.complete([photoBytes]);
    // Image decoding is performed outside the fake clock.
    for (var i = 0; i < 30 && find.byType(RawImage).evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump();
    }
    expect(find.byType(RawImage), findsOneWidget);
    expect(find.text('unavailable'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final fails in [false, true]) {
    testWidgets(
      'late SDK result is ignored after URL change (failure=$fails)',
      (tester) async {
        final oldRequest = network(_oldUrl);
        final newRequest = network(_newUrl);
        await mount(tester, _oldUrl);
        await failNetwork(tester, oldRequest);
        expect(sdkRequests, hasLength(1));
        await mount(tester, _newUrl);
        newRequest.complete(ImageInfo(image: newPhoto.clone()));
        await tester.pump();
        sdkRequests.single.complete(
          fails ? ['unauthorized', 'Access denied', null] : [photoBytes],
        );
        await tester.pumpAndSettle();
        expectPhoto(tester, newPhoto);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('failed SDK state is cleared when the profile URL changes', (
    tester,
  ) async {
    final oldRequest = network(_oldUrl);
    final newRequest = network(_newUrl);
    await mount(tester, _oldUrl);
    await failNetwork(tester, oldRequest);
    sdkRequests.single.complete(['unauthorized', 'Access denied', null]);
    await tester.pumpAndSettle();
    expect(find.text('unavailable'), findsOneWidget);
    await mount(tester, _newUrl);
    expect(find.text('loading'), findsOneWidget);
    newRequest.complete(ImageInfo(image: newPhoto.clone()));
    await tester.pumpAndSettle();
    expectPhoto(tester, newPhoto);
  });

  testWidgets('invalid SDK bytes use the fallback without an image exception', (
    tester,
  ) async {
    final request = network(_oldUrl);
    await mount(tester, _oldUrl);
    await failNetwork(tester, request);
    sdkRequests.single.complete([
      Uint8List.fromList([1, 2, 3]),
    ]);
    for (
      var i = 0;
      i < 30 && find.text('unavailable').evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump();
    }
    expect(find.text('unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('other image hosts never invoke Firebase Storage', (
    tester,
  ) async {
    const url = 'https://example.com/avatar.jpg';
    final request = network(url);
    await mount(tester, url);
    await failNetwork(tester, request);
    expect(find.text('unavailable'), findsOneWidget);
    expect(sdkRequests, isEmpty);
  });

  testWidgets('removing a profile image restores the initial immediately', (
    tester,
  ) async {
    network(_oldUrl).complete(ImageInfo(image: oldPhoto.clone()));
    Future<void> avatar(String? url) => tester.pumpWidget(
      MaterialApp(home: UserAvatar(imageUrl: url, displayName: 'Alice')),
    );
    await avatar(_oldUrl);
    await tester.pump();
    expectPhoto(tester, oldPhoto);
    await avatar(null);
    expect(find.byType(RawImage), findsNothing);
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets(
    'author keeps the latest image on stream error, respects deletion',
    (tester) async {
      final profiles = StreamController<String?>();
      addTearDown(profiles.close);
      network(_oldUrl).complete(ImageInfo(image: oldPhoto.clone()));
      network(_newUrl).complete(ImageInfo(image: newPhoto.clone()));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authorProfileImageUrlProvider.overrideWith(
              (ref, id) => profiles.stream,
            ),
            authorDisplayNameProvider.overrideWith(
              (ref, query) => Stream.value(query.fallback),
            ),
          ],
          child: const MaterialApp(
            home: AuthorAvatar(
              authorId: 'test-author',
              displayName: 'Alice',
              fallbackImageUrl: _oldUrl,
            ),
          ),
        ),
      );
      await tester.pump();
      expectPhoto(tester, oldPhoto);
      profiles.add(_newUrl);
      await tester.pumpAndSettle();
      expectPhoto(tester, newPhoto);
      profiles.addError(StateError('temporary stream error'));
      await tester.pumpAndSettle();
      expectPhoto(tester, newPhoto);
      profiles.add(null);
      await tester.pumpAndSettle();
      expect(find.byType(RawImage), findsNothing);
      expect(find.text('A'), findsOneWidget);
      profiles.addError(StateError('temporary stream error after deletion'));
      await tester.pumpAndSettle();
      expect(find.byType(RawImage), findsNothing);
      expect(find.text('A'), findsOneWidget);
    },
  );
}
