import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 掲示板一覧の表示方法。
enum BulletinViewMode { card, list }

final bulletinViewModeProvider =
    StateNotifierProvider<BulletinViewModeNotifier, BulletinViewMode>(
      (ref) => BulletinViewModeNotifier(),
    );

/// 選んだ表示方法を端末に保存し、次に開いたときも同じ表示にする。
class BulletinViewModeNotifier extends StateNotifier<BulletinViewMode> {
  BulletinViewModeNotifier() : super(BulletinViewMode.card) {
    _load();
  }

  static const prefsKey = 'bulletin_view_mode';
  bool _changedBeforeLoad = false;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved =
          BulletinViewMode.values
              .where((mode) => mode.name == prefs.getString(prefsKey))
              .firstOrNull;
      // 読み込み中に切り替えた場合は、その選択を優先する。
      if (saved != null && mounted && !_changedBeforeLoad) state = saved;
    } catch (e) {
      debugPrint('掲示板の表示方法を読み込めませんでした: $e');
    }
  }

  Future<void> setMode(BulletinViewMode mode) async {
    _changedBeforeLoad = true;
    if (state == mode) return;
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, mode.name);
    } catch (e) {
      debugPrint('掲示板の表示方法を保存できませんでした: $e');
    }
  }
}
