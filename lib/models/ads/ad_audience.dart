const adGrades = ['1', '2', '3', '4', '5_plus', 'unknown'];
String adGradeLabel(String grade) => switch (grade) {
  '1' || '2' || '3' || '4' => '$grade年生',
  '5_plus' => '5年目以上',
  _ => '判定不可',
};

/// Years since admission; the academic year changes on April 1 in Japan.
String adGradeFromEmail(String? email, DateTime now) {
  final parts = email?.trim().toLowerCase().split('@');
  if (parts == null ||
      parts.length != 2 ||
      !['s.chibakoudai.jp', 'chibatech.ac.jp'].contains(parts[1])) {
    return 'unknown';
  }
  final match = RegExp(
    r'^(?:s)?(\d{2})(?:\d{5}|[a-z]\d{3,6})$',
  ).firstMatch(parts[0]);
  if (match == null) return 'unknown';
  final japan = now.toUtc().add(const Duration(hours: 9));
  final year = japan.year - (japan.month < 4 ? 1 : 0);
  final grade = year - (2000 + int.parse(match[1]!)) + 1;
  if (grade < 1 || grade > 12) return 'unknown';
  return grade >= 5 ? '5_plus' : '$grade';
}
