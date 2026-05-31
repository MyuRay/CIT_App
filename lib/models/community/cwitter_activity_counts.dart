/// Cwitter プロフィールの Cweet 数（返信・recweet 含む）
class CwitterActivityCounts {
  const CwitterActivityCounts({
    this.postCount = 0,
    this.replyCount = 0,
    this.recweetCount = 0,
  });

  final int postCount;
  final int replyCount;
  final int recweetCount;

  int get totalCount => postCount + replyCount + recweetCount;
}
