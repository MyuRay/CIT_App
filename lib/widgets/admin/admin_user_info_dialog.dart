import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/user_app_info_provider.dart';

Future<void> showAdminUserInfo(BuildContext context, String uid) =>
    showDialog<void>(
      context: context,
      builder: (_) => AdminUserInfoDialog(userId: uid),
    );

class AdminUserInfoDialog extends ConsumerWidget {
  const AdminUserInfoDialog({super.key, required this.userId});
  final String userId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(userAppInfoProvider(userId));
    return AlertDialog(
      title: const Text('ユーザー情報'),
      scrollable: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableText('UID: $userId'),
          const SizedBox(height: 12),
          StreamBuilder(
            stream:
                ref
                    .watch(userAppInfoFirestoreProvider)
                    .collection('users')
                    .doc(userId)
                    .snapshots(),
            builder: (context, snapshot) {
              final profile = snapshot.data?.data();
              return SelectableText(
                '表示名: ${profile?['displayName'] ?? '—'}\nメール: ${profile?['email'] ?? '—'}\nCweetID: ${profile?['cwitterId'] ?? '未設定'}',
              );
            },
          ),
          const Divider(height: 24),
          info.when(
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('アプリ・端末情報を取得できませんでした'),
            data:
                (data) =>
                    data == null
                        ? const Text('アプリ・端末情報はまだ届いていません。利用者が最新版を起動すると送信されます。')
                        : SelectableText(
                          [
                            'OS: ${data['os'] ?? '—'}',
                            'OSバージョン: ${data['osVersion'] ?? '—'}',
                            'アプリバージョン: ${data['appVersion'] ?? '—'}',
                            'ビルド番号: ${data['buildNumber'] ?? '—'}',
                            'アプリID: ${data['packageName'] ?? '—'}',
                            '実行環境: ${data['platform'] ?? '—'}',
                            '言語: ${data['locale'] ?? '—'}',
                          ].join('\n'),
                        ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}
