import 'dart:async';



import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

import '../../services/user/user_service.dart';



class ChangeEmailVerificationScreen extends ConsumerStatefulWidget {

  const ChangeEmailVerificationScreen({super.key});



  @override

  ConsumerState<ChangeEmailVerificationScreen> createState() =>

      _ChangeEmailVerificationScreenState();

}



class _ChangeEmailVerificationScreenState

    extends ConsumerState<ChangeEmailVerificationScreen> {

  static const Duration _autoCheckInterval = Duration(seconds: 10);



  String? _pendingEmail;

  bool _isChecking = false;

  Timer? _checkTimer;



  @override

  void initState() {

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {

      _loadPendingEmail();

    });

    _checkTimer = Timer.periodic(_autoCheckInterval, (_) {

      _checkCompletion(showLoading: false);

    });

  }



  @override

  void dispose() {

    _checkTimer?.cancel();

    super.dispose();

  }



  Future<void> _loadPendingEmail() async {

    final prefs = await SharedPreferences.getInstance();

    final pending = prefs.getString(AppConstants.pendingEmailChangeKey);

    if (!mounted) return;



    if (pending == null || pending.isEmpty) {

      context.go('/change-email');

      return;

    }



    setState(() => _pendingEmail = pending);

    await _checkCompletion(showLoading: false);

  }



  Future<void> _clearPendingEmail() async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(AppConstants.pendingEmailChangeKey);

  }



  Future<void> _finishWithReauth(String newEmail) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(AppConstants.postEmailChangeLoginEmailKey, newEmail);

    await _clearPendingEmail();



    try {

      await FirebaseAuth.instance.signOut();

    } catch (_) {}



    if (!mounted) return;



    await showDialog<void>(

      context: context,

      barrierDismissible: false,

      builder: (dialogContext) => AlertDialog(

        icon: Icon(

          Icons.check_circle_outline,

          color: Theme.of(dialogContext).colorScheme.primary,

        ),

        title: const Text('メールアドレスを変更しました'),

        content: Text(

          'セキュリティのため、一度ログアウトしました。\n\n'

          '新しいメールアドレス（$newEmail）とパスワードで、再度ログインしてください。',

        ),

        actions: [

          FilledButton(

            onPressed: () => Navigator.of(dialogContext).pop(),

            child: const Text('ログイン画面へ'),

          ),

        ],

      ),

    );



    if (!mounted) return;

    context.go('/login');

  }



  Future<void> _checkCompletion({required bool showLoading}) async {

    if (_isChecking || _pendingEmail == null) return;



    if (showLoading && mounted) {

      setState(() => _isChecking = true);

    }



    try {

      final result = await UserService.checkEmailChangeCompletion(_pendingEmail!);

      if (!mounted) return;



      switch (result) {

        case EmailChangeCheckResult.notCompleted:

          if (showLoading) {

            ScaffoldMessenger.of(context).showSnackBar(

              const SnackBar(

                content: Text(

                  'まだ変更が反映されていません。メール内のリンクを開いてから再度お試しください。',

                ),

              ),

            );

          }

        case EmailChangeCheckResult.completed:

          await _clearPendingEmail();

          ScaffoldMessenger.of(context).showSnackBar(

            const SnackBar(content: Text('メールアドレスを変更しました')),

          );

          context.go('/home');

        case EmailChangeCheckResult.completedRequiresReauth:

          await _finishWithReauth(_pendingEmail!);

      }

    } catch (e) {

      if (showLoading && mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text('確認に失敗しました: $e')),

        );

      }

    } finally {

      if (showLoading && mounted) {

        setState(() => _isChecking = false);

      }

    }

  }



  @override

  Widget build(BuildContext context) {

    final colorScheme = Theme.of(context).colorScheme;

    final pendingEmail = _pendingEmail;



    if (pendingEmail == null) {

      return const Scaffold(

        body: Center(child: CircularProgressIndicator()),

      );

    }



    return Scaffold(

      appBar: AppBar(title: const Text('新しいメールの認証')),

      body: SafeArea(

        child: SingleChildScrollView(

          padding: const EdgeInsets.all(24),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [

              Icon(

                Icons.mark_email_unread_outlined,

                size: 72,

                color: colorScheme.primary,

              ),

              const SizedBox(height: 20),

              Text(

                '新しいメールアドレスの認証',

                textAlign: TextAlign.center,

                style: Theme.of(context).textTheme.headlineSmall?.copyWith(

                      fontWeight: FontWeight.bold,

                    ),

              ),

              const SizedBox(height: 16),

              Container(

                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(

                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),

                  borderRadius: BorderRadius.circular(12),

                ),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    const Text('新しいメールアドレスに確認メールを送信しました。'),

                    const SizedBox(height: 12),

                    const Text('メール内のリンクを開くと、メールアドレスの変更が完了します。'),

                    const SizedBox(height: 12),

                    Text(

                      '送信先: $pendingEmail',

                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(

                            fontWeight: FontWeight.bold,

                          ),

                    ),

                    const SizedBox(height: 12),

                    Text(

                      'リンクを開いたあと「変更完了を確認」を押してください。'

                      '変更後は新しいメールアドレスでの再ログインが必要になる場合があります。',

                      style: Theme.of(context).textTheme.bodySmall,

                    ),

                  ],

                ),

              ),

              const SizedBox(height: 24),

              SizedBox(

                height: 48,

                child: FilledButton.icon(

                  onPressed: _isChecking

                      ? null

                      : () => _checkCompletion(showLoading: true),

                  icon: _isChecking

                      ? const SizedBox(

                          width: 20,

                          height: 20,

                          child: CircularProgressIndicator(strokeWidth: 2),

                        )

                      : const Icon(Icons.refresh),

                  label: Text(_isChecking ? '確認中...' : '変更完了を確認'),

                ),

              ),

              const SizedBox(height: 12),

              Container(

                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(

                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),

                  borderRadius: BorderRadius.circular(8),

                ),

                child: const Text(

                  'メールが届かない場合は迷惑メールフォルダを確認してください。\n'

                  'リンクを開いたあと「変更完了を確認」を押すか、数十秒待つと自動で確認します。',

                ),

              ),

              const SizedBox(height: 16),

              TextButton(

                onPressed: () => context.go('/change-email'),

                child: const Text('メールアドレスを入力し直す'),

              ),

            ],

          ),

        ),

      ),

    );

  }

}


