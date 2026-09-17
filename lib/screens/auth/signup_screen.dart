import 'dart:async';
import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/email_registration_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/legal_consent_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../services/auth/email_registration.dart';
import 'widgets/auth_components.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key, this.emailLink, this.completing = false});
  final String? emailLink;
  final bool completing;
  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _linkController = TextEditingController();
  bool _isLoading = false,
      _obscurePassword = true,
      _obscureConfirmPassword = true;
  bool _agreedTerms = false, _agreedPrivacy = false;
  String? _sentTo;
  String? _registrationEmail;
  int _cooldown = 0;
  Timer? _resendTimer;
  bool get _completing => widget.completing || widget.emailLink != null;
  bool get _needsEmail => _completing && _registrationEmail == null;

  @override
  void initState() {
    super.initState();
    final registration = ref.read(emailRegistrationServiceProvider);
    final pending = registration.pendingEmail;
    final email =
        registration.hasPendingSetup
            ? registration.auth.currentUser?.email
            : pending;
    _emailController.text = email ?? '';
    if (_completing && email?.isNotEmpty == true) {
      _registrationEmail = email!.trim().toLowerCase();
    }
    _displayNameController.text =
        registration.auth.currentUser?.displayName ?? '';
    if (!_completing) _sentTo = pending;
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final controller in [
      _displayNameController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
      _linkController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _submit() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    if (_needsEmail) {
      setState(() {
        _registrationEmail = _emailController.text.trim().toLowerCase();
        _emailController.text = _registrationEmail!;
      });
      FocusScope.of(context).unfocus();
      return;
    }
    if (_completing && (!_agreedTerms || !_agreedPrivacy)) {
      _message('利用規約とプライバシーポリシーに同意してください');
      return;
    }
    setState(() => _isLoading = true);
    final service = ref.read(emailRegistrationServiceProvider);
    final completionState = ref.read(registrationCompletingProvider.notifier);
    final consentRevision = ref.read(legalConsentRevisionProvider.notifier);
    if (_completing) completionState.state = true;
    try {
      if (!_completing) {
        await service.sendLink(_emailController.text);
        if (!mounted) return;
        setState(() {
          _sentTo = _emailController.text.trim();
          _cooldown = 60;
        });
        _resendTimer?.cancel();
        _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted || _cooldown <= 1) {
            timer.cancel();
            if (mounted) setState(() => _cooldown = 0);
          } else {
            setState(() => _cooldown--);
          }
        });
        _message('確認メールを送信しました。メール内のリンクから登録を続けてください。');
      } else {
        await service.complete(
          email: _registrationEmail!,
          link: widget.emailLink ?? '',
          displayName: _displayNameController.text,
          password: _passwordController.text,
        );
        consentRevision.state++;
        _passwordController.clear();
        _confirmPasswordController.clear();
        if (mounted) context.go('/home');
      }
    } catch (error) {
      _message(registrationErrorMessage(error));
    } finally {
      if (_completing) completionState.state = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _usePastedLink() {
    final link = normalizeRegistrationLink(_linkController.text);
    if (link == null) {
      _message('確認メールにある登録リンクを、そのまま貼り付けてください。');
      return;
    }
    context.go(
      Uri(path: '/signup/complete', queryParameters: {'link': link}).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              const AuthBackgroundDecoration(),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AuthHeader(
                              title: _completing ? '登録を完了する' : 'メールアドレスを確認',
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _completing
                                  ? 'ステップ 2 / 2　表示名とパスワードを設定'
                                  : 'ステップ 1 / 2　大学のメールアドレスを確認',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _completing
                                  ? _needsEmail
                                      ? '確認メールを受け取ったアドレスを入力してください。'
                                      : 'このメールアドレスでアカウントを作成します。'
                                  : '確認メールのリンクを開いてからアカウントを作成します。メールを送信しただけでは登録されません。',
                            ),
                            const SizedBox(height: 18),
                            AllowedEmailInfoCard(
                              headline: '千葉工業大学のメールアドレスで登録できます',
                              domains: AppConstants.signupAllowedDomains,
                            ),
                            const SizedBox(height: 18),
                            AuthTextField(
                              controller: _emailController,
                              hintText: 'CITメールアドレス',
                              prefixIcon: Icons.alternate_email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction:
                                  _completing
                                      ? TextInputAction.next
                                      : TextInputAction.done,
                              enabled: !_isLoading,
                              readOnly: _completing && !_needsEmail,
                              suffixIcon:
                                  _completing && !_needsEmail
                                      ? const Icon(Icons.lock_outline)
                                      : null,
                              autocorrect: false,
                              inputFormatters:
                                  AppConstants.citEmailInputFormatters,
                              validator: AppConstants.validateCitEmailForSignup,
                            ),
                            if (_completing && !_needsEmail) ...[
                              const SizedBox(height: 12),
                              AuthTextField(
                                controller: _displayNameController,
                                hintText: '表示名（掲示板・レビューなどに表示）',
                                prefixIcon: Icons.person_outline,
                                enabled: !_isLoading,
                                textInputAction: TextInputAction.next,
                                validator:
                                    (value) =>
                                        (value?.trim().length ?? 0) < 2
                                            ? '表示名は2文字以上で入力してください'
                                            : null,
                              ),
                              const SizedBox(height: 12),
                              AuthTextField(
                                controller: _passwordController,
                                hintText: 'パスワード',
                                prefixIcon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                enabled: !_isLoading,
                                autocorrect: false,
                                textInputAction: TextInputAction.next,
                                inputFormatters:
                                    AppConstants.passwordInputFormatters,
                                validator: AppConstants.validatePassword,
                                suffixIcon: IconButton(
                                  tooltip:
                                      _obscurePassword
                                          ? 'パスワードを表示'
                                          : 'パスワードを非表示',
                                  onPressed:
                                      () => setState(
                                        () =>
                                            _obscurePassword =
                                                !_obscurePassword,
                                      ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              AuthTextField(
                                controller: _confirmPasswordController,
                                hintText: 'パスワード（確認）',
                                prefixIcon: Icons.lock_outline,
                                obscureText: _obscureConfirmPassword,
                                enabled: !_isLoading,
                                autocorrect: false,
                                textInputAction: TextInputAction.done,
                                inputFormatters:
                                    AppConstants.passwordInputFormatters,
                                validator:
                                    (value) =>
                                        value != _passwordController.text ||
                                                (value?.isEmpty ?? true)
                                            ? AppConstants.errorPasswordMismatch
                                            : null,
                                suffixIcon: IconButton(
                                  tooltip:
                                      _obscureConfirmPassword
                                          ? 'パスワードを表示'
                                          : 'パスワードを非表示',
                                  onPressed:
                                      () => setState(
                                        () =>
                                            _obscureConfirmPassword =
                                                !_obscureConfirmPassword,
                                      ),
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _PasswordRecommendationNote(),
                              const SizedBox(height: 12),
                              Text(
                                '登録済みのメールアドレスの場合は、アカウントを引き継ぎ、入力したパスワードに更新します。',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
                              _AgreementCheckboxRow(
                                value: _agreedTerms,
                                enabled: !_isLoading,
                                onChanged:
                                    (v) => setState(() => _agreedTerms = v),
                                linkLabel: '利用規約',
                                suffixLabel: 'に同意します',
                                onTapLink: () => context.push('/terms'),
                              ),
                              _AgreementCheckboxRow(
                                value: _agreedPrivacy,
                                enabled: !_isLoading,
                                onChanged:
                                    (v) => setState(() => _agreedPrivacy = v),
                                linkLabel: 'プライバシーポリシー',
                                suffixLabel: 'に同意します',
                                onTapLink: () => context.push('/privacy'),
                              ),
                            ],
                            const SizedBox(height: 20),
                            PrimaryAuthButton(
                              label:
                                  _completing
                                      ? _needsEmail
                                          ? 'このメールアドレスで続ける'
                                          : 'メールを認証して登録を完了'
                                      : _cooldown > 0
                                      ? '再送まで $_cooldown秒'
                                      : _sentTo == null
                                      ? '確認メールを送信'
                                      : '確認メールを再送',
                              isLoading: _isLoading,
                              onPressed:
                                  _isLoading ||
                                          (!_completing && _cooldown > 0) ||
                                          (_completing &&
                                              !_needsEmail &&
                                              (!_agreedTerms ||
                                                  !_agreedPrivacy))
                                      ? null
                                      : _submit,
                            ),
                            if (!_completing && _sentTo != null) ...[
                              const SizedBox(height: 18),
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  '$_sentTo に送信しました。受信トレイと迷惑メールを確認してください。',
                                ),
                              ),
                              const SizedBox(height: 12),
                              ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                title: const Text('リンクからアプリが開かない場合'),
                                children: [
                                  const Text(
                                    'メールの登録リンクを長押ししてコピーし、ここに貼り付けてください。送信先と同じメールアドレスで続けます。',
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _linkController,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    decoration: const InputDecoration(
                                      labelText: 'メールの登録リンク',
                                    ),
                                    minLines: 1,
                                    maxLines: 3,
                                  ),
                                  TextButton(
                                    onPressed:
                                        _isLoading ? null : _usePastedLink,
                                    child: const Text('貼り付けたリンクで続ける'),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 24),
                            if (ref
                                    .read(emailRegistrationServiceProvider)
                                    .auth
                                    .currentUser !=
                                null)
                              TextButton(
                                onPressed:
                                    _isLoading
                                        ? null
                                        : () async {
                                          await ref
                                              .read(authServiceProvider)
                                              .signOut();
                                          if (context.mounted) {
                                            context.go('/login');
                                          }
                                        },
                                child: const Text('いったんログアウトする'),
                              ),
                            if (_completing)
                              TextButton(
                                onPressed:
                                    _isLoading
                                        ? null
                                        : () => context.go('/signup'),
                                child: const Text('新しい確認メールを送る'),
                              ),
                            AuthNavigationCard(
                              label: 'すでにアカウントをお持ちの方はこちら',
                              emphasizeText: true,
                              onTap:
                                  _isLoading
                                      ? null
                                      : () => context.go('/login'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
          Icon(Icons.info_outline, size: 16, color: theme.colorScheme.primary),
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
                activeColor: AuthPalette.greenDark,
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
                        color: AppColors.accent(context, AuthPalette.greenDark),
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.accent(
                          context,
                          AuthPalette.greenDark,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    suffixLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.85,
                      ),
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
