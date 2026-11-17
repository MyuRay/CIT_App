import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/legal_consent_provider.dart';

/// 現在の規約・ポリシーへの同意を確認するゲート
class CommunityLegalUpdateConsentGate extends ConsumerWidget {
  const CommunityLegalUpdateConsentGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasConsent = ref.watch(hasAcceptedCurrentLegalConsentProvider);
    if (hasConsent) return child;
    final status = ref.watch(legalConsentStatusProvider);

    return PopScope(
      canPop: false,
      child: Stack(
        children: [
          child,
          ModalBarrier(
            dismissible: false,
            color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.55),
          ),
          if (status.isLoading || status.hasError)
            SafeArea(
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(24),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (status.isLoading) ...[
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          const Text('同意状況を確認しています…'),
                        ] else ...[
                          const Text('同意状況を確認できませんでした。接続を確認して再試行してください。'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed:
                                () =>
                                    ref.invalidate(legalConsentStatusProvider),
                            child: const Text('再試行'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            const _CommunityLegalUpdateConsentSheet(),
        ],
      ),
    );
  }
}

class _CommunityLegalUpdateConsentSheet extends ConsumerStatefulWidget {
  const _CommunityLegalUpdateConsentSheet();

  @override
  ConsumerState<_CommunityLegalUpdateConsentSheet> createState() =>
      _CommunityLegalUpdateConsentSheetState();
}

class _CommunityLegalUpdateConsentSheetState
    extends ConsumerState<_CommunityLegalUpdateConsentSheet> {
  bool _agreedTerms = false;
  bool _agreedPrivacy = false;
  bool _isSaving = false;
  String? _saveError;

  Future<void> _accept() async {
    if (!_agreedTerms || !_agreedPrivacy || _isSaving) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      await recordLegalConsentAcceptance(ref);
    } catch (_) {
      if (mounted) {
        setState(() => _saveError = '同意を保存できませんでした。接続を確認して、もう一度お試しください。');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canAccept = _agreedTerms && _agreedPrivacy && !_isSaving;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              color: colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.policy_outlined,
                        size: 36,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '利用規約・プライバシーポリシーを更新しました',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.35,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '主な変更内容\n'
                        '・運営者と問い合わせ先の明記\n'
                        '・投稿や問い合わせ等を運営用Discordへ送信することと、退会時の削除範囲\n'
                        '・登録メールから推定した学年による広告表示と、その計測\n'
                        '・Excel改善用データの任意提供（初期状態はオン、取り込み前に解除可能）\n'
                        '・情報の保存方針と、利用制限・損害賠償の扱い\n\n'
                        '更新後の全文をご確認ください。Excelの提供は、取り込みのたびに選べます。',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '運営通知では、投稿・問い合わせの内容と、表示名・ユーザーID・メールの一部等をDiscordへ送信します。'
                        '運営メンバーが新着確認・問い合わせ対応・通報確認のために閲覧します。'
                        'メールを一部伏せても、個人との関連がなくなるわけではありません。'
                        '過去の通知は退会時の自動削除に含まれない場合があります。\n\n'
                        '同意しない場合や、アプリを利用せずに削除を請求する場合の窓口：citapp919@gmail.com',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        value: _agreedTerms,
                        onChanged:
                            _isSaving
                                ? null
                                : (value) {
                                  setState(() => _agreedTerms = value ?? false);
                                },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        title: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => context.push('/terms'),
                              child: Text(
                                '利用規約',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const Text('に同意する'),
                          ],
                        ),
                      ),
                      CheckboxListTile(
                        value: _agreedPrivacy,
                        onChanged:
                            _isSaving
                                ? null
                                : (value) {
                                  setState(
                                    () => _agreedPrivacy = value ?? false,
                                  );
                                },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        title: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => context.push('/privacy'),
                              child: Text(
                                'プライバシーポリシー',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const Text('に同意する'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_saveError != null) ...[
                        Text(
                          _saveError!,
                          style: TextStyle(color: colorScheme.error),
                        ),
                        const SizedBox(height: 8),
                      ],
                      FilledButton(
                        onPressed: canAccept ? _accept : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: AppColors.onColor(
                            const Color(0xFF4CAF50),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child:
                            _isSaving
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onColor(
                                      const Color(0xFF4CAF50),
                                    ),
                                  ),
                                )
                                : const Text('同意して利用を開始する'),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed:
                            _isSaving ? null : () => SystemNavigator.pop(),
                        child: const Text('同意しない（アプリを終了）'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
