import 'dart:async';
import 'package:cit_app/services/schedule/schedule_image_save_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('jp.ac.chibakoudai.citapp/schedule_image');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final imageBytes = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    test('saves the exact PNG bytes on ${platform.name}', () async {
      debugDefaultTargetPlatformOverride = platform;
      MethodCall? savedCall;
      messenger.setMockMethodCallHandler(channel, (call) async {
        savedCall = call;
        return null;
      });

      await ScheduleImageSaveService.savePng(
        imageBytes,
        fileName: 'CIT_App_timetable_20260930.png',
      );

      expect(savedCall?.method, 'saveImage');
      expect(savedCall?.arguments['bytes'], imageBytes);
      expect(savedCall?.arguments['name'], 'CIT_App_timetable_20260930.png');
    });
  }

  test('waits for the native library to finish saving', () async {
    final nativeSave = Completer<void>();
    messenger.setMockMethodCallHandler(channel, (_) => nativeSave.future);
    var completed = false;
    final save = ScheduleImageSaveService.savePng(
      imageBytes,
      fileName: 'timetable.png',
    ).then((_) => completed = true);

    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    nativeSave.complete();
    await save;
    expect(completed, isTrue);
  });

  for (final code in ['permission_denied', 'save_failed']) {
    test('preserves $code so the UI can show the right recovery', () async {
      messenger.setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(code: code, message: 'save error');
      });

      await expectLater(
        ScheduleImageSaveService.savePng(imageBytes, fileName: 'timetable.png'),
        throwsA(
          isA<PlatformException>()
              .having((error) => error.code, 'code', code)
              .having((error) => error.message, 'message', 'save error'),
        ),
      );
    });
  }

  test(
    'rejects non-mobile platforms before calling the native bridge',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      var called = false;
      messenger.setMockMethodCallHandler(channel, (_) async {
        called = true;
        return null;
      });

      await expectLater(
        ScheduleImageSaveService.savePng(imageBytes, fileName: 'timetable.png'),
        throwsA(
          isA<PlatformException>().having(
            (error) => error.code,
            'code',
            'unsupported_platform',
          ),
        ),
      );
      expect(called, isFalse);
    },
  );

  test('reports missing native registration as unsupported', () async {
    await expectLater(
      ScheduleImageSaveService.savePng(imageBytes, fileName: 'timetable.png'),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'unsupported_platform',
        ),
      ),
    );
  });

  test('rejects an empty image before opening the photo library', () async {
    var called = false;
    messenger.setMockMethodCallHandler(channel, (_) async {
      called = true;
      return null;
    });

    await expectLater(
      ScheduleImageSaveService.savePng(Uint8List(0), fileName: 'timetable.png'),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'save_failed',
        ),
      ),
    );
    expect(called, isFalse);
  });

  test(
    'passes a safe file name rather than a path to the native bridge',
    () async {
      final names = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        names.add(call.arguments['name'] as String);
        return null;
      });

      await ScheduleImageSaveService.savePng(
        imageBytes,
        fileName: '../a/b.PNG',
      );
      await ScheduleImageSaveService.savePng(imageBytes, fileName: '');
      await ScheduleImageSaveService.savePng(imageBytes, fileName: 'a' * 200);

      expect(names, [
        '___a_b.png',
        'CIT_App_timetable.png',
        '${'a' * 120}.png',
      ]);
      for (final name in names) {
        expect(RegExp(r'^[A-Za-z0-9_-]{1,120}\.png$').hasMatch(name), isTrue);
      }
    },
  );
}
