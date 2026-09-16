import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
// Google Fonts exposes this manifest hook specifically for offline tests.
// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as font_loader;
import 'package:cit_app/core/theme/app_theme.dart';

const themePreviewDirectory = String.fromEnvironment('THEME_PREVIEW_DIR');

/// Tests exercise production theme colors without fetching fonts over HTTP.
/// Optional Windows previews substitute Meiryo for the remote Noto Sans JP font.
Future<Map<Brightness, ThemeData>> loadTestThemes() async {
  final font =
      themePreviewDirectory.isNotEmpty
          ? ByteData.sublistView(
            await File('C:/Windows/Fonts/meiryo.ttc').readAsBytes(),
          )
          : await rootBundle.load(
            'packages/cupertino_icons/assets/CupertinoIcons.ttf',
          );
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final assetBytes = <String, ByteData>{};
  for (final key in ['assets/icons/app_launcher_icon.png']) {
    assetBytes[key] = await rootBundle.load(key);
  }
  if (themePreviewDirectory.isNotEmpty) {
    final loader = FontLoader('MaterialIcons')..addFont(
      Future.value(
        ByteData.sublistView(
          await File(
            'C:/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytes(),
        ),
      ),
    );
    await loader.load();
  }
  font_loader.assetManifest = _TestFontManifest(manifest);
  GoogleFonts.config.allowRuntimeFetching = false;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
        final key = const StringCodec().decodeMessage(message);
        if (key?.startsWith('test-fonts/') == true) return font;
        return assetBytes[key];
      });
  final themes = {
    Brightness.light: AppTheme.lightTheme,
    Brightness.dark: AppTheme.darkTheme,
  };
  await GoogleFonts.pendingFonts();
  return themes;
}

class _TestFontManifest implements AssetManifest {
  _TestFontManifest(this.base);
  final AssetManifest base;
  @override
  List<String> listAssets() => [
    ...base.listAssets(),
    for (final weight in [
      'Thin',
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
      'Black',
    ])
      'test-fonts/NotoSansJP-$weight.ttf',
  ];
  @override
  List<AssetMetadata>? getAssetVariants(String key) =>
      base.getAssetVariants(key);
}
