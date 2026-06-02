import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../services/user/user_service.dart';
import 'widgets/auth_components.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
    _loadPostEmailChangeLoginEmail();
  }

  Future<void> _loadPostEmailChangeLoginEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(AppConstants.postEmailChangeLoginEmailKey);
      if (email == null || email.isEmpty || !mounted) return;

      _emailController.text = email;
      await prefs.remove(AppConstants.postEmailChangeLoginEmailKey);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'メールアドレスの変更が完了しました。新しいメールアドレスでログインしてください。',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      });
    } catch (_) {}
  }

  Future<void> _loadRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool('remember_me');
      if (saved != null && mounted) {
        setState(() => _rememberMe = saved);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 明示的なログイン保持設定
      try {
        await FirebaseAuth.instance.setPersistence(
          _rememberMe ? Persistence.LOCAL : Persistence.SESSION,
        );
      } catch (_) {
        // モバイルでは未対応のため無視
      }

      // ユーザーの選択を保存
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', _rememberMe);
      } catch (_) {}

      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // ログイン後、メール認証状態をFirestoreに同期
      // （ルーターがFirestoreの状態を監視して自動的にリダイレクトする）
      if (mounted) {
        // メール認証状態をFirestoreに同期（ルーターが監視して遷移する）
        await UserService.syncCurrentUserEmailVerification();

        // ルーターが自動的に遷移するまで少し待つ
        await Future.delayed(const Duration(milliseconds: 300));

        // 念のため、Firebase Authの状態も確認して遷移
        final isVerified = await authService.checkEmailVerification();
        if (mounted) {
          if (isVerified) {
            // メール認証済みの場合、ホームへ
            context.go('/home');
          } else {
            // メール認証未完了の場合、認証待ち画面へ
            context.go('/email-verification');
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'ログインに失敗しました')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController =
        TextEditingController(text: _emailController.text.trim());
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
                  onPressed:
                      sending ? null : () => Navigator.of(dialogContext).pop(),
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
                            await ref
                                .read(authServiceProvider)
                                .sendPasswordResetEmail(
                                  email: emailController.text,
                                );
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(this.context).showSnackBar(
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

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'メールアドレスを入力してください';
    }
    if (!value.contains('@')) {
      return AppConstants.errorInvalidEmail;
    }
    if (!AppConstants.isAllowedDomain(value)) {
      return AppConstants.errorInvalidDomain;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'パスワードを入力してください';
    }
    if (value.length < 6) {
      return AppConstants.errorWeakPassword;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            const AuthBackgroundDecoration(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 16,
                      bottom: 24 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 40,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: _buildContent(theme),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 26),
            child: child,
          ),
        );
      },
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const AuthHeader(title: 'ログイン'),
            const SizedBox(height: 28),
            AllowedEmailInfoCard(
              headline: '千葉工業大学のメールアドレスのみ利用可能です',
              domains: AppConstants.allowedDomains,
            ),
            const SizedBox(height: 22),
            AuthTextField(
              controller: _emailController,
              hintText: 'CITメールアドレス',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              autocorrect: false,
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _passwordController,
              hintText: 'パスワード',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              enabled: !_isLoading,
              autocorrect: false,
              validator: _validatePassword,
              onFieldSubmitted: (_) => _isLoading ? null : _signIn(),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'パスワードを表示' : 'パスワードを非表示',
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading ? null : _showForgotPasswordDialog,
                style: TextButton.styleFrom(
                  foregroundColor: AuthPalette.forgotLink,
                ),
                child: const Text('パスワードを忘れた方'),
              ),
            ),
            const SizedBox(height: 4),
            _RememberLoginRow(
              value: _rememberMe,
              onChanged: _isLoading
                  ? null
                  : (v) => setState(() => _rememberMe = v),
            ),
            const SizedBox(height: 22),
            PrimaryAuthButton(
              label: 'ログイン',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _signIn,
            ),
            const SizedBox(height: 22),
            const AuthDivider(),
            const SizedBox(height: 22),
            AuthNavigationCard(
              label: 'アカウントをお持ちでない方はこちら',
              tinted: true,
              onTap: _isLoading ? null : () => context.go('/signup'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// 「ログイン状態を保持する」行（広いタップ領域）。
class _RememberLoginRow extends StatelessWidget {
  const _RememberLoginRow({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onChanged != null;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: enabled ? () => onChanged!(!value) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: enabled ? (v) => onChanged!(v ?? true) : null,
                activeColor: AuthPalette.green,
                checkColor: Colors.white,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'ログイン状態を保持する',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
