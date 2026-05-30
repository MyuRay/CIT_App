import '../../models/community/chiba_channel_comment.dart';

/// 返信アンカー（>>N）からたどれるレスの連鎖を組み立てる
class ChibaChannelReplyChain {
  ChibaChannelReplyChain._();

  /// 指定レスから親を辿り、古い順（根→葉）で返す
  static List<ChibaChannelComment> buildChainToComment(
    ChibaChannelComment comment,
    List<ChibaChannelComment> allComments,
  ) {
    final byNumber = {
      for (final item in allComments) item.commentNumber: item,
    };
    final reversed = <ChibaChannelComment>[comment];
    var current = comment;

    while (current.inReplyToCommentNumber != null) {
      final parent = byNumber[current.inReplyToCommentNumber!];
      if (parent == null) break;
      if (reversed.any((item) => item.id == parent.id)) break;
      reversed.add(parent);
      current = parent;
    }

    return reversed.reversed.toList();
  }

  /// >>N タップ時: 文脈レスから辿れる連鎖、またはアンカー先の連鎖
  static List<ChibaChannelComment> resolveChainForAnchor({
    required ChibaChannelComment fromComment,
    required int anchorNumber,
    required List<ChibaChannelComment> allComments,
  }) {
    final chainToFrom = buildChainToComment(fromComment, allComments);
    if (chainToFrom.any((item) => item.commentNumber == anchorNumber)) {
      return chainToFrom;
    }

    final byNumber = {
      for (final item in allComments) item.commentNumber: item,
    };
    final anchor = byNumber[anchorNumber];
    if (anchor == null) return chainToFrom;
    return buildChainToComment(anchor, allComments);
  }
}
