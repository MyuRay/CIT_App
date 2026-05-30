import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../models/community/chiba_channel_comment.dart';

/// レス本文。>>N をタップ可能にする
class ChibaChannelCommentBody extends StatefulWidget {
  const ChibaChannelCommentBody({
    super.key,
    required this.comment,
    required this.onAnchorTap,
  });

  final ChibaChannelComment comment;
  final ValueChanged<int> onAnchorTap;

  static final RegExp _anchorPattern = RegExp(r'>>(\d+)');

  @override
  State<ChibaChannelCommentBody> createState() =>
      _ChibaChannelCommentBodyState();
}

class _ChibaChannelCommentBodyState extends State<ChibaChannelCommentBody> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.comment.isDeleted) {
      return Text(
        '[${ChibaChannelComment.deletedMessage}]',
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.45,
          color: colorScheme.onSurface.withValues(alpha: 0.45),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    if (widget.comment.body.isEmpty) {
      return const SizedBox.shrink();
    }

    _recognizers.clear();
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(height: 1.45);
    final anchorStyle = bodyStyle?.copyWith(
      color: const Color(0xFF1565C0),
      fontWeight: FontWeight.w600,
    );

    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in ChibaChannelCommentBody._anchorPattern
        .allMatches(widget.comment.body)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: widget.comment.body.substring(start, match.start),
          style: bodyStyle,
        ));
      }

      final anchorNumber = int.parse(match.group(1)!);
      final recognizer = TapGestureRecognizer()
        ..onTap = () => widget.onAnchorTap(anchorNumber);
      _recognizers.add(recognizer);

      spans.add(TextSpan(
        text: match.group(0),
        style: anchorStyle,
        recognizer: recognizer,
      ));
      start = match.end;
    }

    if (start < widget.comment.body.length) {
      spans.add(TextSpan(
        text: widget.comment.body.substring(start),
        style: bodyStyle,
      ));
    }

    return Text.rich(TextSpan(children: spans));
  }
}

/// タップ可能な >>N ラベル（inReplyTo 表示用）
class ChibaChannelReplyAnchorLink extends StatelessWidget {
  const ChibaChannelReplyAnchorLink({
    super.key,
    required this.commentNumber,
    required this.onTap,
  });

  final int commentNumber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        child: Text(
          '>>$commentNumber',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF1565C0),
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
