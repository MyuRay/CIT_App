import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/cwitter_pin_provider.dart';
import '../../../core/providers/schedule_provider.dart';
import '../../../models/community/cwitter_post.dart';

Future<void> changeCwitterPin(
  BuildContext context,
  WidgetRef ref, {
  required CwitterPost post,
  required bool pinned,
}) async {
  final uid = ref.read(currentUserIdProvider);
  if (uid == null || uid != post.authorId) return;
  final saving = ref.read(cwitterPinSavingProvider(uid).notifier);
  if (saving.state) return;
  saving.state = true;
  try {
    final currentPin = await ref.read(cwitterPinnedPostIdProvider(uid).future);
    if (!context.mounted || ref.read(currentUserIdProvider) != uid) return;
    if (pinned && currentPin != null && currentPin != post.id) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              scrollable: true,
              title: const Text('固定するCweetを変更'),
              content: const Text('プロフィールに固定できるCweetは1件です。このCweetに変更しますか？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('変更する'),
                ),
              ],
            ),
      );
      if (confirmed != true) return;
    }
    if (!context.mounted || ref.read(currentUserIdProvider) != uid) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(cwitterPinServiceProvider)
        .setPinned(userId: uid, postId: post.id, pinned: pinned);
    // Moving the post to the pinned slot can dispose its original card.
    if (messenger.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(pinned ? 'プロフィールに固定しました' : '固定を解除しました')),
      );
    }
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error is StateError
              ? error.message.toString()
              : '固定の設定を保存できませんでした。もう一度お試しください',
        ),
      ),
    );
  } finally {
    if (saving.mounted) saving.state = false;
  }
}
