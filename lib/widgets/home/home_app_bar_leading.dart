import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/constants/home_feature_intro.dart';
import '../../core/providers/home_feature_intro_provider.dart';
import '../../screens/profile/simple_profile_screen.dart';
import 'home_my_page_guide_bubble.dart';

/// ホーム AppBar 左側：マイページアバター＋（条件付き）機能紹介吹き出し。
class HomeAppBarLeading extends ConsumerStatefulWidget {
  const HomeAppBarLeading({super.key, required this.avatar});

  final Widget avatar;

  @override
  ConsumerState<HomeAppBarLeading> createState() => _HomeAppBarLeadingState();

  static double leadingWidth(
    BuildContext context, {
    required bool showBubble,
    String message = '',
    String tapHint = '(タップで確認)',
  }) {
    if (!showBubble) return 48;
    const avatarSlot = 48.0;
    const gap = 2.0;
    final bubbleWidth = HomeMyPageGuideBubble.contentWidth(
      context,
      message: message,
      tapHint: tapHint,
    );
    final desired = avatarSlot + gap + bubbleWidth;
    final maxLeading = MediaQuery.sizeOf(context).width - 112;
    return desired.clamp(avatarSlot, maxLeading);
  }
}

class _HomeAppBarLeadingState extends ConsumerState<HomeAppBarLeading> {
  int? _lastProcessedVisit;

  void _rollShortcutIntroForVisit(int visit) {
    if (_lastProcessedVisit == visit) return;
    _lastProcessedVisit = visit;

    if (ref.read(homeFeatureIntroMainCampusPendingProvider)) {
      return;
    }

    ref.read(homeFeatureIntroBubbleProvider.notifier).rollForVisit(
      mainCampusPending: false,
      shortcutIds: ref.read(pendingShortcutHomeFeatureIntroIdsProvider),
    );
  }

  void _rollShortcutIntroNow() {
    _lastProcessedVisit = null;
    ref.read(homeFeatureIntroBubbleProvider.notifier).rollForVisit(
      mainCampusPending: false,
      shortcutIds: ref.read(pendingShortcutHomeFeatureIntroIdsProvider),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _rollShortcutIntroForVisit(ref.read(homeTabVisitSignalProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(homeTabVisitSignalProvider, (previous, next) {
      _rollShortcutIntroForVisit(next);
    });

    ref.listen<bool>(homeFeatureIntroMainCampusPendingProvider, (
      previous,
      next,
    ) {
      if (previous == true && next == false) {
        _rollShortcutIntroNow();
      }
    });

    final mainCampusPending = ref.watch(homeFeatureIntroMainCampusPendingProvider);
    final shortcutIds = ref.watch(pendingShortcutHomeFeatureIntroIdsProvider);
    final shortcutBubble = ref.watch(homeFeatureIntroBubbleProvider);
    final display = resolveHomeFeatureIntroDisplay(
      mainCampusPending: mainCampusPending,
      shortcutBubble: shortcutBubble,
    );

    if (!mainCampusPending &&
        shortcutIds.isEmpty &&
        shortcutBubble.visible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(homeFeatureIntroBubbleProvider.notifier).hide();
      });
    }

    final showBubble = display.show && display.id != null;
    final message =
        showBubble ? homeFeatureIntroMessage(display.id!) : '';

    void openMyPage() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SimpleProfileScreen()),
      );
    }

    void onBubbleTap() {
      if (mainCampusPending) {
        openMyPage();
        return;
      }
      if (kHomeFeatureIntroTapCyclesMessages) {
        ref
            .read(homeFeatureIntroBubbleProvider.notifier)
            .cycleShortcutMessage(shortcutIds);
        return;
      }
      openMyPage();
    }

    if (!showBubble) {
      return Align(alignment: Alignment.centerLeft, child: widget.avatar);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.avatar,
          const SizedBox(width: 2),
          HomeMyPageGuideBubble(
            message: message,
            onTap: onBubbleTap,
          ),
        ],
      ),
    );
  }
}
