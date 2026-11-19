import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/cwitter_provider.dart';
import '../../../core/providers/schedule_provider.dart';
import 'cwitter_id_setup_view.dart';

/// Viewing is available without an ID; actions ask explicitly before setup.
Future<void> promptCwitterIdRegistration(
  BuildContext context,
  WidgetRef ref, {
  required String action,
}) async {
  final uid = ref.read(currentUserIdProvider);
  if (uid == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ログインが必要です')));
    return;
  }
  final register = await showDialog<bool>(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: const Text('CweetIDを設定'),
          content: Text('$actionにはCweetIDの設定が必要です。\n投稿の閲覧はIDなしでも続けられます。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('あとで'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('設定する'),
            ),
          ],
        ),
  );
  if (register != true ||
      !context.mounted ||
      ref.read(currentUserIdProvider) != uid) {
    return;
  }
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder:
          (setupContext) => Scaffold(
            appBar: AppBar(title: const Text('CweetIDを設定')),
            body: CwitterIdSetupView(
              onRegistered: () => Navigator.of(setupContext).pop(),
              onLater: () => Navigator.of(setupContext).pop(),
            ),
          ),
    ),
  );
}

bool hasCurrentCwitterIdentity(WidgetRef ref) {
  final uid = ref.read(currentUserIdProvider);
  final user = ref.read(currentAppUserStreamProvider).valueOrNull;
  return uid != null && user?.uid == uid && user?.hasCwitterId == true;
}
