import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/home_feature_intro.dart';
import '../../models/user/profile_shortcut.dart';
import 'settings_provider.dart';

/// ホームタブを開くたびにインクリメント（初回表示・タブ復帰）。
final homeTabVisitSignalProvider = StateProvider<int>((ref) => 0);

final homeFeatureIntroMainCampusPendingProvider = Provider<bool>((ref) {
  ref.watch(settingsProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  final campusStored = ref.watch(preferredBusCampusStoredProvider) != null;
  final introDismissed =
      prefs.getBool(kHomeMainCampusIntroDismissedPrefsKey) ?? false;
  return shouldShowHomeMainCampusIntro(
    campusStored: campusStored,
    introDismissedPermanently: introDismissed,
  );
});

final pendingShortcutHomeFeatureIntroIdsProvider =
    Provider<List<HomeFeatureIntroId>>((ref) {
      ref.watch(settingsProvider);
      final prefs = ref.watch(sharedPreferencesProvider);
      final visibleIds = ref.watch(profileShortcutVisibleIdsProvider);
      final visibleSet = visibleIds.toSet();

      final pending = <HomeFeatureIntroId>[];
      for (final shortcutId in kProfileShortcutCatalog) {
        if (!visibleSet.contains(shortcutId)) continue;
        if (shouldEmphasizeProfileShortcut(prefs, shortcutId)) {
          pending.add(homeFeatureIntroIdForShortcut(shortcutId));
        }
      }
      return pending;
    });

/// 表示対象の一覧（メインキャンパス優先 + 強調ショートカット）。UI のインデックス用。
final pendingHomeFeatureIntroIdsProvider = Provider<List<HomeFeatureIntroId>>((
  ref,
) {
  final pending = <HomeFeatureIntroId>[];
  if (ref.watch(homeFeatureIntroMainCampusPendingProvider)) {
    pending.add(HomeFeatureIntroId.mainCampus);
  }
  pending.addAll(ref.watch(pendingShortcutHomeFeatureIntroIdsProvider));
  return pending;
});

class HomeFeatureIntroBubbleState {
  const HomeFeatureIntroBubbleState({
    required this.visible,
    this.activeId,
  });

  final bool visible;
  final HomeFeatureIntroId? activeId;

  static const hidden = HomeFeatureIntroBubbleState(
    visible: false,
    activeId: null,
  );
}

class HomeFeatureIntroBubbleNotifier
    extends StateNotifier<HomeFeatureIntroBubbleState> {
  HomeFeatureIntroBubbleNotifier() : super(HomeFeatureIntroBubbleState.hidden);

  final Random _random = Random();

  void rollForVisit({
    required bool mainCampusPending,
    required List<HomeFeatureIntroId> shortcutIds,
  }) {
    if (mainCampusPending) {
      state = const HomeFeatureIntroBubbleState(
        visible: true,
        activeId: HomeFeatureIntroId.mainCampus,
      );
      return;
    }

    if (shortcutIds.isEmpty) {
      state = HomeFeatureIntroBubbleState.hidden;
      return;
    }

    if (_random.nextDouble() >= kHomeFeatureShortcutIntroShowProbability) {
      state = HomeFeatureIntroBubbleState.hidden;
      return;
    }

    state = HomeFeatureIntroBubbleState(
      visible: true,
      activeId: shortcutIds[_random.nextInt(shortcutIds.length)],
    );
  }

  void cycleShortcutMessage(List<HomeFeatureIntroId> shortcutIds) {
    if (!state.visible || shortcutIds.length <= 1) return;
    final current = state.activeId;
    if (current == null || current == HomeFeatureIntroId.mainCampus) return;

    final index = shortcutIds.indexOf(current);
    final nextIndex = index < 0 ? 0 : (index + 1) % shortcutIds.length;
    state = HomeFeatureIntroBubbleState(
      visible: true,
      activeId: shortcutIds[nextIndex],
    );
  }

  void hide() {
    state = HomeFeatureIntroBubbleState.hidden;
  }
}

final homeFeatureIntroBubbleProvider =
    StateNotifierProvider<HomeFeatureIntroBubbleNotifier, HomeFeatureIntroBubbleState>(
      (ref) => HomeFeatureIntroBubbleNotifier(),
    );

class HomeFeatureIntroDisplay {
  const HomeFeatureIntroDisplay({required this.show, this.id});

  final bool show;
  final HomeFeatureIntroId? id;

  static const hidden = HomeFeatureIntroDisplay(show: false);
}

/// メインキャンパス未設定時は常に吹き出し。設定後はショートカット抽選結果のみ。
HomeFeatureIntroDisplay resolveHomeFeatureIntroDisplay({
  required bool mainCampusPending,
  required HomeFeatureIntroBubbleState shortcutBubble,
}) {
  if (mainCampusPending) {
    return const HomeFeatureIntroDisplay(
      show: true,
      id: HomeFeatureIntroId.mainCampus,
    );
  }
  if (shortcutBubble.visible && shortcutBubble.activeId != null) {
    return HomeFeatureIntroDisplay(
      show: true,
      id: shortcutBubble.activeId,
    );
  }
  return HomeFeatureIntroDisplay.hidden;
}
