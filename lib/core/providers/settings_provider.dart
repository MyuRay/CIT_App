import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferences インスタンスプロバイダー
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// 設定管理クラス
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._prefs)
      : super(
          SettingsState(
            showSaturday: _prefs.getBool('showSaturday') ?? true,
            preferredBusCampus: _prefs.getString('preferredBusCampus') ?? 'tsudanuma',
          ),
        );

  final SharedPreferences _prefs;

  // 土曜日表示設定を切り替え
  Future<void> toggleShowSaturday() async {
    final newValue = !state.showSaturday;
    await _prefs.setBool('showSaturday', newValue);
    state = state.copyWith(showSaturday: newValue);
  }

  // 土曜日表示設定を直接設定
  Future<void> setShowSaturday(bool value) async {
    await _prefs.setBool('showSaturday', value);
    state = state.copyWith(showSaturday: value);
  }

  // 学バス優先キャンパスを設定（'tsudanuma' or 'narashino'）
  Future<void> setPreferredBusCampus(String campus) async {
    await _prefs.setString('preferredBusCampus', campus);
    state = state.copyWith(preferredBusCampus: campus);
  }
}

// 設定状態クラス
class SettingsState {
  const SettingsState({
    required this.showSaturday,
    required this.preferredBusCampus,
  });

  final bool showSaturday;
  final String preferredBusCampus; // 'tsudanuma' or 'narashino'

  SettingsState copyWith({
    bool? showSaturday,
    String? preferredBusCampus,
  }) {
    return SettingsState(
      showSaturday: showSaturday ?? this.showSaturday,
      preferredBusCampus: preferredBusCampus ?? this.preferredBusCampus,
    );
  }
}

// 設定プロバイダー
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});

// 土曜日表示設定の便利なプロバイダー
final showSaturdayProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).showSaturday;
});

// 土曜日表示設定切り替えメソッドのプロバイダー
final toggleShowSaturdayProvider = Provider<Future<void> Function()>((ref) {
  return () => ref.read(settingsProvider.notifier).toggleShowSaturday();
});

// 学バス優先キャンパス取得プロバイダー
final preferredBusCampusProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).preferredBusCampus;
});

// 学バス優先キャンパス設定メソッドのプロバイダー
final setPreferredBusCampusProvider = Provider<Future<void> Function(String)>((ref) {
  return (campus) => ref.read(settingsProvider.notifier).setPreferredBusCampus(campus);
});
