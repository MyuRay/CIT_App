import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Saves timetable images into the device's photo library.
class ScheduleImageSaveService {
  static const _channel = MethodChannel(
    'jp.ac.chibakoudai.citapp/schedule_image',
  );

  static Future<void> savePng(
    Uint8List bytes, {
    required String fileName,
  }) async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      throw PlatformException(
        code: 'unsupported_platform',
        message: 'この端末では写真への保存に対応していません。',
      );
    }
    if (bytes.isEmpty) {
      throw PlatformException(code: 'save_failed', message: '保存する画像がありません。');
    }

    // Only a file name crosses the native bridge; never a caller-owned path.
    var name = fileName
        .replaceFirst(RegExp(r'\.png$', caseSensitive: false), '')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    if (name.isEmpty) name = 'CIT_App_timetable';
    if (name.length > 120) name = name.substring(0, 120);

    try {
      await _channel.invokeMethod<void>('saveImage', {
        'bytes': bytes,
        'name': '$name.png',
      });
    } on MissingPluginException {
      throw PlatformException(
        code: 'unsupported_platform',
        message: 'この端末では写真への保存を利用できません。',
      );
    }
  }
}
