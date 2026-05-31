import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// Cwitter ID（@付き）と、公式アカウントなら「公式」タグを表示する。
class CwitterHandleText extends StatelessWidget {
  const CwitterHandleText({
    super.key,
    required this.cwitterId,
    this.style,
    this.maxLines = 1,
    this.showOfficialTag = true,
  });

  final String cwitterId;
  final TextStyle? style;
  final int? maxLines;
  final bool showOfficialTag;

  @override
  Widget build(BuildContext context) {
    final handle = '@$cwitterId';
    final isOfficial = AppConstants.isOfficialCwitterAccount(cwitterId);

    if (!isOfficial || !showOfficialTag) {
      return Text(
        handle,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            handle,
            style: style,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        const CwitterOfficialTag(),
      ],
    );
  }
}

/// @citapp など公式 Cwitter アカウント向けの「公式」タグ。
class CwitterOfficialTag extends StatelessWidget {
  const CwitterOfficialTag({super.key});

  static const _gold = Color(0xFFD4AF37);
  static const _goldDeep = Color(0xFF9A7B1A);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFFFE082) : _goldDeep;
    final accent = isDark ? const Color(0xFFFFD54F) : _gold;
    final backgroundColor = accent.withValues(alpha: isDark ? 0.28 : 0.18);
    final borderColor = accent.withValues(alpha: isDark ? 0.72 : 0.55);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        '公式',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.2,
        ),
      ),
    );
  }
}
