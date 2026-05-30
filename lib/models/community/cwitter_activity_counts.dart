/// Cwitter プロフィールの Cweet 数（recweet 含む）
class CwitterActivityCounts {
  const CwitterActivityCounts({
    this.postCount = 0,
    this.recweetCount = 0,
  });

  final int postCount;
  final int recweetCount;

  int get totalCount => postCount + recweetCount;
}
