import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/providers/auth_provider.dart';

final accountDeletionSubmitProvider = Provider<Future<void> Function(String)>((
  ref,
) {
  final auth = ref.watch(firebaseAuthProvider);
  final logout = ref.watch(authServiceProvider);
  return (password) async {
    final user = auth.currentUser;
    if (user == null || user.email == null) throw StateError('ログインが必要です');
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: user.email!, password: password),
    );
    final token = await user.getIdToken(true);
    final response = await http
        .post(
          Uri.parse(
            'https://us-central1-cit-app-2de1c.cloudfunctions.net/deleteMyAccount',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'confirm': true}),
        )
        .timeout(const Duration(seconds: 45));
    if (response.statusCode != 202) {
      if (response.statusCode == 401) {
        throw FirebaseAuthException(code: 'requires-recent-login');
      }
      throw StateError('削除を開始できませんでした');
    }
    await logout.signOutAfterAccountDeletion();
  };
});

class AccountDeletionScreen extends ConsumerStatefulWidget {
  const AccountDeletionScreen({super.key});
  @override
  ConsumerState<AccountDeletionScreen> createState() =>
      _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends ConsumerState<AccountDeletionScreen> {
  final _password = TextEditingController();
  bool _confirmed = false, _sending = false, _accepted = false;
  String? _error;
  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_confirmed || _sending || _accepted || _password.text.isEmpty) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(accountDeletionSubmitProvider)(_password.text);
      if (mounted) {
        _password.clear();
        setState(() => _accepted = true);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(
          () =>
              _error = switch (e.code) {
                'wrong-password' || 'invalid-credential' => 'パスワードが正しくありません。',
                'requires-recent-login' => '本人確認の有効期限が切れました。もう一度お試しください。',
                'too-many-requests' => '試行回数が多すぎます。しばらく待ってからお試しください。',
                _ => '本人確認ができませんでした。通信状況を確認してください。',
              },
        );
      }
    } on TimeoutException {
      if (mounted) {
        setState(
          () =>
              _error =
                  '通信がタイムアウトしました。受け付け済みの場合は自動で削除が進みます。まだログインできる場合は再度お試しください。',
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = '削除を開始できませんでした。通信状況を確認して再度お試しください。');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_sending,
      child: Scaffold(
        appBar: AppBar(title: const Text('アカウント削除')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_accepted) ...[
                const Text('アカウントの削除を開始しました。'),
                const SizedBox(height: 12),
                const Text('アプリを閉じても自動で処理が続きます。運営の承認は不要です。'),
              ] else ...[
                const Text('アカウントと関連データを削除します。削除後は復元できません。'),
                const SizedBox(height: 16),
                const Text(
                  'プロフィール、時間割・出欠・課題、投稿・コメント・レビュー、アップロード画像、通知登録などが対象です。',
                ),
                const SizedBox(height: 12),
                const Text('本人確認後にログアウトし、サーバーで自動削除します。アプリを閉じても処理が続きます。'),
                const SizedBox(height: 12),
                const Text('不正利用・トラブル対応に必要な通報や運営記録は、必要な期間に限り保管します。'),
                const SizedBox(height: 20),
                TextField(
                  controller: _password,
                  obscureText: true,
                  enabled: !_sending,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: '現在のパスワード',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _confirmed,
                  onChanged:
                      _sending
                          ? null
                          : (v) => setState(() => _confirmed = v ?? false),
                  title: const Text('アカウントと関連データを削除し、復元できないことを確認しました'),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!, style: TextStyle(color: colors.error)),
                  ),
                FilledButton.icon(
                  onPressed:
                      _confirmed && !_sending && _password.text.isNotEmpty
                          ? _submit
                          : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                  ),
                  icon:
                      _sending
                          ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.onError,
                            ),
                          )
                          : const Icon(Icons.delete_forever_outlined),
                  label: Text(_sending ? '本人確認・削除開始中…' : 'アカウントを削除する'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
