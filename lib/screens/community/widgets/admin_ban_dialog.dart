import 'package:flutter/material.dart';

import '../../../models/community/user_ban.dart';
import '../../../services/community/user_ban_service.dart';

/// 運営（管理者）がユーザーをBANするためのダイアログ。
///
/// 理由とBAN期間（日/月/永久）を選択して実行する。
/// BANに成功した場合は true を返す。
Future<bool> showAdminBanDialog(
  BuildContext context, {
  required String targetUserId,
  required String targetLabel,
  required String adminId,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => _AdminBanDialog(
      targetUserId: targetUserId,
      targetLabel: targetLabel,
      adminId: adminId,
    ),
  );
  return result ?? false;
}

/// BAN中ユーザーに表示する通知ダイアログ。
Future<void> showBanNoticeDialog(BuildContext context, UserBan ban) {
  final exception = UserBannedException(ban);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.block, color: Colors.red, size: 36),
      title: const Text('投稿できません'),
      content: Text(exception.message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// 例外が [UserBannedException] のときだけBAN通知を表示する。
///
/// 表示した場合は true を返す（呼び出し側で SnackBar 等を抑制するため）。
bool maybeShowBanNotice(BuildContext context, Object error) {
  if (error is! UserBannedException) return false;
  showBanNoticeDialog(context, error.ban);
  return true;
}

class _AdminBanDialog extends StatefulWidget {
  const _AdminBanDialog({
    required this.targetUserId,
    required this.targetLabel,
    required this.adminId,
  });

  final String targetUserId;
  final String targetLabel;
  final String adminId;

  @override
  State<_AdminBanDialog> createState() => _AdminBanDialogState();
}

class _AdminBanDialogState extends State<_AdminBanDialog> {
  BanReason _reason = BanReason.spam;
  BanDuration _duration = BanDuration.day;
  bool _isSubmitting = false;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      await UserBanService.banUser(
        targetUserId: widget.targetUserId,
        reason: _reason,
        duration: _duration,
        adminId: widget.adminId,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.targetLabel} を${_duration.label}しました'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('BANに失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: const Icon(Icons.gavel, color: Colors.red, size: 32),
      title: const Text('アカウントをBAN'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '対象: ${widget.targetLabel}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'BANの理由',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<BanReason>(
              value: _reason,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              items: [
                for (final reason in BanReason.values)
                  DropdownMenuItem(
                    value: reason,
                    child: Text(
                      reason.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      if (value != null) setState(() => _reason = value);
                    },
            ),
            const SizedBox(height: 16),
            Text(
              'BAN期間',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            for (final duration in BanDuration.values)
              RadioListTile<BanDuration>(
                value: duration,
                groupValue: _duration,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(duration.label),
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        if (value != null) setState(() => _duration = value);
                      },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('BANする'),
        ),
      ],
    );
  }
}
