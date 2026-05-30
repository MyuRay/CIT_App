import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';

/// 旧ドメイン（@s.chibakoudai.jp / @p.chibakoudai.jp）利用者向けの
/// メールアドレス変更推奨ダイアログ。
class LegacyEmailMigrationDialog {
  LegacyEmailMigrationDialog._();

  static bool shouldShow(String? email) =>
      AppConstants.shouldPromptEmailMigration(email);

  static Future<void> showIfNeeded(
    BuildContext context, {
    required String? email,
  }) async {
    if (!shouldShow(email)) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(
            Icons.alternate_email,
            color: Theme.of(dialogContext).colorScheme.primary,
            size: 32,
          ),
          title: const Text('メールアドレスの変更をお願いします'),
          content: const Text(
            '大学メールのドメインが変更されました。\n\n'
            '@s.chibakoudai.jp または @p.chibakoudai.jp で登録されている方は、'
            'マイページから新しいCITメールアドレス（@chibatech.ac.jp など）への変更をお願いします。\n\n'
            '変更には現在のパスワードと、新しいメールアドレスの認証が必要です。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('あとで'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  context.push('/change-email');
                }
              },
              child: const Text('変更する'),
            ),
          ],
        );
      },
    );
  }
}
