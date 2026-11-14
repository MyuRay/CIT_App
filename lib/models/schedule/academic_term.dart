/// 時間割の表示名と独立して保存する年度・学期。
class AcademicTerm {
  const AcademicTerm(this.year, this.isFall);
  final int year;
  final bool isFall;
  String get label => '${year}年度${isFall ? '後期' : '前期'}';
  String get key => '${year}_${isFall ? 'fall' : 'spring'}';
  static int currentYear([DateTime? date]) {
    final now = date ?? DateTime.now();
    return now.month < 4 ? now.year - 1 : now.year;
  }

  static AcademicTerm? parse(String value) {
    final year = RegExp(r'(\d{4})\s*年(?:度)?').firstMatch(value);
    if (year == null || !RegExp('前期|後期|春|秋').hasMatch(value)) return null;
    return AcademicTerm(
      int.parse(year.group(1)!),
      value.contains('後期') || value.contains('秋'),
    );
  }
}
