import 'package:flutter/material.dart';

import '../../../models/community/chiba_channel_comment.dart';
import '../../../models/community/chiba_channel_thread.dart';
import '../../../models/reports/report_model.dart';
import '../../../services/reports/report_service.dart';
import '../../../services/user/user_service.dart';
import '../../reports/report_form_dialog.dart';

Future<void> showChibaChannelCommentReportDialog(
  BuildContext context, {
  required ChibaChannelComment comment,
  required ChibaChannelThread thread,
}) async {
  if (comment.isDeleted) return;

  if (await ReportService.hasAlreadyReported(
    targetId: comment.id,
    type: ReportType.chibaChannelComment,
  )) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('このレスはすでに通報済みです')),
    );
    return;
  }

  final targetEmail =
      await _resolveAuthorEmail(comment.authorId, comment.authorEmail);
  if (targetEmail.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('投稿者のメール情報を取得できず通報できませんでした')),
    );
    return;
  }

  if (!context.mounted) return;
  await showReportDialog(
    context,
    type: ReportType.chibaChannelComment,
    targetId: comment.id,
    targetTitle: '「${thread.title}」の #${comment.commentNumber} レス',
    moderation: ReportModerationSnapshot(
      targetContent: comment.body,
      targetAuthorId: comment.authorId,
      targetAuthorName: '${comment.displayName} ${comment.displayIdLabel}',
      targetAuthorEmail: targetEmail,
      targetPostId: thread.id,
      source: 'chiba_channel',
    ),
  );
}

Future<String> _resolveAuthorEmail(
  String authorId,
  String? storedEmail,
) async {
  final fromDoc = storedEmail?.trim().toLowerCase() ?? '';
  if (fromDoc.isNotEmpty) return fromDoc;

  final user = await UserService.getUser(authorId);
  return (user?.email ?? '').trim().toLowerCase();
}
