import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/users/blocked_user_model.dart';
import '../../core/providers/user_block_provider.dart';

class BlockConfirmationDialog extends ConsumerStatefulWidget {
  final String blockedUserId;
  final String blockedUserName;

  const BlockConfirmationDialog({
    super.key,
    required this.blockedUserId,
    required this.blockedUserName,
  });

  @override
  ConsumerState<BlockConfirmationDialog> createState() =>
      _BlockConfirmationDialogState();
}

class _BlockConfirmationDialogState
    extends ConsumerState<BlockConfirmationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  BlockReason? _selectedReason;
  bool _confirmed = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _blockUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedReason == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ブロック理由を選択してください')));
      return;
    }

    if (!_confirmed) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('確認事項にチェックを入れてください')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(userBlockProvider.notifier)
          .blockUser(
            blockedUserId: widget.blockedUserId,
            blockedUserName: widget.blockedUserName,
            reason: _selectedReason!,
            notes:
                _notesController.text.isNotEmpty ? _notesController.text : null,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.blockedUserName}をブロックしました'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ブロックに失敗しました: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: AlertDialog(
        backgroundColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: mediaQuery.size.height * 0.8,
            maxWidth: 500,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.block, color: Colors.red, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ユーザーをブロック',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.blockedUserName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.red[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'ブロックすると以下の効果があります',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• このユーザーの投稿やコメントが非表示になります\n'
                            '• あなたがブロックしたことは相手に通知されません\n'
                            '• いつでもブロックを解除できます',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'ブロック理由 *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...BlockReason.values.map((reason) {
                      return RadioListTile<BlockReason>(
                        title: Text(reason.displayName),
                        value: reason,
                        groupValue: _selectedReason,
                        onChanged:
                            _isLoading
                                ? null
                                : (value) {
                                  setState(() {
                                    _selectedReason = value;
                                  });
                                },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      maxLength: 500,
                      enabled: !_isLoading,
                      decoration: const InputDecoration(
                        labelText: 'メモ（任意）',
                        border: OutlineInputBorder(),
                        hintText: '備考があれば記入してください（500文字以内）',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value != null && value.length > 500) {
                          return 'メモは500文字以内で入力してください';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text(
                        '上記の内容を理解しました',
                        style: TextStyle(fontSize: 14),
                      ),
                      value: _confirmed,
                      onChanged:
                          _isLoading
                              ? null
                              : (value) {
                                setState(() {
                                  _confirmed = value ?? false;
                                });
                              },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _blockUser,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Text('ブロックする'),
          ),
        ],
      ),
    );
  }
}

/// ブロック確認ダイアログを表示する関数
Future<bool?> showBlockConfirmationDialog(
  BuildContext context, {
  required String blockedUserId,
  required String blockedUserName,
}) {
  print('📱 showBlockConfirmationDialog: context mounted = ${context.mounted}');
  print('📱 blockedUserName = $blockedUserName, userId = $blockedUserId');

  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      print('📱 ブロックダイアログbuilder実行中');
      return BlockConfirmationDialog(
        blockedUserId: blockedUserId,
        blockedUserName: blockedUserName,
      );
    },
  );
}
