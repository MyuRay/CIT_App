import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/legal_consent_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/settings_provider.dart';
import 'widgets/auth_components.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedTerms = false;
  bool _agreedPrivacy = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _agreedTerms && _agreedPrivacy && !_isLoading;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedTerms || !_agreedPrivacy) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('利用規約とプライバシーポリシーに同意してください')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUpWithEmailAndPassword(
        displayName: _displayNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await ref.read(sharedPreferencesProvider).setString(
            AppConstants.legalConsentAcceptedVersionKey,
            AppConstants.currentLegalConsentVersion,
          );
      ref.read(legalConsentRevisionProvider.notifier).state++;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '確認メールを送信しました。認証完了後にログインし、'
              '交流タブでCwitter IDを設定してご利用を開始できます。',
            ),
            duration: Duration(seconds: 5),
          ),
        );
        // メール認証待ち画面へ遷移
        context.go('/email-verification');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'アカウント作成に失敗しました')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '表示名を入力してください';
    }
    if (value.trim().length < 2) {
      return '表示名は2文字以上で入力してください';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'パスワードを再入力してください';
    }
    if (value != _passwordController.text) {
      return AppConstants.errorPasswordMismatch;
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const AuthHeader(title: 'アカウント作成'),
            const SizedBox(height: 28),
            AllowedEmailInfoCard(
              headline: '千葉工業大学のメールアドレスのみ登録可能です',
              domains: AppConstants.signupAllowedDomains,
            ),
            const SizedBox(height: 12),
            const CwitterInfoCard(),
            const SizedBox(height: 22),
            AuthTextField(
              controller: _displayNameController,
              hintText: '表示名（掲示板、学食レビュー、交流機能に表示されます）',
              prefixIcon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              validator: _validateDisplayName,
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _emailController,
              hintText: 'CITメールアドレス',
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              autocorrect: false,
              inputFormatters: AppConstants.citEmailInputFormatters,
              validator: AppConstants.validateCitEmailForSignup,
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _passwordController,
              hintText: 'パスワード',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              autocorrect: false,
              inputFormatters: AppConstants.passwordInputFormatters,
              validator: AppConstants.validatePassword,
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
            const SizedBox(height: 12),
            AuthTextField(
              controller: _confirmPasswordController,
              hintText: 'パスワード（確認）',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              enabled: !_isLoading,
              autocorrect: false,
              inputFormatters: AppConstants.passwordInputFormatters,
              validator: _validateConfirmPassword,
              suffixIcon: IconButton(
                tooltip:
                    _obscureConfirmPassword ? 'パスワードを表示' : 'パスワードを非表示',
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _PasswordRecommendationNote(),
            const SizedBox(height: 16),
            _AgreementCheckboxRow(
              value: _agreedTerms,
              enabled: !_isLoading,
              onChanged: (v) => setState(() => _agreedTerms = v),
              linkLabel: '利用規約',
              suffixLabel: 'に同意します',
              onTapLink: () => context.push('/terms'),
            ),
            _AgreementCheckboxRow(
              value: _agreedPrivacy,
              enabled: !_isLoading,
              onChanged: (v) => setState(() => _agreedPrivacy = v),
              linkLabel: 'プライバシーポリシー',
              suffixLabel: 'に同意します',
              onTapLink: () => context.push('/privacy'),
            ),
            const SizedBox(height: 22),
            PrimaryAuthButton(
              label: 'アカウントを作成',
              isLoading: _isLoading,
              onPressed: _canSubmit ? _signUp : null,
            ),
            const SizedBox(height: 22),
            const AuthDivider(),
            const SizedBox(height: 22),
            AuthNavigationCard(
              label: 'すでにアカウントをお持ちの方はこちら',
              emphasizeText: true,
              onTap: _isLoading ? null : () => context.go('/login'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// パスワードに関する注意書き。
class _PasswordRecommendationNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'MARINEアカウント及び大学関連サービスとは違うパスワードを使うことを推奨します',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 利用規約・プライバシーポリシー同意チェック（行全体タップで切替）。
class _AgreementCheckboxRow extends StatelessWidget {
  const _AgreementCheckboxRow({
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.linkLabel,
    required this.suffixLabel,
    required this.onTapLink,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final String linkLabel;
  final String suffixLabel;
  final VoidCallback onTapLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: enabled ? () => onChanged(!value) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: enabled ? (v) => onChanged(v ?? false) : null,
                activeColor: AuthPalette.green,
                checkColor: Colors.white,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  GestureDetector(
                    onTap: enabled ? onTapLink : null,
                    child: Text(
                      linkLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AuthPalette.greenDark,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: AuthPalette.greenDark,
                      ),
                    ),
                  ),
                  Text(
                    suffixLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
