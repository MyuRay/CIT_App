import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../services/user/user_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Stack(
            children: [
              // Header background (brand color)
              Container(
                height: 240,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.85),
                    ],
                  ),
                ),
              ),

              // Scrollable content
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            // Logo + App name
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Image.asset(
                                    'assets/icons/app_icon.png',
                                    height: 64,
                                    width: 64,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.school,
                                      size: 56,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  AppConstants.appName,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Card with form
                            Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'ログイン',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 16),
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
                                                '千葉工業大学のメールアドレスのみ利用可能です\n${AppConstants.allowedDomains.join(' / ')}',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        decoration: const InputDecoration(
                                          labelText: 'CITメールアドレス',
                                          hintText: 'example@s.chibakoudai.jp / example@p.chibakoudai.jp / example@chibatech.ac.jp',
                                          prefixIcon: Icon(Icons.email_outlined),
                                          helperText: '※ 上記のドメインのみ利用可能',
                                          helperMaxLines: 2,
                                        ),
                                        validator: (value) {
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
                                        },
                                      ),
                                      const SizedBox(height: 14),
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        decoration: InputDecoration(
                                          labelText: 'パスワード',
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
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: _isLoading
                                            ? null
                                            : (v) => setState(() => _rememberMe = v ?? true),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('ログイン状態を保持する'),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    height: 48,
                                    child: FilledButton(
                                      onPressed: _isLoading ? null : _signIn,
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 22,
                                                  width: 22,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : const Text('ログイン'),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextButton(
                                        onPressed: _isLoading ? null : () => context.go('/signup'),
                                        child: const Text('アカウントをお持ちでない方はこちら'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
