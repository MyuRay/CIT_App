import 'package:flutter/material.dart';

import '../../../models/community/cwitter_post.dart';
import '../../../services/reports/report_service.dart';
import '../../../services/user/user_service.dart';
import '../../../models/community/cwitter_reply.dart';
import '../../../models/reports/report_model.dart';
import '../../reports/report_form_dialog.dart';

Future<void> showCwitterPostReportDialog(
  BuildContext context, {
  required CwitterPost post,
}) async {
  if (await ReportService.hasAlreadyReported(
    targetId: post.id,
    type: ReportType.cwitterPost,
  )) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('このCweetはすでに通報済みです')),
    );
    return;
  }

  final targetEmail = await _resolveAuthorEmail(post.authorId, post.authorEmail);
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
    type: ReportType.cwitterPost,
    targetId: post.id,
    targetTitle: '${post.userHandle} のCweet',
    moderation: ReportModerationSnapshot(
      targetContent: post.body,
      targetAuthorId: post.authorId,
      targetAuthorName: post.displayName,
      targetAuthorEmail: targetEmail,
      targetAuthorCwitterId: post.cwitterId,
      targetPostId: post.id,
      source: 'cwitter',
    ),
  );
}

Future<void> showCwitterReplyReportDialog(
  BuildContext context, {
  required CwitterPost post,
  required CwitterReply reply,
}) async {
  if (await ReportService.hasAlreadyReported(
    targetId: reply.id,
    type: ReportType.cwitterReply,
  )) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('この返信はすでに通報済みです')),
    );
    return;
  }

  final targetEmail =
      await _resolveAuthorEmail(reply.authorId, reply.authorEmail);
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
    type: ReportType.cwitterReply,
    targetId: reply.id,
    targetTitle: '${reply.userHandle} の返信',
    moderation: ReportModerationSnapshot(
      targetContent: reply.body,
      targetAuthorId: reply.authorId,
      targetAuthorName: reply.displayName,
      targetAuthorEmail: targetEmail,
      targetAuthorCwitterId: reply.cwitterId,
      targetPostId: post.id,
      source: 'cwitter',
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

Future<void> showCwitterUserReportDialog(
  BuildContext context, {
  required String authorId,
  required String displayName,
  required String cwitterId,
}) async {
  if (await ReportService.hasAlreadyReported(
    targetId: authorId,
    type: ReportType.user,
  )) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('このユーザーはすでに通報済みです')),
    );
    return;
  }

  final targetEmail = await _resolveAuthorEmail(authorId, null);
  if (targetEmail.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ユーザーのメール情報を取得できず通報できませんでした')),
    );
    return;
  }

  if (!context.mounted) return;
  await showReportDialog(
    context,
    type: ReportType.user,
    targetId: authorId,
    targetTitle: '@$cwitterId（$displayName）',
    moderation: ReportModerationSnapshot(
      targetAuthorId: authorId,
      targetAuthorName: displayName,
      targetAuthorEmail: targetEmail,
      targetAuthorCwitterId: cwitterId,
      source: 'cwitter',
    ),
  );
}
