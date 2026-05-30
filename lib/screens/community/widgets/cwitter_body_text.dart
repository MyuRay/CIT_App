import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final _urlRegex = RegExp(r'(https?:\/\/[^\s)]+)');

/// Cweet / 返信本文。テキスト選択・コピーと URL タップに対応。
class CwitterBodyText extends StatelessWidget {
  const CwitterBodyText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.linkColor,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final Color? linkColor;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    return SelectionArea(
      child: Text.rich(
        TextSpan(
          style: baseStyle,
          children: buildCwitterLinkSpans(
            context: context,
            text: text,
            baseStyle: baseStyle,
            linkColor: linkColor,
          ),
        ),
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
      ),
    );
  }
}

List<InlineSpan> buildCwitterLinkSpans({
  required BuildContext context,
  required String text,
  required TextStyle baseStyle,
  Color? linkColor,
}) {
  final spans = <InlineSpan>[];
  final effectiveLinkColor =
      linkColor ?? Theme.of(context).colorScheme.primary;
  var start = 0;

  for (final match in _urlRegex.allMatches(text)) {
    if (match.start > start) {
      spans.add(TextSpan(text: text.substring(start, match.start)));
    }
    final url = text.substring(match.start, match.end);
    spans.add(
      TextSpan(
        text: url,
        style: baseStyle.copyWith(
          color: effectiveLinkColor,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => launchExternalUrlWithConfirmation(context, url),
      ),
    );
    start = match.end;
  }

  if (start < text.length) {
    spans.add(TextSpan(text: text.substring(start)));
  }

  return spans;
}

Future<void> launchExternalUrlWithConfirmation(
  BuildContext context,
  String url,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return AlertDialog(
        title: const Text('外部サイトを開く'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'このリンクはCIT App外のサイトです。'
              '内容の安全性は保証されません。ブラウザで開きます。',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            SelectableText(
              url,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text('開く'),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) return;

  final uri = Uri.tryParse(url);
  if (uri == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('リンクが無効です: $url')),
    );
    return;
  }

  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('リンクを開けませんでした: $url')),
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('リンクを開けませんでした: $e')),
    );
  }
}
