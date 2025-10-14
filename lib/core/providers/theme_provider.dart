import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// テーマモードのプロバイダー
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  static const String _themeKey = 'theme_mode';

  // テーマモードを読み込み
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeIndex = prefs.getInt(_themeKey);
      if (themeModeIndex != null) {
        state = ThemeMode.values[themeModeIndex];
        print('✅ テーマモード読み込み: ${state.name}');
      }
    } catch (e) {
      print('❌ テーマモード読み込みエラー: $e');
    }
  }

  // テーマモードを保存
  Future<void> _saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, state.index);
      print('✅ テーマモード保存: ${state.name}');
    } catch (e) {
      print('❌ テーマモード保存エラー: $e');
    }
  }

  // テーマモードを変更
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _saveThemeMode();
  }

  // ライトモードに設定
  Future<void> setLightMode() async {
    await setThemeMode(ThemeMode.light);
  }

  // ダークモードに設定
  Future<void> setDarkMode() async {
    await setThemeMode(ThemeMode.dark);
  }

  // システム設定に従う
  Future<void> setSystemMode() async {
    await setThemeMode(ThemeMode.system);
  }

  // 現在のテーマモードの表示名を取得
  String get currentThemeDisplayName {
    switch (state) {
      case ThemeMode.light:
        return 'ライトモード';
      case ThemeMode.dark:
        return 'ダークモード';
      case ThemeMode.system:
        return 'システム設定に従う';
    }
  }

  // ダークモードかどうか（ システム設定考慮）
  bool isDarkMode(BuildContext context) {
    switch (state) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
  }
}