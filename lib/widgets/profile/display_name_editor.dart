import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_provider.dart';

/// マイページと Cwitter で共通の表示名を編集する。
Future<void> showDisplayNameEditor(
  BuildContext context,
  WidgetRef ref, {
  required String currentDisplayName,
}) async {
  final user = ref.read(firebaseAuthProvider).currentUser;
  if (user == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ログインが必要です')));
    return;
  }

  final saved = await showDialog<bool>(
    context: context,
    builder:
        (_) => _DisplayNameEditor(
          uid: user.uid,
          initialName: currentDisplayName.trim(),
        ),
  );
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('表示名を更新しました')));
  }
}

class _DisplayNameEditor extends ConsumerStatefulWidget {
  const _DisplayNameEditor({required this.uid, required this.initialName});

  final String uid;
  final String initialName;

  @override
  ConsumerState<_DisplayNameEditor> createState() => _DisplayNameEditorState();
}

class _DisplayNameEditorState extends ConsumerState<_DisplayNameEditor> {
  late final _controller = TextEditingController(text: widget.initialName);
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _formKey.currentState?.validate() != true) return;
    if (ref.read(firebaseAuthProvider).currentUser?.uid != widget.uid) {
      setState(() => _error = 'ログイン状態が変わりました。画面を閉じてやり直してください。');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(authServiceProvider)
          .updateDisplayName(_controller.text.trim());
      if (!mounted) return;
      // 両画面と投稿者名は同じ users の変更をリアルタイムで受信する。
      // 認証ストリームを再起動せず、取得済みのプロフィールだけ更新する。
      ref.invalidate(currentUserProvider);
      ref.invalidate(userProvider(widget.uid));
      ref.invalidate(currentUserDisplayNameProvider);
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '表示名を更新できませんでした。もう一度お試しください。';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: const Text('表示名を編集'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _controller,
                  autofocus: true,
                  enabled: !_saving,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                  decoration: const InputDecoration(labelText: '表示名'),
                  validator:
                      (value) =>
                          (value ?? '').trim().isEmpty ? '表示名を入力してください' : null,
                ),
                const SizedBox(height: 12),
                const Text('マイページ、Cwitter、掲示板コメント欄、学食レビューなどで表示されます。'),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child:
                _saving
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('保存'),
          ),
        ],
      ),
    );
  }
}
