import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/cwitter_provider.dart';
import '../../../core/providers/cwitter_reply_count_override_provider.dart';
import '../../../core/providers/admin_provider.dart';
import '../../../core/providers/schedule_provider.dart';
import '../../../models/community/cwitter_post.dart';
import '../../../models/community/cwitter_reply.dart';
import '../../../services/community/cwitter_post_image_service.dart';
import '../../../services/community/cwitter_service.dart';
import '../../../utils/community/post_image_utils.dart';
import '../community_time_format.dart';
import 'cwitter_author_header.dart';
import 'cwitter_avatar.dart';
import 'cwitter_body_text.dart';
import 'cwitter_post_images_grid.dart';
import 'admin_ban_dialog.dart';
import 'cwitter_more_menu.dart';
import 'cwitter_reply_context.dart';
import 'cwitter_report_helper.dart';
import 'cwitter_posting_guidelines_dialog.dart';
import '../../../screens/user_block/block_confirmation_dialog.dart';

/// 投稿への返信ボトムシート
class CwitterReplySheet extends ConsumerStatefulWidget {
  const CwitterReplySheet({super.key, required this.post});

  final CwitterPost post;

  static Future<void> show(BuildContext context, CwitterPost post) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: CwitterReplySheet(post: post),
      ),
    );
  }

  @override
  ConsumerState<CwitterReplySheet> createState() => _CwitterReplySheetState();
}

class _CwitterReplySheetState extends ConsumerState<CwitterReplySheet> {
  final _replyController = TextEditingController();
  final _replyFocusNode = FocusNode();
  final _pendingImages = <XFile>[];
  bool _isSending = false;
  CwitterReply? _replyTo;

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  void _startReplyTo(CwitterReply reply) {
    setState(() => _replyTo = reply);
    _replyFocusNode.requestFocus();
  }

  void _cancelReplyTo() {
    setState(() => _replyTo = null);
  }

  Future<void> _pickImages() async {
    if (_pendingImages.length >= CwitterPostImageService.maxImagesPerPost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '画像は最大${CwitterPostImageService.maxImagesPerPost}枚までです',
          ),
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final remaining =
        CwitterPostImageService.maxImagesPerPost - _pendingImages.length;
    final picked = await picker.pickMultipleMedia(limit: remaining);
    if (!mounted || picked.isEmpty) return;

    final images = picked.where(isSupportedPostImageXFile).toList();
    if (images.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('画像ファイルを選択してください')),
      );
      return;
    }

    setState(() {
      _pendingImages.addAll(images.take(remaining));
    });
  }

  Future<void> _submitReply() async {
    var text = _replyController.text.trim();
    if (text.isEmpty && _pendingImages.isEmpty) return;

    if (_replyTo != null) {
      final mention = '@${_replyTo!.cwitterId}';
      if (!text.startsWith(mention)) {
        text = '$mention $text';
      }
    }

    final appUser = ref.read(currentAppUserStreamProvider).valueOrNull;
    final uid = ref.read(currentUserIdProvider);
    if (appUser == null || uid == null || !appUser.hasCwitterId) return;

    final confirmed = await CwitterPostingGuidelinesDialog.confirmIfNeeded(
      context,
      ref,
    );
    if (!confirmed || !mounted) return;

    final replyCountNotifier =
        ref.read(cwitterReplyCountOverrideProvider.notifier);
    final nextReplyCount = _resolveReplyCount(ref) + 1;
    replyCountNotifier.apply(
      postId: widget.post.id,
      replyCount: nextReplyCount,
    );

    setState(() => _isSending = true);
    try {
      await CwitterService.createReply(
        postId: widget.post.id,
        authorId: uid,
        authorEmail: appUser.email,
        cwitterId: appUser.cwitterId!,
        displayName: appUser.displayName,
        body: text,
        profileImageUrl: appUser.profileImageUrl,
        inReplyToReplyId: _replyTo?.id,
        imageFiles: List<XFile>.from(_pendingImages),
      );
      if (!mounted) return;
      _replyController.clear();
      setState(() {
        _replyTo = null;
        _pendingImages.clear();
      });
      FocusScope.of(context).unfocus();
    } catch (e) {
      replyCountNotifier.revert(widget.post.id);
      if (!mounted) return;
      if (maybeShowBanNotice(context, e)) return;
      final isRateLimited = e is CwitterReplyRateLimitException;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isRateLimited ? '$e' : '返信に失敗しました: $e'),
          backgroundColor: isRateLimited ? Colors.orange.shade800 : null,
          duration: Duration(seconds: isRateLimited ? 3 : 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  int _resolveReplyCount(WidgetRef ref) {
    final override = ref.read(cwitterReplyCountOverrideProvider)[widget.post.id];
    final streamCount =
        ref.read(cwitterPostReplyCountProvider(widget.post.id)).valueOrNull;
    return resolveCwitterReplyCount(
      post: widget.post,
      override: override,
      streamCount: streamCount,
    );
  }

  Future<void> _deleteReply(String replyId, String userId) async {
    final replyCountNotifier =
        ref.read(cwitterReplyCountOverrideProvider.notifier);
    final nextReplyCount = _resolveReplyCount(ref) - 1;
    replyCountNotifier.apply(
      postId: widget.post.id,
      replyCount: nextReplyCount,
    );

    try {
      await CwitterService.deleteReply(
        postId: widget.post.id,
        replyId: replyId,
        userId: userId,
      );
    } catch (e) {
      replyCountNotifier.revert(widget.post.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('返信の削除に失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mutedColor = colorScheme.onSurface.withValues(alpha: 0.65);
    final appUser = ref.watch(currentAppUserStreamProvider).valueOrNull;
    final uid = ref.watch(currentUserIdProvider);
    final repliesAsync = ref.watch(filteredCwitterRepliesProvider(widget.post.id));
    final isPostOwner = uid != null && uid == widget.post.authorId;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Text(
                    '返信',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
              child: _PostPreviewHeader(
                post: widget.post,
                mutedColor: mutedColor,
                isOwner: isPostOwner,
                onDeletePost: isPostOwner
                    ? () async {
                        await CwitterService.deletePost(
                          postId: widget.post.id,
                          userId: uid,
                        );
                        ref
                            .read(cwitterFeedProvider.notifier)
                            .removePost(widget.post.id);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      }
                    : null,
                onBlock: isPostOwner
                    ? null
                    : () => showBlockConfirmationDialog(
                          context,
                          blockedUserId: widget.post.authorId,
                          blockedUserName: widget.post.displayName,
                          blockedUserCwitterId: widget.post.cwitterId,
                        ),
              ),
            ),
            const Divider(height: 20),
            Expanded(
              child: repliesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('読み込み失敗: $e')),
                data: (replies) {
                  if (replies.isEmpty) {
                    return Center(
                      child: Text(
                        'まだ返信がありません',
                        style: TextStyle(color: mutedColor),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                    itemCount: replies.length,
                    itemBuilder: (context, index) {
                      final reply = replies[index];
                      final isReplyOwner =
                          uid != null && uid == reply.authorId;
                      return _ReplyListTile(
                        post: widget.post,
                        reply: reply,
                        allReplies: replies,
                        mutedColor: mutedColor,
                        isOwner: isReplyOwner,
                        onReply: () => _startReplyTo(reply),
                        onDelete: isReplyOwner
                            ? () => _deleteReply(reply.id, uid)
                            : null,
                        onBlock: isReplyOwner
                            ? null
                            : () => showBlockConfirmationDialog(
                                  context,
                                  blockedUserId: reply.authorId,
                                  blockedUserName: reply.displayName,
                                  blockedUserCwitterId: reply.cwitterId,
                                ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyTo != null) ...[
                    CwitterReplyContextPreview(
                      authorId: _replyTo!.authorId,
                      authorName: _replyTo!.displayName,
                      cwitterId: _replyTo!.cwitterId,
                      body: _replyTo!.body,
                      onTap: _cancelReplyTo,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_pendingImages.isNotEmpty) ...[
                    CwitterPostImagesGrid(
                      imageUrls: const [],
                      localXFiles: _pendingImages,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isSending
                            ? null
                            : () => setState(_pendingImages.clear),
                        child: const Text('画像をすべて削除'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (appUser != null)
                        CwitterAvatar(
                          authorId: appUser.uid,
                          displayName: appUser.displayName,
                          cwitterId: appUser.cwitterId,
                          profileImageUrl: appUser.profileImageUrl,
                          radius: 18,
                        ),
                      const SizedBox(width: 10),
                      IconButton(
                        tooltip: '画像を追加（最大4枚）',
                        onPressed: _isSending ? null : _pickImages,
                        icon: Icon(
                          Icons.image_outlined,
                          color: _pendingImages.length >=
                                  CwitterPostImageService.maxImagesPerPost
                              ? colorScheme.onSurface.withValues(alpha: 0.35)
                              : const Color(0xFF2E7D32),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          focusNode: _replyFocusNode,
                          enableInteractiveSelection: true,
                          maxLines: 4,
                          minLines: 1,
                          maxLength: 280,
                          enabled: !_isSending,
                          decoration: InputDecoration(
                            hintText: _replyTo != null
                                ? '@${_replyTo!.cwitterId} への返信…'
                                : '返信を入力…',
                            isDense: true,
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _isSending ? null : _submitReply,
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                        ),
                        icon: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 元投稿プレビュー（⋮は行の右端に固定）
class _PostPreviewHeader extends ConsumerWidget {
  const _PostPreviewHeader({
    required this.post,
    required this.mutedColor,
    required this.isOwner,
    this.onDeletePost,
    this.onBlock,
  });

  final CwitterPost post;
  final Color mutedColor;
  final bool isOwner;
  final Future<void> Function()? onDeletePost;
  final VoidCallback? onBlock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserIdProvider);
    final isAdmin = ref.watch(isAdminProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CwitterAuthorHeader.fromPost(
          post,
          avatarRadius: 18,
          trailing: CwitterMoreMenu(
            isOwner: isOwner,
            onDeletePost: onDeletePost,
            onReport: isOwner
                ? null
                : () => showCwitterPostReportDialog(context, post: post),
            onBlock: onBlock,
            onBan: (!isAdmin || isOwner || uid == null)
                ? null
                : () => showAdminBanDialog(
                      context,
                      targetUserId: post.authorId,
                      targetLabel: '@${post.cwitterId}',
                      adminId: uid,
                    ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.body.isNotEmpty) ...[
                const SizedBox(height: 6),
                CwitterBodyText(text: post.body),
              ],
              if (post.hasImages) ...[
                const SizedBox(height: 8),
                CwitterPostImagesGrid(
                  imageUrls: post.imageUrls,
                  heroTagPrefix: 'cwitterReplyPreview_${post.id}',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 返信1件（⋮はアバター列の右端、日時は名前の下）
class _ReplyListTile extends ConsumerWidget {
  const _ReplyListTile({
    required this.post,
    required this.reply,
    required this.allReplies,
    required this.mutedColor,
    required this.isOwner,
    required this.onReply,
    this.onDelete,
    this.onBlock,
  });

  final CwitterPost post;
  final CwitterReply reply;
  final List<CwitterReply> allReplies;
  final Color mutedColor;
  final bool isOwner;
  final VoidCallback onReply;
  final Future<void> Function()? onDelete;
  final VoidCallback? onBlock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uid = ref.watch(currentUserIdProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final targetReply = resolveReplyTarget(
      reply: reply,
      post: post,
      replies: allReplies,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CwitterAuthorHeader(
            authorId: reply.authorId,
            displayName: reply.displayName,
            cwitterId: reply.cwitterId,
            profileImageUrl: reply.profileImageUrl,
            avatarRadius: 16,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatCommunityRelativeTime(reply.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: mutedColor,
                    fontSize: 11,
                  ),
                ),
                CwitterMoreMenu(
                  isOwner: isOwner,
                  onDeleteReply: onDelete,
                  onReport: isOwner
                      ? null
                      : () => showCwitterReplyReportDialog(
                            context,
                            post: post,
                            reply: reply,
                          ),
                  onBlock: onBlock,
                  onBan: (!isAdmin || isOwner || uid == null)
                      ? null
                      : () => showAdminBanDialog(
                            context,
                            targetUserId: reply.authorId,
                            targetLabel: '@${reply.cwitterId}',
                            adminId: uid,
                          ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (targetReply != null) ...[
                  CwitterReplyContextPreview(
                    authorId: targetReply.authorId,
                    authorName: targetReply.displayName,
                    cwitterId: targetReply.cwitterId,
                    body: targetReply.body,
                  ),
                  const SizedBox(height: 8),
                ],
                if (reply.body.isNotEmpty)
                  CwitterBodyText(text: reply.body),
                if (reply.hasImages) ...[
                  SizedBox(height: reply.body.isNotEmpty ? 8 : 0),
                  CwitterPostImagesGrid(
                    imageUrls: reply.imageUrls,
                    heroTagPrefix: 'cwitterReply_${reply.id}',
                  ),
                ],
                const SizedBox(height: 2),
                _ReplyActionButton(
                  mutedColor: mutedColor,
                  onTap: onReply,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyActionButton extends StatelessWidget {
  const _ReplyActionButton({
    required this.mutedColor,
    required this.onTap,
  });

  final Color mutedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 15,
                color: mutedColor,
              ),
              const SizedBox(width: 4),
              Text(
                '返信',
                style: TextStyle(
                  fontSize: 12,
                  color: mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
