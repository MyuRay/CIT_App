import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/home_feature_intro.dart';
import '../constants/home_feature_intro.dart';
import '../../models/user/profile_shortcut.dart';

enum AppFontSizeOption { small, medium, large }

enum CalendarWeekStart { sunday, monday }

extension CalendarWeekStartX on CalendarWeekStart {
  String get storageValue {
    switch (this) {
      case CalendarWeekStart.sunday:
        return 'sunday';
      case CalendarWeekStart.monday:
        return 'monday';
    }
  }

  String get displayName {
    switch (this) {
      case CalendarWeekStart.sunday:
        return '日曜スタート';
      case CalendarWeekStart.monday:
        return '月曜スタート';
    }
  }
}

CalendarWeekStart _weekStartFromStorage(String? value) {
  switch (value) {
    case 'sunday':
      return CalendarWeekStart.sunday;
    case 'monday':
      return CalendarWeekStart.monday;
    default:
      return CalendarWeekStart.monday;
  }
}

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
          preferredBusCampus:
              _prefs.containsKey('preferredBusCampus')
                  ? _prefs.getString('preferredBusCampus')
                  : null,
          scheduleNotificationEnabled:
              _prefs.getBool('scheduleNotificationEnabled') ?? false,
          appFontSize: _fontSizeFromStorage(_prefs.getString('appFontSize')),
          trainPreferredDirectionTsudanuma:
              _prefs.getString('train_preferred_direction_tsudanuma') ?? '',
          trainPreferredDirectionNarashino:
              _prefs.getString('train_preferred_direction_narashino') ?? '',
          calendarWeekStart: _weekStartFromStorage(
            _prefs.getString('calendarWeekStart'),
          ),
          profileShortcutVisibleIds: profileShortcutVisibleIdsFromPrefs(_prefs),
          profileShortcutsHighlightDismissedIds:
              profileShortcutHighlightDismissedIdsFromPrefs(_prefs),
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
    final saved = await _prefs.setString('preferredBusCampus', campus);
    if (!saved) throw StateError('メインキャンパスを保存できませんでした');
    await _prefs.setBool(kHomeMainCampusIntroDismissedPrefsKey, true);
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
  Future<void> setTrainPreferredDirection(
    String campusKey,
    String directionKey,
  ) async {
    if (campusKey == 'narashino') {
      await _prefs.setString(
        'train_preferred_direction_narashino',
        directionKey,
      );
      state = state.copyWith(trainPreferredDirectionNarashino: directionKey);
    } else {
      await _prefs.setString(
        'train_preferred_direction_tsudanuma',
        directionKey,
      );
      state = state.copyWith(trainPreferredDirectionTsudanuma: directionKey);
    }
  }

  // 学年暦カレンダーの週開始日を設定（日曜スタート / 月曜スタート）
  Future<void> setCalendarWeekStart(CalendarWeekStart value) async {
    await _prefs.setString('calendarWeekStart', value.storageValue);
    state = state.copyWith(calendarWeekStart: value);
  }

  Future<void> setProfileShortcutVisibleIds(
    List<ProfileShortcutId> ids,
  ) async {
    final allowed = kProfileShortcutCatalog.toSet();
    final normalized =
        ids.where(allowed.contains).toList(growable: false);
    final encoded = encodeProfileShortcutVisibleIds(normalized);
    // setString は値が同じだと false を返すことがあるため、戻り値だけでは判定しない。
    await _prefs.setString(kProfileShortcutVisibleIdsPrefsKey, encoded);
    final persisted = profileShortcutVisibleIdsFromPrefs(_prefs);
    if (!_profileShortcutListsEqual(persisted, normalized)) {
      throw StateError('よく使う機能の設定を保存できませんでした');
    }
    state = state.copyWith(profileShortcutVisibleIds: normalized);
  }

  static bool _profileShortcutListsEqual(
    List<ProfileShortcutId> a,
    List<ProfileShortcutId> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  List<ProfileShortcutId> _readProfileShortcutVisibleIds() {
    return profileShortcutVisibleIdsFromPrefs(_prefs);
  }

  Future<void> dismissProfileShortcutHighlight(ProfileShortcutId id) async {
    final next = Set<String>.from(state.profileShortcutsHighlightDismissedIds)
      ..add(id.storageKey);
    await _prefs.setString(
      kProfileShortcutsHighlightDismissedIdsPrefsKey,
      encodeProfileShortcutHighlightDismissedIds(next),
    );
    await _prefs.remove(kProfileShortcutsHighlightDismissedLegacyPrefsKey);
    state = state.copyWith(profileShortcutsHighlightDismissedIds: next);
  }

  /// マイページ関連の表示設定を初期状態に戻す（管理者向け隠し操作）。
  Future<void> resetMyPageDefaults() async {
    await _prefs.remove('preferredBusCampus');
    await _prefs.remove(kHomeMainCampusIntroDismissedPrefsKey);
    await _prefs.remove(kProfileShortcutVisibleIdsPrefsKey);
    await _prefs.remove(kProfileShortcutsHighlightDismissedIdsPrefsKey);
    await _prefs.remove(kProfileShortcutsHighlightDismissedLegacyPrefsKey);
    await _prefs.setString(
      'calendarWeekStart',
      CalendarWeekStart.monday.storageValue,
    );
    await _prefs.setString(
      'appFontSize',
      AppFontSizeOption.small.storageValue,
    );

    state = SettingsState(
      showSaturday: state.showSaturday,
      preferredBusCampus: null,
      scheduleNotificationEnabled: state.scheduleNotificationEnabled,
      appFontSize: AppFontSizeOption.small,
      trainPreferredDirectionTsudanuma: state.trainPreferredDirectionTsudanuma,
      trainPreferredDirectionNarashino: state.trainPreferredDirectionNarashino,
      calendarWeekStart: CalendarWeekStart.monday,
      profileShortcutVisibleIds: null,
      profileShortcutsHighlightDismissedIds: const {},
    );
  }

  Future<void> toggleProfileShortcut(ProfileShortcutId id) async {
    final current = List<ProfileShortcutId>.from(
      _readProfileShortcutVisibleIds(),
    );
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
      current.sort(
        (a, b) => kProfileShortcutCatalog.indexOf(a).compareTo(
          kProfileShortcutCatalog.indexOf(b),
        ),
      );
    }
    await setProfileShortcutVisibleIds(current);
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
    required this.calendarWeekStart,
    required this.profileShortcutVisibleIds,
    required this.profileShortcutsHighlightDismissedIds,
  });

  final bool showSaturday;

  /// ユーザーが明示設定したキャンパス。未設定時は null（表示は「未設定」、動作は [effectivePreferredBusCampus]）。
  final String? preferredBusCampus;

  final bool scheduleNotificationEnabled; // 講義通知の有効/無効
  final AppFontSizeOption appFontSize;
  final String trainPreferredDirectionTsudanuma;
  final String trainPreferredDirectionNarashino;
  final CalendarWeekStart calendarWeekStart; // 学年暦カレンダーの週開始日

  /// 保存済みの表示リスト。未初期化（ホットリロード直後など）のとき null。
  final List<ProfileShortcutId>? profileShortcutVisibleIds;
  final Set<String> profileShortcutsHighlightDismissedIds;

  /// アプリ内の既定キャンパス（未設定時は津田沼）。
  String get effectivePreferredBusCampus => preferredBusCampus ?? 'tsudanuma';

  List<ProfileShortcutId> get resolvedProfileShortcutVisibleIds =>
      profileShortcutVisibleIds ??
      List<ProfileShortcutId>.from(kProfileShortcutDefaultVisible);

  SettingsState copyWith({
    bool? showSaturday,
    String? preferredBusCampus,
    bool? scheduleNotificationEnabled,
    AppFontSizeOption? appFontSize,
    String? trainPreferredDirectionTsudanuma,
    String? trainPreferredDirectionNarashino,
    CalendarWeekStart? calendarWeekStart,
    List<ProfileShortcutId>? profileShortcutVisibleIds,
    Set<String>? profileShortcutsHighlightDismissedIds,
  }) {
    return SettingsState(
      showSaturday: showSaturday ?? this.showSaturday,
      preferredBusCampus: preferredBusCampus ?? this.preferredBusCampus,
      scheduleNotificationEnabled:
          scheduleNotificationEnabled ?? this.scheduleNotificationEnabled,
      appFontSize: appFontSize ?? this.appFontSize,
      trainPreferredDirectionTsudanuma:
          trainPreferredDirectionTsudanuma ??
          this.trainPreferredDirectionTsudanuma,
      trainPreferredDirectionNarashino:
          trainPreferredDirectionNarashino ??
          this.trainPreferredDirectionNarashino,
      calendarWeekStart: calendarWeekStart ?? this.calendarWeekStart,
      profileShortcutVisibleIds:
          profileShortcutVisibleIds ?? this.profileShortcutVisibleIds,
      profileShortcutsHighlightDismissedIds:
          profileShortcutsHighlightDismissedIds ??
          this.profileShortcutsHighlightDismissedIds,
    );
  }
}

// 設定プロバイダー
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return SettingsNotifier(prefs);
  },
);

// 土曜日表示設定の便利なプロバイダー
final showSaturdayProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).showSaturday;
});

// 土曜日表示設定切り替えメソッドのプロバイダー
final toggleShowSaturdayProvider = Provider<Future<void> Function()>((ref) {
  return () => ref.read(settingsProvider.notifier).toggleShowSaturday();
});

// メインキャンパス（未設定時も津田沼として扱う）
final preferredBusCampusProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).effectivePreferredBusCampus;
});

// ユーザーが保存したメインキャンパス（未設定なら null）
final preferredBusCampusStoredProvider = Provider<String?>((ref) {
  return ref.watch(settingsProvider).preferredBusCampus;
});

// 学バス優先キャンパス設定メソッドのプロバイダー
final setPreferredBusCampusProvider = Provider<Future<void> Function(String)>((
  ref,
) {
  return (campus) =>
      ref.read(settingsProvider.notifier).setPreferredBusCampus(campus);
});

// 講義通知設定のプロバイダー
final scheduleNotificationEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).scheduleNotificationEnabled;
});

// 講義通知設定切り替えメソッドのプロバイダー
final setScheduleNotificationEnabledProvider =
    Provider<Future<void> Function(bool)>((ref) {
      return (enabled) => ref
          .read(settingsProvider.notifier)
          .setScheduleNotificationEnabled(enabled);
    });

// アプリ文字サイズ設定のプロバイダー
final appFontSizeProvider = Provider<AppFontSizeOption>((ref) {
  return ref.watch(settingsProvider).appFontSize;
});

// アプリ文字サイズ設定更新メソッドのプロバイダー
final setAppFontSizeProvider =
    Provider<Future<void> Function(AppFontSizeOption)>((ref) {
      return (size) => ref.read(settingsProvider.notifier).setAppFontSize(size);
    });

// 学年暦カレンダーの週開始日プロバイダー
final calendarWeekStartProvider = Provider<CalendarWeekStart>((ref) {
  return ref.watch(settingsProvider).calendarWeekStart;
});

// 学年暦カレンダーの週開始日更新メソッドのプロバイダー
final setCalendarWeekStartProvider =
    Provider<Future<void> Function(CalendarWeekStart)>((ref) {
      return (value) =>
          ref.read(settingsProvider.notifier).setCalendarWeekStart(value);
    });

// 各タブチュートリアルの再表示要求シグナル（値をインクリメントして通知）
final tabTutorialReplaySignalProvider = StateProvider<int>((ref) => 0);

final profileShortcutVisibleIdsProvider = Provider<List<ProfileShortcutId>>((
  ref,
) {
  // SettingsState 本体はホットリロード後に古い形が残ることがあるため prefs から読む。
  ref.watch(settingsProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return profileShortcutVisibleIdsFromPrefs(prefs);
});

final resetMyPageDefaultsProvider = Provider<Future<void> Function()>((ref) {
  return () => ref.read(settingsProvider.notifier).resetMyPageDefaults();
});

final profileShortcutEmphasizedProvider = Provider.family<bool, ProfileShortcutId>(
  (ref, id) {
    ref.watch(settingsProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    return shouldEmphasizeProfileShortcut(prefs, id);
  },
);

final dismissProfileShortcutHighlightProvider =
    Provider<Future<void> Function(ProfileShortcutId)>((ref) {
      return (id) =>
          ref.read(settingsProvider.notifier).dismissProfileShortcutHighlight(id);
    });

final toggleProfileShortcutProvider =
    Provider<Future<void> Function(ProfileShortcutId)>((ref) {
      return (id) => ref.read(settingsProvider.notifier).toggleProfileShortcut(id);
    });
