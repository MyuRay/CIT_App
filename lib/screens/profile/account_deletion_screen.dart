import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/auth_provider.dart';
import '../../services/contact/contact_service.dart';

const accountDeletionEmail = 'masatomurai2004@gmail.com';
const accountDeletionSubject = 'CIT App アカウント・関連データの削除申請';
const accountDeletionMessage =
    'CIT App のアカウントと関連データの削除を希望します。\n'
    '対象：認証アカウント、プロフィール、時間割・出欠、投稿・コメント・レビュー、'
    'アップロード画像、通知登録、その他このアカウントに関連するデータ。\n'
    '運営による確認・削除が必要であり、送信時点では削除が完了しないことを確認しました。'
    '対応予定および完了結果を登録メールアドレスへお知らせください。';

/// Reuses the existing support queue. No authentication or profile data is
/// deleted before the operator can remove the associated data as well.
final accountDeletionSubmitProvider = Provider<Future<String> Function()>((
  ref,
) {
  final auth = ref.watch(firebaseAuthProvider);
  return () {
    final user = auth.currentUser;
    if (user == null) throw StateError('ログインが必要です');
    return ContactService.createContact(
      name: user.displayName,
      email: user.email,
      category: 'account',
      categoryName: 'アカウント関連',
      subject: accountDeletionSubject,
      message: accountDeletionMessage,
    );
  };
});

class AccountDeletionScreen extends ConsumerStatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  ConsumerState<AccountDeletionScreen> createState() =>
      _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends ConsumerState<AccountDeletionScreen> {
  bool _confirmed = false;
  bool _sending = false;
  String? _requestId;
  String? _error;

  Future<void> _submit() async {
    if (!_confirmed || _sending || _requestId != null) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final id = await ref
          .read(accountDeletionSubmitProvider)()
          .timeout(const Duration(seconds: 30));
      if (mounted) setState(() => _requestId = id);
    } on TimeoutException {
      if (mounted) {
        setState(
          () =>
              _error =
                  '送信結果を確認できませんでした。マイページのお問い合わせ履歴を確認し、'
                  '申請がなければ再度お試しいただくか、下記メール窓口をご利用ください。',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error =
                  '申請を送信できませんでした。通信状況をご確認のうえ再度お試しいただくか、'
                  '下記メール窓口をご利用ください。',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: accountDeletionEmail,
      query:
          'subject=${Uri.encodeComponent(accountDeletionSubject)}&body=${Uri.encodeComponent('登録メールアドレス：\n\n$accountDeletionMessage')}',
    );
    try {
      if (await launchUrl(uri)) return;
    } catch (_) {
      /* The address remains selectable without a mail app. */
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メールアプリを開けませんでした。下記のアドレスをコピーしてご連絡ください。')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_sending,
      child: Scaffold(
        appBar: AppBar(title: const Text('アカウント削除')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                _requestId == null ? 'アカウントと関連データの削除を申請' : '削除申請を受け付けました',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text(
                '運営が申請を確認し、アカウントと関連データを削除します。'
                '送信した時点では削除は完了せず、処理が完了するまでアカウントは残ります。'
                '対応予定と完了結果は登録メールアドレスへご案内します。',
              ),
              const SizedBox(height: 16),
              const Text('削除対象', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'アカウント・プロフィール、時間割・出欠、投稿・コメント・レビュー、'
                'アップロード画像、通知登録などの関連データ。削除後は復元できません。',
              ),
              const SizedBox(height: 8),
              const Text(
                '法令順守・不正利用やトラブルへの対応に必要な記録は、必要な範囲で保管し、'
                '目的がなくなった時点で削除または匿名化します。',
              ),
              const SizedBox(height: 20),
              if (_requestId case final id?) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '受付済み・削除処理待ち',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SelectableText('受付番号：$id'),
                        const SizedBox(height: 8),
                        const Text('マイページの「お問い合わせ履歴」から申請内容を確認できます。'),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _confirmed,
                  onChanged:
                      _sending
                          ? null
                          : (value) =>
                              setState(() => _confirmed = value ?? false),
                  title: const Text('削除対象と、運営による削除手続きが必要なことを確認しました'),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                FilledButton.icon(
                  onPressed: _confirmed && !_sending ? _submit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  icon:
                      _sending
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.send_outlined),
                  label: Text(_sending ? '送信中…' : '削除を申請する'),
                ),
              ],
              const SizedBox(height: 28),
              Text('アプリで申請できない場合', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              const Text(
                '登録メールアドレスから、件名に「CIT App アカウント削除」と記載して'
                '下記へご連絡ください。アプリの再インストールは不要です。パスワードは送らないでください。',
              ),
              const SizedBox(height: 8),
              const SelectableText(accountDeletionEmail),
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: _openEmail,
                    icon: const Icon(Icons.mail_outline),
                    label: const Text('メールを作成'),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        const ClipboardData(text: accountDeletionEmail),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('メールアドレスをコピーしました')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('コピー'),
                  ),
                ],
              ),
              Text(
                '運営：CIT App開発・運営チーム（代表：村井雅斗）',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
