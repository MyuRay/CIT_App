import '../../models/schedule/lecture_period_model.dart';

/// ホームの表示は選択中の時間割の学期ではなく、大学の講義期間で判断する。
/// 設定が不明な場合はカードを表示し、時間割へのアクセスを残す。
bool isOutsideHomeTimetableLecturePeriod({
  required LecturePeriodSettings? settings,
  required DateTime date,
}) {
  if (settings == null) return false;

  bool hasValidRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return false;
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return !endDay.isBefore(startDay);
  }

  if (!hasValidRange(settings.springStartDate, settings.springEndDate) &&
      !hasValidRange(settings.fallStartDate, settings.fallEndDate)) {
    return false;
  }
  return !settings.containsDate(date);
}
