import 'package:flutter/material.dart';

import '../../../models/community/cwitter_post.dart';

/// recweet 実行前の確認ダイアログ。`true` のとき recweet してよい。
Future<bool> showCwitterRecweetConfirmationDialog(
  BuildContext context, {
  required CwitterPost post,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('recweetしますか？'),
        content: Text(
          '「${post.displayName}」さんのCweetをフォロー中のタイムラインに共有します。',
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
            ),
            child: const Text('recweet'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
