import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppFontSizeOption { small, medium, large }

extension AppFontSizeOptionX on AppFontSizeOption {
  String get storageValue {
    switch (this) {
      case AppFontSizeOption.small:
        return 'small';
      case AppFontSizeOption.medium:
        return 'medium';
      case AppFontSizeOption.large:
        return 'large';
    }
  }

  String get displayName {
    switch (this) {
      case AppFontSizeOption.small:
        return '小(推奨)';
      case AppFontSizeOption.medium:
        return '中';
      case AppFontSizeOption.large:
        return '大';
    }
  }

  double get textScale {
    switch (this) {
      case AppFontSizeOption.small:
        return 0.9;
      case AppFontSizeOption.medium:
        return 1.0;
      case AppFontSizeOption.large:
        return 1.15;
    }
  }
}

AppFontSizeOption _fontSizeFromStorage(String? value) {
  switch (value) {
    case 'small':
      return AppFontSizeOption.small;
    case 'large':
      return AppFontSizeOption.large;
    case 'medium':
      return AppFontSizeOption.medium;
    default:
      return AppFontSizeOption.small;
  }
}

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
            scheduleNotificationEnabled: _prefs.getBool('scheduleNotificationEnabled') ?? false,
            appFontSize: _fontSizeFromStorage(_prefs.getString('appFontSize')),
            trainPreferredDirectionTsudanuma:
                _prefs.getString('train_preferred_direction_tsudanuma') ?? '',
            trainPreferredDirectionNarashino:
                _prefs.getString('train_preferred_direction_narashino') ?? '',
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

  // 講義通知の有効/無効を設定
  Future<void> setScheduleNotificationEnabled(bool enabled) async {
    await _prefs.setBool('scheduleNotificationEnabled', enabled);
    state = state.copyWith(scheduleNotificationEnabled: enabled);
  }

  // アプリ内の文字サイズ設定を変更
  Future<void> setAppFontSize(AppFontSizeOption fontSize) async {
    await _prefs.setString('appFontSize', fontSize.storageValue);
    state = state.copyWith(appFontSize: fontSize);
  }

  /// 電車スナップショットの優先方面（`directionKey`、空なら先頭方面を使用）
  Future<void> setTrainPreferredDirection(String campusKey, String directionKey) async {
    if (campusKey == 'narashino') {
      await _prefs.setString('train_preferred_direction_narashino', directionKey);
      state = state.copyWith(trainPreferredDirectionNarashino: directionKey);
    } else {
      await _prefs.setString('train_preferred_direction_tsudanuma', directionKey);
      state = state.copyWith(trainPreferredDirectionTsudanuma: directionKey);
    }
  }
}

// 設定状態クラス
class SettingsState {
  const SettingsState({
    required this.showSaturday,
    required this.preferredBusCampus,
    required this.scheduleNotificationEnabled,
    required this.appFontSize,
    required this.trainPreferredDirectionTsudanuma,
    required this.trainPreferredDirectionNarashino,
  });

  final bool showSaturday;
  final String preferredBusCampus; // 'tsudanuma' or 'narashino'
  final bool scheduleNotificationEnabled; // 講義通知の有効/無効
  final AppFontSizeOption appFontSize;
  final String trainPreferredDirectionTsudanuma;
  final String trainPreferredDirectionNarashino;

  SettingsState copyWith({
    bool? showSaturday,
    String? preferredBusCampus,
    bool? scheduleNotificationEnabled,
    AppFontSizeOption? appFontSize,
    String? trainPreferredDirectionTsudanuma,
    String? trainPreferredDirectionNarashino,
  }) {
    return SettingsState(
      showSaturday: showSaturday ?? this.showSaturday,
      preferredBusCampus: preferredBusCampus ?? this.preferredBusCampus,
      scheduleNotificationEnabled: scheduleNotificationEnabled ?? this.scheduleNotificationEnabled,
      appFontSize: appFontSize ?? this.appFontSize,
      trainPreferredDirectionTsudanuma:
          trainPreferredDirectionTsudanuma ?? this.trainPreferredDirectionTsudanuma,
      trainPreferredDirectionNarashino:
          trainPreferredDirectionNarashino ?? this.trainPreferredDirectionNarashino,
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

// 講義通知設定のプロバイダー
final scheduleNotificationEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).scheduleNotificationEnabled;
});

// 講義通知設定切り替えメソッドのプロバイダー
final setScheduleNotificationEnabledProvider = Provider<Future<void> Function(bool)>((ref) {
  return (enabled) => ref.read(settingsProvider.notifier).setScheduleNotificationEnabled(enabled);
});

// アプリ文字サイズ設定のプロバイダー
final appFontSizeProvider = Provider<AppFontSizeOption>((ref) {
  return ref.watch(settingsProvider).appFontSize;
});

// アプリ文字サイズ設定更新メソッドのプロバイダー
final setAppFontSizeProvider = Provider<Future<void> Function(AppFontSizeOption)>((ref) {
  return (size) => ref.read(settingsProvider.notifier).setAppFontSize(size);
});

// 各タブチュートリアルの再表示要求シグナル（値をインクリメントして通知）
final tabTutorialReplaySignalProvider = StateProvider<int>((ref) => 0);
