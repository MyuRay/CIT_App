import '../../../widgets/home/guide_highlight.dart';
import 'package:flutter/material.dart';

import '../../../widgets/home/my_page_relocation_guide.dart';

class ControlTutorialStep {
  const ControlTutorialStep({
    required this.anchor,
    required this.title,
    required this.description,
    this.onEnter,
  });

  final GlobalKey anchor;
  final String title;
  final String description;
  final Future<void> Function()? onEnter;
}

enum _TutorialChoice { previous, next, later }

/// Explain the real controls without running demo actions or changing settings.
Future<bool> showVisualTabTutorial(
  BuildContext context, {
  required List<ControlTutorialStep> steps,
  required bool Function() isCurrentSession,
  ValueChanged<ControlTutorialStep>? onStepShown,
  ControlTutorialStep? closingStep,
}) async {
  Future<bool> finishTutorial() async {
    if (!context.mounted || !isCurrentSession()) return false;
    final step = closingStep;
    if (step == null) return true;
    await step.onEnter?.call();
    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted || !isCurrentSession()) return false;
    final anchorContext = step.anchor.currentContext;
    if (anchorContext != null) {
      await Scrollable.ensureVisible(anchorContext, alignment: 0.5);
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!context.mounted || !isCurrentSession()) return false;
    final target = resolveGuideHighlight(context, step.anchor);
    if (target == null) return false;
    onStepShown?.call(step);
    final acknowledged = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'チュートリアルの終了案内',
      barrierColor: Colors.transparent,
      transitionDuration:
          MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
      transitionBuilder:
          (_, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
      pageBuilder:
          (dialogContext, animation, secondary) => MyPageRelocationGuide(
            target: target.rect,
            targetShape: target.shape,
            avatarKey: step.anchor,
            title: step.title,
            description: step.description,
            continueLabel: '終了する',
          ),
    );
    return acknowledged == true && context.mounted && isCurrentSession();
  }

  var index = 0;
  var shownAny = false;
  while (index < steps.length && context.mounted && isCurrentSession()) {
    final step = steps[index];
    await step.onEnter?.call();
    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted || !isCurrentSession()) return false;
    final anchorContext = step.anchor.currentContext;
    if (anchorContext != null) {
      await Scrollable.ensureVisible(anchorContext, alignment: 0.5);
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!context.mounted || !isCurrentSession()) return false;
    final target = resolveGuideHighlight(context, step.anchor);
    if (target == null) {
      index++;
      continue;
    }
    onStepShown?.call(step);
    shownAny = true;
    final choice = await showGeneralDialog<_TutorialChoice>(
      context: context,
      barrierDismissible: false,
      barrierLabel: '使い方ガイド',
      barrierColor: Colors.transparent,
      transitionDuration:
          MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
      transitionBuilder:
          (_, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
      pageBuilder:
          (dialogContext, animation, secondary) => MyPageRelocationGuide(
            target: target.rect,
            targetShape: target.shape,
            avatarKey: step.anchor,
            title: step.title,
            description: step.description,
            stepLabel: '${index + 1} / ${steps.length}',
            continueLabel: index == steps.length - 1 ? '完了' : '次へ',
            onContinue:
                () => Navigator.pop(dialogContext, _TutorialChoice.next),
            onPrevious:
                index == 0
                    ? null
                    : () =>
                        Navigator.pop(dialogContext, _TutorialChoice.previous),
            onSkip: () => Navigator.pop(dialogContext, _TutorialChoice.later),
          ),
    );
    if (choice == null || !context.mounted || !isCurrentSession()) return false;
    if (choice == _TutorialChoice.later) return finishTutorial();
    if (choice == _TutorialChoice.previous) {
      index = (index - 1).clamp(0, steps.length - 1);
    } else {
      index++;
    }
  }
  if (index != steps.length || !shownAny) return false;
  return finishTutorial();
}
