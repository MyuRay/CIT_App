import 'package:flutter/material.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:image_picker/image_picker.dart';



import '../../../core/providers/chiba_channel_provider.dart';

import '../../../core/providers/cwitter_provider.dart';

import '../../../core/providers/schedule_provider.dart';

import '../../../models/community/chiba_channel_comment.dart';

import '../../../models/community/chiba_channel_thread.dart';

import '../../../services/community/chiba_channel_image_service.dart';

import '../../../services/community/chiba_channel_reply_sound_service.dart';
import '../../../services/community/chiba_channel_service.dart';

import '../community_time_format.dart';

import 'chiba_channel_comment_body.dart';
import 'chiba_channel_reply_chain_sheet.dart';
import 'chiba_channel_report_helper.dart';
import 'cwitter_post_images_grid.dart';



class ChibaChannelThreadScreen extends ConsumerStatefulWidget {

  const ChibaChannelThreadScreen({super.key, required this.thread});



  final ChibaChannelThread thread;



  @override

  ConsumerState<ChibaChannelThreadScreen> createState() =>

      _ChibaChannelThreadScreenState();

}



class _ChibaChannelThreadScreenState

    extends ConsumerState<ChibaChannelThreadScreen> {

  final _commentController = TextEditingController();

  final _commentFocusNode = FocusNode();

  final _scrollController = ScrollController();

  final _pendingImages = <XFile>[];

  bool _isSending = false;

  bool _showScrollToLatest = false;

  ChibaChannelComment? _replyTo;

  Set<String> _knownCommentIds = {};
  bool _commentsInitialized = false;



  @override

  void initState() {

    super.initState();

    ChibaChannelReplySoundService.ensureLoaded();

    _scrollController.addListener(_updateScrollToLatestVisibility);

  }



  @override

  void dispose() {

    _scrollController.removeListener(_updateScrollToLatestVisibility);

    _scrollController.dispose();

    _commentController.dispose();

    _commentFocusNode.dispose();

    super.dispose();

  }



  void _updateScrollToLatestVisibility() {

    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;

    final hasOverflow = position.maxScrollExtent > 48;

    final nearBottom = position.pixels >= position.maxScrollExtent - 80;

    final shouldShow = hasOverflow && !nearBottom;

    if (shouldShow != _showScrollToLatest) {

      setState(() => _showScrollToLatest = shouldShow);

    }

  }



  Future<void> _scrollToLatest() async {

    if (!_scrollController.hasClients) return;

    await _scrollController.animateTo(

      _scrollController.position.maxScrollExtent,

      duration: const Duration(milliseconds: 300),

      curve: Curves.easeOut,

    );

  }



  void _startReplyTo(ChibaChannelComment comment) {

    setState(() => _replyTo = comment);

    _commentFocusNode.requestFocus();

  }



  void _cancelReplyTo() {

    setState(() => _replyTo = null);

  }



  Future<void> _pickImages() async {

    if (_pendingImages.length >=

        ChibaChannelImageService.maxImagesPerComment) {

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text(

            '画像は最大${ChibaChannelImageService.maxImagesPerComment}枚までです',

          ),

        ),

      );

      return;

    }



    final picker = ImagePicker();

    final picked = await picker.pickMultiImage(

      imageQuality: 85,

      maxWidth: 2048,

      maxHeight: 2048,

    );

    if (!mounted || picked.isEmpty) return;



    setState(() {

      final remaining =

          ChibaChannelImageService.maxImagesPerComment - _pendingImages.length;

      _pendingImages.addAll(picked.take(remaining));

    });

  }



  void _removePendingImage(int index) {

    setState(() => _pendingImages.removeAt(index));

  }



  Future<void> _sendComment() async {

    if (_isSending) return;



    final text = _commentController.text.trim();

    if (text.isEmpty && _pendingImages.isEmpty) return;



    final uid = ref.read(currentUserIdProvider);

    final appUser = ref.read(currentAppUserStreamProvider).valueOrNull;

    if (uid == null || appUser == null) return;



    setState(() => _isSending = true);

    try {

      await ChibaChannelService.createComment(

        threadId: widget.thread.id,

        authorId: uid,

        authorEmail: appUser.email,

        body: text,

        inReplyToCommentNumber: _replyTo?.commentNumber,

        inReplyToCommentId: _replyTo?.id,

        imageFiles: List<XFile>.from(_pendingImages),

      );

      _commentController.clear();

      setState(() {

        _replyTo = null;

        _pendingImages.clear();

      });

      if (mounted) FocusScope.of(context).unfocus();

    } catch (error) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text(error.toString().replaceFirst('ArgumentError: ', '')),

        ),

      );

    } finally {

      if (mounted) setState(() => _isSending = false);

    }

  }



  Future<void> _reportComment(ChibaChannelComment comment) async {
    await showChibaChannelCommentReportDialog(
      context,
      comment: comment,
      thread: widget.thread,
    );
  }

  Future<void> _deleteComment(ChibaChannelComment comment) async {

    final uid = ref.read(currentUserIdProvider);

    if (uid == null || comment.authorId != uid) return;



    final confirmed = await showDialog<bool>(

      context: context,

      builder: (context) => AlertDialog(

        title: const Text('レスを削除'),

        content: const Text('このレスを削除しますか？'),

        actions: [

          TextButton(

            onPressed: () => Navigator.pop(context, false),

            child: const Text('キャンセル'),

          ),

          FilledButton(

            onPressed: () => Navigator.pop(context, true),

            child: const Text('削除'),

          ),

        ],

      ),

    );

    if (confirmed != true || !mounted) return;



    try {

      await ChibaChannelService.deleteComment(

        threadId: widget.thread.id,

        commentId: comment.id,

        authorId: uid,

      );

    } catch (error) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text(error.toString())),

      );

    }

  }



  Future<void> _deleteThread() async {

    final uid = ref.read(currentUserIdProvider);

    if (uid == null || widget.thread.authorId != uid) return;



    final confirmed = await showDialog<bool>(

      context: context,

      builder: (context) => AlertDialog(

        title: const Text('スレッドを削除'),

        content: const Text('このスレッドとすべてのレスを削除しますか？'),

        actions: [

          TextButton(

            onPressed: () => Navigator.pop(context, false),

            child: const Text('キャンセル'),

          ),

          FilledButton(

            onPressed: () => Navigator.pop(context, true),

            child: const Text('削除'),

          ),

        ],

      ),

    );

    if (confirmed != true || !mounted) return;



    try {

      await ChibaChannelService.deleteThread(

        threadId: widget.thread.id,

        authorId: uid,

      );

      if (!mounted) return;

      Navigator.of(context).pop();

    } catch (error) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text(error.toString())),

      );

    }

  }



  @override

  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    final uid = ref.watch(currentUserIdProvider);

    final commentsAsync =

        ref.watch(chibaChannelCommentsProvider(widget.thread.id));

    final isOwner = uid != null && uid == widget.thread.authorId;

    ref.listen(chibaChannelCommentsProvider(widget.thread.id), (previous, next) {
      next.whenData((comments) {
        final ids = comments.map((comment) => comment.id).toSet();
        if (!_commentsInitialized) {
          _commentsInitialized = true;
          _knownCommentIds = ids;
          return;
        }
        final hasNewComment =
            comments.any((comment) => !_knownCommentIds.contains(comment.id));
        if (hasNewComment) {
          ChibaChannelReplySoundService.playNewReplyPop();
        }
        _knownCommentIds = ids;
      });
    });



    return Scaffold(

      appBar: AppBar(

        title: Text(

          widget.thread.title,

          maxLines: 1,

          overflow: TextOverflow.ellipsis,

        ),

        actions: [

          if (isOwner)

            IconButton(

              icon: const Icon(Icons.delete_outline),

              tooltip: 'スレッドを削除',

              onPressed: _deleteThread,

            ),

        ],

      ),

      body: Column(

        children: [

          Expanded(

            child: commentsAsync.when(

              loading: () => const Center(child: CircularProgressIndicator()),

              error: (error, _) => Center(

                child: Text('読み込みに失敗しました: $error'),

              ),

              data: (comments) {

                WidgetsBinding.instance.addPostFrameCallback((_) {

                  if (mounted) _updateScrollToLatestVisibility();

                });



                return Stack(

                  children: [

                    ListView(

                      controller: _scrollController,

                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),

                      children: [

                        _ThreadHeader(thread: widget.thread),

                        const SizedBox(height: 12),

                        if (comments.isEmpty)

                          Padding(

                            padding: const EdgeInsets.symmetric(vertical: 32),

                            child: Center(

                              child: Text(

                                'まだレスがありません。最初のレスを書いてみましょう。',

                                style: theme.textTheme.bodyMedium?.copyWith(

                                  color:

                                      colorScheme.onSurface.withValues(alpha: 0.65),

                                ),

                              ),

                            ),

                          )

                        else

                          ...comments.map(

                            (comment) => _CommentTile(
                          comment: comment,
                          allComments: comments,
                          thread: widget.thread,
                          threadAuthorId: widget.thread.authorId,
                          canDelete:
                              uid == comment.authorId && !comment.isDeleted,
                          canReport: uid != null &&
                              uid != comment.authorId &&
                              !comment.isDeleted,
                          onReply: () => _startReplyTo(comment),
                          onDelete: () => _deleteComment(comment),
                          onReport: () => _reportComment(comment),
                        ),

                          ),

                      ],

                    ),

                    if (_showScrollToLatest)

                      Positioned(

                        right: 16,

                        bottom: 16,

                        child: _ScrollToLatestButton(

                          onPressed: _scrollToLatest,

                        ),

                      ),

                  ],

                );

              },

            ),

          ),

          SafeArea(

            top: false,

            child: Container(

              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),

              decoration: BoxDecoration(

                border: Border(

                  top: BorderSide(

                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),

                  ),

                ),

              ),

              child: Column(

                mainAxisSize: MainAxisSize.min,

                crossAxisAlignment: CrossAxisAlignment.stretch,

                children: [

                  if (_replyTo != null)

                    _ReplyContextBar(

                      comment: _replyTo!,

                      onCancel: _cancelReplyTo,

                    ),

                  if (_pendingImages.isNotEmpty) ...[

                    CwitterPostImagesGrid(

                      imageUrls: const [],

                      localXFiles: _pendingImages,

                      heroTagPrefix:

                          'chibaChannelPending_${widget.thread.id}',

                    ),

                    const SizedBox(height: 8),

                    Wrap(

                      spacing: 8,

                      children: [

                        for (var i = 0; i < _pendingImages.length; i++)

                          InputChip(

                            label: Text('画像${i + 1}'),

                            onDeleted: () => _removePendingImage(i),

                          ),

                      ],

                    ),

                    const SizedBox(height: 8),

                  ],

                  Row(

                    crossAxisAlignment: CrossAxisAlignment.end,

                    children: [

                      IconButton(

                        onPressed: _isSending || uid == null ? null : _pickImages,

                        icon: const Icon(Icons.image_outlined),

                        tooltip: '画像を追加',

                      ),

                      Expanded(

                        child: TextField(

                          controller: _commentController,

                          focusNode: _commentFocusNode,

                          enabled: !_isSending && uid != null,

                          maxLength: 1000,

                          maxLines: 4,

                          minLines: 1,

                          decoration: InputDecoration(

                            hintText: _replyTo == null

                                ? '匿名でレスする'

                                : '>>${_replyTo!.commentNumber} へ返信',

                            border: const OutlineInputBorder(),

                            counterText: '',

                          ),

                        ),

                      ),

                      const SizedBox(width: 4),

                      IconButton.filled(

                        onPressed:

                            _isSending || uid == null ? null : _sendComment,

                        icon: _isSending

                            ? const SizedBox(

                                width: 18,

                                height: 18,

                                child: CircularProgressIndicator(

                                  strokeWidth: 2,

                                ),

                              )

                            : const Icon(Icons.send),

                        style: IconButton.styleFrom(

                          backgroundColor: const Color(0xFF4CAF50),

                          foregroundColor: Colors.white,

                        ),

                      ),

                    ],

                  ),

                ],

              ),

            ),

          ),

        ],

      ),

    );

  }

}



class _ReplyContextBar extends StatelessWidget {

  const _ReplyContextBar({

    required this.comment,

    required this.onCancel,

  });



  final ChibaChannelComment comment;

  final VoidCallback onCancel;



  @override

  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;



    return Container(

      margin: const EdgeInsets.only(bottom: 8),

      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),

      decoration: BoxDecoration(

        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),

        borderRadius: BorderRadius.circular(8),

        border: Border.all(

          color: const Color(0xFF4CAF50).withValues(alpha: 0.35),

        ),

      ),

      child: Row(

        children: [

          Expanded(

            child: Text(

              '>>${comment.commentNumber} ${comment.displayName}[${comment.displayIdLabel}] へ返信',

              style: theme.textTheme.bodySmall?.copyWith(

                color: colorScheme.onSurface.withValues(alpha: 0.8),

              ),

              maxLines: 1,

              overflow: TextOverflow.ellipsis,

            ),

          ),

          IconButton(

            onPressed: onCancel,

            icon: const Icon(Icons.close, size: 18),

            tooltip: '返信をやめる',

          ),

        ],

      ),

    );

  }

}



class _ThreadHeader extends StatelessWidget {

  const _ThreadHeader({required this.thread});



  final ChibaChannelThread thread;



  @override

  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;



    return Card(

      elevation: 0,

      shape: RoundedRectangleBorder(

        borderRadius: BorderRadius.circular(12),

        side: BorderSide(

          color: colorScheme.outlineVariant.withValues(alpha: 0.5),

        ),

      ),

      child: Padding(

        padding: const EdgeInsets.all(14),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Row(

              children: [

                _CategoryTag(label: thread.category),

                if (thread.isHot) ...[

                  const SizedBox(width: 6),

                  Container(

                    padding: const EdgeInsets.symmetric(

                      horizontal: 6,

                      vertical: 2,

                    ),

                    decoration: BoxDecoration(

                      color: Colors.orange.withValues(alpha: 0.15),

                      borderRadius: BorderRadius.circular(6),

                    ),

                    child: const Text(

                      'HOT',

                      style: TextStyle(

                        fontSize: 10,

                        fontWeight: FontWeight.bold,

                        color: Colors.orange,

                      ),

                    ),

                  ),

                ],

              ],

            ),

            const SizedBox(height: 10),

            Text(

              thread.title,

              style: theme.textTheme.titleMedium?.copyWith(

                fontWeight: FontWeight.bold,

              ),

            ),

            const SizedBox(height: 6),

            Text(

              '${thread.commentCount}件のレス · ${thread.activityLabel} ${formatCommunityRelativeTime(thread.lastActivityAt)}',

              style: theme.textTheme.bodySmall?.copyWith(

                color: colorScheme.onSurface.withValues(alpha: 0.65),

              ),

            ),

          ],

        ),

      ),

    );

  }

}



class _CommentTile extends StatelessWidget {

  const _CommentTile({
    required this.comment,
    required this.allComments,
    required this.thread,
    required this.threadAuthorId,
    required this.canDelete,
    required this.canReport,
    required this.onReply,
    required this.onDelete,
    required this.onReport,
  });

  final ChibaChannelComment comment;
  final List<ChibaChannelComment> allComments;
  final ChibaChannelThread thread;
  final String threadAuthorId;
  final bool canDelete;
  final bool canReport;
  final VoidCallback onReply;
  final VoidCallback onDelete;
  final VoidCallback onReport;



  @override

  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    final isThreadOwner = threadAuthorId.isNotEmpty &&
        comment.authorId == threadAuthorId;

    void openAnchorChain(int anchorNumber) {
      ChibaChannelReplyChainSheet.show(
        context,
        allComments: allComments,
        fromComment: comment,
        anchorNumber: anchorNumber,
        threadAuthorId: threadAuthorId,
      );
    }

    return Card(

      margin: const EdgeInsets.only(bottom: 8),

      elevation: 0,

      shape: RoundedRectangleBorder(

        borderRadius: BorderRadius.circular(10),

        side: BorderSide(

          color: colorScheme.outlineVariant.withValues(alpha: 0.4),

        ),

      ),

      child: Padding(

        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),

        child: Row(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Container(

              width: 36,

              alignment: Alignment.center,

              child: Text(

                '${comment.commentNumber}',

                style: theme.textTheme.labelLarge?.copyWith(

                  fontWeight: FontWeight.bold,

                  color: const Color(0xFF2E7D32),

                ),

              ),

            ),

            Expanded(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Row(

                    children: [

                      Text(

                        comment.displayName,

                        style: theme.textTheme.labelMedium?.copyWith(

                          color: colorScheme.onSurface.withValues(alpha: 0.7),

                        ),

                      ),

                      const SizedBox(width: 6),

                      Text(
                        comment.displayIdLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isThreadOwner) ...[
                        const SizedBox(width: 6),
                        const _ThreadOwnerBadge(),
                      ],
                      const SizedBox(width: 8),

                      Text(

                        formatCommunityRelativeTime(comment.createdAt),

                        style: theme.textTheme.bodySmall?.copyWith(

                          color: colorScheme.onSurface.withValues(alpha: 0.55),

                        ),

                      ),

                    ],

                  ),

                  if (comment.inReplyToCommentNumber != null &&
                      !comment.isDeleted &&
                      !comment.body
                          .startsWith('>>${comment.inReplyToCommentNumber}')) ...[
                    const SizedBox(height: 4),
                    ChibaChannelReplyAnchorLink(
                      commentNumber: comment.inReplyToCommentNumber!,
                      onTap: () =>
                          openAnchorChain(comment.inReplyToCommentNumber!),
                    ),
                  ],
                  if (comment.isDeleted || comment.body.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ChibaChannelCommentBody(
                      comment: comment,
                      onAnchorTap: openAnchorChain,
                    ),
                  ],

                  if (comment.hasImages) ...[

                    const SizedBox(height: 8),

                    CwitterPostImagesGrid(

                      imageUrls: comment.imageUrls,

                      heroTagPrefix:

                          'chibaChannel_${comment.threadId}_${comment.id}',

                    ),

                  ],

                  const SizedBox(height: 4),

                  Align(

                    alignment: Alignment.centerLeft,

                    child: TextButton.icon(

                      onPressed: onReply,

                      icon: const Icon(Icons.reply, size: 16),

                      label: const Text('返信'),

                      style: TextButton.styleFrom(

                        visualDensity: VisualDensity.compact,

                        padding: const EdgeInsets.symmetric(horizontal: 8),

                      ),

                    ),

                  ),

                ],

              ),

            ),

            if (canDelete || canReport)
              _CommentMoreMenu(
                canDelete: canDelete,
                canReport: canReport,
                onDelete: onDelete,
                onReport: onReport,
              ),

          ],

        ),

      ),

    );

  }

}



class _ScrollToLatestButton extends StatelessWidget {

  const _ScrollToLatestButton({required this.onPressed});



  final VoidCallback onPressed;



  @override

  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;



    return Material(

      elevation: 4,

      shadowColor: Colors.black.withValues(alpha: 0.2),

      shape: const CircleBorder(),

      color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,

      child: InkWell(

        onTap: onPressed,

        customBorder: const CircleBorder(),

        child: SizedBox(

          width: 44,

          height: 44,

          child: Icon(

            Icons.keyboard_arrow_down,

            color: isDark ? const Color(0xFF9AE6A0) : const Color(0xFF2E7D32),

          ),

        ),

      ),

    );

  }

}



class _CommentMoreMenu extends StatelessWidget {
  const _CommentMoreMenu({
    required this.canDelete,
    required this.canReport,
    required this.onDelete,
    required this.onReport,
  });

  final bool canDelete;
  final bool canReport;
  final VoidCallback onDelete;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      splashRadius: 18,
      iconSize: 18,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: Icon(Icons.more_vert, size: 18, color: iconColor),
      onSelected: (value) {
        if (value == 'report') {
          onReport();
          return;
        }
        if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];
        if (canReport) {
          items.add(
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.flag_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('通報'),
                ],
              ),
            ),
          );
        }
        if (canDelete) {
          items.add(
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('削除', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          );
        }
        return items;
      },
    );
  }
}



class _ThreadOwnerBadge extends StatelessWidget {
  const _ThreadOwnerBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF1565C0).withValues(alpha: 0.35),
        ),
      ),
      child: const Text(
        'スレ主',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1565C0),
        ),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {

  const _CategoryTag({required this.label});



  final String label;



  @override

  Widget build(BuildContext context) {

    final colorScheme = Theme.of(context).colorScheme;

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),

      decoration: BoxDecoration(

        color: const Color(0xFF4CAF50).withValues(alpha: 0.12),

        borderRadius: BorderRadius.circular(8),

        border: Border.all(

          color: const Color(0xFF4CAF50).withValues(alpha: 0.4),

        ),

      ),

      child: Text(

        label,

        style: TextStyle(

          fontSize: 11,

          fontWeight: FontWeight.w600,

          color: colorScheme.brightness == Brightness.dark

              ? const Color(0xFF81C784)

              : const Color(0xFF2E7D32),

        ),

      ),

    );

  }

}

