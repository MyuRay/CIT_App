import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

/// 旧ドメイン（@s.chibakoudai.jp / @p.chibakoudai.jp）利用者向けの
/// メールアドレス変更推奨ダイアログ。
class LegacyEmailMigrationDialog {
  LegacyEmailMigrationDialog._();

  static bool shouldShow(String? email) =>
      AppConstants.shouldPromptEmailMigration(email);

  static Future<void> showIfNeeded(
    BuildContext context, {
    required String uid,
    required String? email,
    required SharedPreferences preferences,
  }) async {
    final dismissedKey = 'legacy_email_migration_dismissed:$uid';
    if (!context.mounted ||
        uid.isEmpty ||
        !shouldShow(email) ||
        preferences.getBool(dismissedKey) == true) {
      return;
    }

    var doNotShowAgain = false;
    final changeEmail = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                icon: Icon(
                  Icons.alternate_email,
                  color: Theme.of(dialogContext).colorScheme.primary,
                  size: 32,
                ),
                title: const Text('メールアドレスの変更をお願いします'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '大学メールのドメインが変更されました。\n\n'
                        '@s.chibakoudai.jp または @p.chibakoudai.jp で登録されている方は、'
                        '新しいCITメールアドレス（@chibatech.ac.jp）への変更をお願いします。\n\n'
                        '変更には現在のパスワードと、新しいメールアドレスの認証が必要です。',
                      ),
                      const SizedBox(height: 12),
                      const Text('メールアドレスはマイページからいつでも変更可能です。'),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('今後表示しない'),
                        value: doNotShowAgain,
                        onChanged: (value) {
                          setDialogState(() => doNotShowAgain = value ?? false);
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('あとで'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('変更する'),
                  ),
                ],
              );
            },
          ),
    );

    if (doNotShowAgain) {
      await preferences.setBool(dismissedKey, true);
    }
    if (changeEmail == true && context.mounted) {
      context.push('/change-email');
    }
  }
}
