import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/auth_provider.dart';

class ChangeEmailScreen extends ConsumerStatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  ConsumerState<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends ConsumerState<ChangeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _newEmailController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeForm());
  }

  void _initializeForm() {
    if (!mounted) return;

    final currentEmail = FirebaseAuth.instance.currentUser?.email?.trim();
    if (AppConstants.hasChibatechEmailDomain(currentEmail)) {
      context.go('/home');
      return;
    }

    final suggested = AppConstants.suggestMigratedEmail(currentEmail);
    if (suggested != null && _newEmailController.text.trim().isEmpty) {
      _newEmailController.text = suggested;
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _newEmailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final pendingEmail = await ref.read(authServiceProvider).requestEmailChange(
            currentPassword: _passwordController.text,
            newEmail: _newEmailController.text,
          );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.pendingEmailChangeKey, pendingEmail);

      if (!mounted) return;
      context.go('/change-email-verification');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapAuthError(e))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('メール変更の申請に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'パスワードが正しくありません';
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています';
      case 'requires-recent-login':
        return 'セキュリティ保護のため、一度ログアウトして再ログインしてからお試しください';
      case 'too-many-requests':
        return 'リクエストが多すぎます。しばらく待ってから再試行してください';
      default:
        return e.message ?? 'メール変更の申請に失敗しました';
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final currentEmail = FirebaseAuth.instance.currentUser?.email?.trim() ?? '';
    final emailController = TextEditingController(text: currentEmail);
    String? errorText;
    bool sending = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('パスワードを再設定'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '登録済みのCITメールアドレスに再設定リンクを送信します。\n'
                    '届かない場合は迷惑メールフォルダも確認してください。',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !sending,
                    decoration: InputDecoration(
                      labelText: 'メールアドレス',
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: sending ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed: sending
                      ? null
                      : () async {
                          setDialogState(() {
                            sending = true;
                            errorText = null;
                          });
                          try {
                            await ref.read(authServiceProvider).sendPasswordResetEmail(
                                  email: emailController.text,
                                );
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '再設定メールを送信しました（迷惑メールフォルダも確認してください）',
                                ),
                              ),
                            );
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() {
                              sending = false;
                              errorText = e.message ?? '送信に失敗しました';
                            });
                          } catch (_) {
                            setDialogState(() {
                              sending = false;
                              errorText = '送信に失敗しました';
                            });
                          }
                        },
                  child: sending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('送信'),
                ),
              ],
            );
          },
        );
      },
    );
    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('メールアドレス変更')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 20, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '大学メールのドメイン変更に対応するため、新しいCITメールアドレスへ変更できます。\n'
                          '変更には現在のパスワード入力と、新しいメールアドレスの認証が必要です。',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '現在のメールアドレス',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  currentEmail.isEmpty ? '（取得できません）' : currentEmail,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: '現在のパスワード',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword ? 'パスワードを表示' : 'パスワードを非表示',
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'パスワードを入力してください';
                    }
                    if (value.length < 6) {
                      return AppConstants.errorWeakPassword;
                    }
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _showForgotPasswordDialog,
                    child: const Text('パスワードを忘れた場合はこちら'),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _newEmailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  inputFormatters: AppConstants.citEmailInputFormatters,
                  textInputAction: TextInputAction.done,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: '新しいCITメールアドレス',
                    hintText: 'example${AppConstants.newEmailDomain}',
                    prefixIcon: const Icon(Icons.email_outlined),
                    helperText:
                        '${AppConstants.emailInputHelper}\n${AppConstants.allowedDomains.join(' / ')}',
                    helperMaxLines: 3,
                  ),
                  validator: (value) {
                    final baseError = AppConstants.validateCitEmail(value);
                    if (baseError != null) {
                      return value == null || value.isEmpty
                          ? '新しいメールアドレスを入力してください'
                          : baseError;
                    }
                    if (value!.trim().toLowerCase() == currentEmail.trim().toLowerCase()) {
                      return '現在と同じメールアドレスです';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('確認メールを送信'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
