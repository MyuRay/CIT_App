import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/settings_provider.dart';

const String _cwitterGuidelinesDismissedKey = 'cwitter_guidelines_dismissed';

/// 投稿前に表示する Cwitter の心得
class CwitterPostingGuidelinesDialog {
  CwitterPostingGuidelinesDialog._();

  /// `true` = 投稿を続行してよい
  static Future<bool> confirmIfNeeded(BuildContext context, WidgetRef ref) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs.getBool(_cwitterGuidelinesDismissedKey) ?? false) {
      return true;
    }

    if (!context.mounted) return false;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => _CwitterPostingGuidelinesDialogBody(
            parentRef: ref,
          ),
        ) ??
        false;
  }
}

class _CwitterPostingGuidelinesDialogBody extends ConsumerStatefulWidget {
  const _CwitterPostingGuidelinesDialogBody({required this.parentRef});

  final WidgetRef parentRef;

  @override
  ConsumerState<_CwitterPostingGuidelinesDialogBody> createState() =>
      _CwitterPostingGuidelinesDialogBodyState();
}

class _CwitterPostingGuidelinesDialogBodyState
    extends ConsumerState<_CwitterPostingGuidelinesDialogBody> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.info_outline,
        color: theme.colorScheme.primary,
        size: 32,
      ),
      title: const Text('Cwitterの利用にあたって'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cweetする前に、次の点をご確認ください。',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            const _GuidelineItem(
              text: '本アプリの投稿規定（利用規約・コミュニティガイドライン）を守ってください。',
            ),
            const _GuidelineItem(
              text: '大学のメールアドレスで登録していることの自覚を持ち、Cweet内容に個人情報や不適切な表現が含まれていないか確認してください。',
            ),
            const _GuidelineItem(
              text: '誹謗中傷・差別・迷惑行為・著作権侵害など、他者や大学に不利益となるCweetはしないでください。',
            ),
            const _GuidelineItem(
              text: '営利目的の宣伝・勧誘、商品・サービスの販売、広告・PR等を目的としたCweetはしないでください（運営者が許可したものを除く）。',
            ),
            const _GuidelineItem(
              text: 'R18コンテンツや暴力的な内容のCweetはしないでください。',
            ),
            const _GuidelineItem(
              text: '内容に問題がないことを確認したうえでCweetしてください。',
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _dontShowAgain,
              onChanged: (value) {
                setState(() => _dontShowAgain = value ?? false);
              },
              title: const Text('今後このポップアップを表示しない'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () async {
            if (_dontShowAgain) {
              await widget.parentRef
                  .read(sharedPreferencesProvider)
                  .setBool(_cwitterGuidelinesDismissedKey, true);
            }
            if (context.mounted) {
              Navigator.of(context).pop(true);
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
          ),
          child: const Text('確認してCweet'),
        ),
      ],
    );
  }
}

class _GuidelineItem extends StatelessWidget {
  const _GuidelineItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '・',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
