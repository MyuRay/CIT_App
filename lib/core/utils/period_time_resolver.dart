/// 千葉工業大学の時限制（1〜10限、各60分）を1か所に集約する解決クラス。
///
/// 既存の時間割データに開始/終了時刻が直接保存されていない場合でも、
/// 時限番号から具体的な時刻を計算する責務をここで一元化する。
///
/// 時限と時刻の対応:
/// - 1限: 09:00〜10:00
/// - 2限: 10:00〜11:00
/// - …
/// - 10限: 18:00〜19:00
class PeriodTimeResolver {
  PeriodTimeResolver._();

  /// 1日の最初の時限の開始時刻（時）。
  static const int firstPeriodStartHour = 9;

  /// 1コマあたりの長さ（分）。
  static const int periodDurationMinutes = 60;

  /// サポートする時限の最小値・最大値。
  static const int minPeriod = 1;
  static const int maxPeriod = 10;

  /// 与えられた period が 1〜10 の範囲に入っているか。
  static bool isValidPeriod(int period) {
    return period >= minPeriod && period <= maxPeriod;
  }

  /// `period` 限の開始時刻（時）。`HH:mm` の `HH` 部分。
  /// 無効な period の場合は null。
  static int? startHourForPeriod(int period) {
    if (!isValidPeriod(period)) return null;
    return firstPeriodStartHour + (period - 1);
  }

  /// `period` 限の終了時刻（時）。`HH:mm` の `HH` 部分。
  /// 無効な period の場合は null。
  static int? endHourForPeriod(int period) {
    final start = startHourForPeriod(period);
    if (start == null) return null;
    return start + 1;
  }

  /// 与えられた日付における `period` 限の開始日時を返す。
  /// 無効な period の場合は null。
  static DateTime? startDateTimeFor(DateTime date, int period) {
    final hour = startHourForPeriod(period);
    if (hour == null) return null;
    return DateTime(date.year, date.month, date.day, hour, 0);
  }

  /// 与えられた日付における `period` 限の終了日時を返す。
  /// 無効な period の場合は null。
  static DateTime? endDateTimeFor(DateTime date, int period) {
    final hour = endHourForPeriod(period);
    if (hour == null) return null;
    return DateTime(date.year, date.month, date.day, hour, 0);
  }

  /// `HH:mm` 表記の開始時刻文字列。無効な period の場合は null。
  static String? startTimeStringForPeriod(int period) {
    final hour = startHourForPeriod(period);
    if (hour == null) return null;
    return '${hour.toString().padLeft(2, '0')}:00';
  }

  /// `HH:mm` 表記の終了時刻文字列。無効な period の場合は null。
  static String? endTimeStringForPeriod(int period) {
    final hour = endHourForPeriod(period);
    if (hour == null) return null;
    return '${hour.toString().padLeft(2, '0')}:00';
  }
}
