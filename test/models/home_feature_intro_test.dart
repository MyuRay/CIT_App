import 'package:cit_app/core/constants/home_feature_intro.dart';
import 'package:cit_app/core/providers/home_feature_intro_provider.dart';
import 'package:cit_app/models/user/profile_shortcut.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('homeFeatureIntroMessage', () {
    test('covers every intro id', () {
      for (final id in HomeFeatureIntroId.values) {
        expect(homeFeatureIntroMessage(id).trim().isNotEmpty, isTrue);
      }
    });

    test('maps every shortcut to an intro id', () {
      for (final id in ProfileShortcutId.values) {
        final introId = homeFeatureIntroIdForShortcut(id);
        expect(introId.name, isNotEmpty);
        expect(homeFeatureIntroMessage(introId).trim().isNotEmpty, isTrue);
      }
    });
  });

  group('shouldShowHomeMainCampusIntro', () {
    test('hidden after campus saved once', () {
      expect(
        shouldShowHomeMainCampusIntro(
          campusStored: true,
          introDismissedPermanently: true,
        ),
        isFalse,
      );
    });

    test('shown only when never saved and not dismissed', () {
      expect(
        shouldShowHomeMainCampusIntro(
          campusStored: false,
          introDismissedPermanently: false,
        ),
        isTrue,
      );
      expect(
        shouldShowHomeMainCampusIntro(
          campusStored: false,
          introDismissedPermanently: true,
        ),
        isFalse,
      );
    });
  });

  group('HomeFeatureIntroBubbleNotifier', () {
    test('main campus pending always shows main campus intro', () {
      final notifier = HomeFeatureIntroBubbleNotifier();
      notifier.rollForVisit(
        mainCampusPending: true,
        shortcutIds: const [
          HomeFeatureIntroId.assignments,
          HomeFeatureIntroId.theme,
        ],
      );
      expect(notifier.state.visible, isTrue);
      expect(notifier.state.activeId, HomeFeatureIntroId.mainCampus);
    });

    test('cycleShortcutMessage skips main campus bubble', () {
      final notifier = HomeFeatureIntroBubbleNotifier();
      notifier.rollForVisit(
        mainCampusPending: true,
        shortcutIds: const [HomeFeatureIntroId.assignments],
      );
      notifier.cycleShortcutMessage(const [HomeFeatureIntroId.assignments]);
      expect(notifier.state.activeId, HomeFeatureIntroId.mainCampus);
    });

    test('cycleShortcutMessage rotates shortcut intros', () {
      final notifier = HomeFeatureIntroBubbleNotifier();
      notifier.state = const HomeFeatureIntroBubbleState(
        visible: true,
        activeId: HomeFeatureIntroId.assignments,
      );
      notifier.cycleShortcutMessage(const [
        HomeFeatureIntroId.assignments,
        HomeFeatureIntroId.theme,
      ]);
      expect(notifier.state.activeId, HomeFeatureIntroId.theme);
    });

    test('rollForVisit hides when no targets', () {
      final notifier = HomeFeatureIntroBubbleNotifier();
      notifier.rollForVisit(
        mainCampusPending: false,
        shortcutIds: const [],
      );
      expect(notifier.state.visible, isFalse);
    });

    test('resolveHomeFeatureIntroDisplay forces main campus while pending', () {
      final display = resolveHomeFeatureIntroDisplay(
        mainCampusPending: true,
        shortcutBubble: HomeFeatureIntroBubbleState.hidden,
      );
      expect(display.show, isTrue);
      expect(display.id, HomeFeatureIntroId.mainCampus);
    });

    test('resolveHomeFeatureIntroDisplay uses shortcut bubble after campus', () {
      const bubble = HomeFeatureIntroBubbleState(
        visible: true,
        activeId: HomeFeatureIntroId.theme,
      );
      final display = resolveHomeFeatureIntroDisplay(
        mainCampusPending: false,
        shortcutBubble: bubble,
      );
      expect(display.id, HomeFeatureIntroId.theme);
    });
  });
}
