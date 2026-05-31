/// 登録済み Cwitter ハッシュタグの集計
class CwitterHashtagSummary {
  const CwitterHashtagSummary({
    required this.tag,
    required this.userCount,
  });

  final String tag;
  final int userCount;
}
