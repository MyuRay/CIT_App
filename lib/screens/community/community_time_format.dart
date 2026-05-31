/// 交流機能向けの相対時刻表示
String formatCommunityRelativeTime(DateTime date) {
  final difference = DateTime.now().difference(date);

  if (difference.inMinutes < 1) {
    return 'たった今';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}分前';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours}時間前';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays}日前';
  }
  return '${date.month}/${date.day}';
}
