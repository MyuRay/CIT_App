import 'package:flutter/material.dart';

import '../../legal/legal_document_anchor.dart';
import '../../legal/privacy_policy_screen.dart';
import '../../legal/terms_of_service_screen.dart';

/// ちばちゃんねるの説明ダイアログ
Future<void> showChibaChannelInfoDialog(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final linkColor = colorScheme.brightness == Brightness.dark
      ? const Color(0xFF9AE6A0)
      : const Color(0xFF2E7D32);

  void openTerms() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const TermsOfServiceScreen(
          initialAnchor: LegalDocumentAnchor.chibaChannel,
        ),
      ),
    );
  }

  void openPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PrivacyPolicyScreen(
          initialAnchor: LegalDocumentAnchor.chibaChannel,
        ),
      ),
    );
  }

  TextStyle linkStyle() => theme.textTheme.bodyMedium!.copyWith(
        height: 1.5,
        color: linkColor,
        decoration: TextDecoration.underline,
        decorationColor: linkColor,
      );

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(
        Icons.info_outline,
        color: colorScheme.brightness == Brightness.dark
            ? const Color(0xFF81C784)
            : const Color(0xFF2E7D32),
        size: 32,
      ),
      title: const Text('ちばちゃんねるについて'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '匿名で気軽に話せる掲示板です。ある程度自由な議論ができる場所になることを願っています。'
              '個人を特定できる形での誹謗中傷や他人が不快になるようなレス、画像は投稿しないでください。',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 12),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '詳細なルールは',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                InkWell(
                  onTap: openTerms,
                  child: Text('利用規約', style: linkStyle()),
                ),
                Text(
                  '・',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                InkWell(
                  onTap: openPrivacyPolicy,
                  child: Text('プライバシーポリシー', style: linkStyle()),
                ),
                Text(
                  'をご確認ください。',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    ),
  );
}
