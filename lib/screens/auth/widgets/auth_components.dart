import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';

/// 認証画面（ログイン / 新規登録）で共通利用するブランドカラー（淡いグリーン基調）。
class AuthPalette {
  const AuthPalette._();

  static const Color green = Color(0xFF4CAF50);
  static const Color greenDark = Color(0xFF2E7D32);
  static const Color greenDeep = Color(0xFF1B5E20);
  static const Color greenSoft = Color(0xFFE8F5E9);
  static const Color greenTint = Color(0xFFF1F8F2);
  static const Color forgotLink = Color(0xFF3D7DCA);
}

/// 背景の淡いグリーン円形グラデーション（左上）+ ドット装飾（右上）。
class AuthBackgroundDecoration extends StatelessWidget {
  const AuthBackgroundDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // 左上の大きな円形グラデーション
          Positioned(
            top: -130,
            left: -110,
            child: _glow(AuthPalette.green.withValues(alpha: 0.16), 300),
          ),
          Positioned(
            top: 60,
            left: -80,
            child: _glow(const Color(0xFF81C784).withValues(alpha: 0.12), 200),
          ),
          // 右上のドット装飾
          const Positioned(
            top: 24,
            right: 18,
            child: _DotGrid(),
          ),
        ],
      ),
    );
  }

  Widget _glow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _DotGrid extends StatelessWidget {
  const _DotGrid();

  @override
  Widget build(BuildContext context) {
    const rows = 4;
    const cols = 4;
    return Column(
      children: List.generate(rows, (r) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: List.generate(cols, (c) {
              final fade = 1 - ((r + c) / (rows + cols));
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AuthPalette.green
                        .withValues(alpha: 0.10 + 0.16 * fade),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

/// アプリアイコン + アプリ名 + 見出し（中央寄せ）。
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AuthPalette.green.withValues(alpha: 0.18),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AuthPalette.green.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/icons/app_launcher_icon.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.school,
                size: 56,
                color: AuthPalette.green,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppConstants.appName,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AuthPalette.greenDark,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// 淡いグリーンの案内カード（情報カードの土台）。
class AuthInfoCard extends StatelessWidget {
  const AuthInfoCard({
    super.key,
    required this.icon,
    required this.child,
  });

  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AuthPalette.greenSoft.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AuthPalette.green.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AuthPalette.green.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AuthPalette.greenDark),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// 利用可能ドメインの案内カード。
class AllowedEmailInfoCard extends StatelessWidget {
  const AllowedEmailInfoCard({
    super.key,
    required this.headline,
    required this.domains,
  });

  final String headline;
  final List<String> domains;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthInfoCard(
      icon: Icons.info_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            domains.join('  /  '),
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.5,
              fontWeight: FontWeight.w700,
              color: AuthPalette.greenDeep,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cwitter ID の案内カード。
class CwitterInfoCard extends StatelessWidget {
  const CwitterInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthInfoCard(
      icon: Icons.alternate_email,
      child: Text(
        '初回ログイン後、交流タブで Cwitter ID（@から始まるID）を設定すると、'
        'Cweetの投稿・返信・recweet・フォローなどが利用できます。',
        style: theme.textTheme.bodySmall?.copyWith(
          height: 1.55,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

/// 共通の入力フィールド（白背景・角丸・フォーカス時グリーン枠）。
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.autocorrect = true,
    this.inputFormatters,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;
  final bool autocorrect;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillColor =
        isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white;
    final borderColor = theme.colorScheme.outline.withValues(alpha: 0.35);

    OutlineInputBorder border(Color color, double width) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      enabled: enabled,
      autocorrect: autocorrect,
      inputFormatters: inputFormatters,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: AuthPalette.greenDark),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: border(borderColor, 1.2),
        border: border(borderColor, 1.2),
        focusedBorder: border(AuthPalette.green, 1.8),
        errorBorder:
            border(theme.colorScheme.error.withValues(alpha: 0.7), 1.2),
        focusedErrorBorder: border(theme.colorScheme.error, 1.8),
      ),
    );
  }
}

/// メインのCTAボタン（グリーングラデーション・56px・矢印アイコン付き）。
class PrimaryAuthButton extends StatelessWidget {
  const PrimaryAuthButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AuthPalette.green, AuthPalette.greenDark],
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AuthPalette.green.withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: enabled ? onPressed : null,
              child: SizedBox(
                height: 56,
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
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

/// 「または」区切り線。
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.6);

    return Row(
      children: [
        Expanded(child: Divider(color: lineColor, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'または',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        Expanded(child: Divider(color: lineColor, thickness: 1)),
      ],
    );
  }
}

/// 画面下部のサブアクションカード（軽い見た目）。
class AuthNavigationCard extends StatelessWidget {
  const AuthNavigationCard({
    super.key,
    required this.label,
    required this.onTap,
    this.leadingIcon = Icons.person_outline,
    this.tinted = false,
    this.emphasizeText = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData leadingIcon;

  /// true の場合は淡いグリーン背景（ログイン画面の新規登録導線）。
  /// false の場合は白背景+薄いグレー枠（新規登録画面のログイン導線）。
  final bool tinted;

  /// テキストをグリーンで強調する。
  final bool emphasizeText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color background;
    final Color borderColor;
    if (tinted) {
      background = isDark
          ? theme.colorScheme.surfaceContainerHighest
          : AuthPalette.greenTint;
      borderColor = AuthPalette.green.withValues(alpha: 0.25);
    } else {
      background =
          isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white;
      borderColor = theme.colorScheme.outline.withValues(alpha: 0.3);
    }

    final textColor = emphasizeText
        ? AuthPalette.greenDark
        : theme.colorScheme.onSurface.withValues(alpha: 0.85);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AuthPalette.green.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(leadingIcon, size: 20, color: AuthPalette.greenDark),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
