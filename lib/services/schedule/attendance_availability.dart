/// 授業の出席可能時間（QR出席を受け付ける時間帯）の判定ロジックと定数を集約する。
///
/// 仕様:
/// - 開始: 授業開始 20 分前
/// - 終了: 授業開始から 60 分後
/// - 通知タップ時の「現在時刻」で判定する（payload に保存された startDateTime を基準に、
///   ユーザーが実際にタップした瞬間の時計で判定）
class AttendanceAvailability {
  AttendanceAvailability._();

  /// 出席受付の開始（授業開始から何分前に開放するか）。
  static const int beforeMinutes = 20;

  /// 出席受付の終了（授業開始から何分後まで受け付けるか）。
  static const int afterMinutes = 60;

  /// 出席受付の開始時刻を返す。
  static DateTime availableFrom(DateTime startDateTime) =>
      startDateTime.subtract(const Duration(minutes: beforeMinutes));

  /// 出席受付の終了時刻を返す。
  static DateTime availableUntil(DateTime startDateTime) =>
      startDateTime.add(const Duration(minutes: afterMinutes));

  /// `now` が授業 `startDateTime` の出席可能時間内かを判定。
  ///
  /// 判定範囲: `startDateTime - 20分 <= now <= startDateTime + 60分`
  /// 端点は両方とも inclusive。
  static bool isWithinWindow({
    required DateTime now,
    required DateTime startDateTime,
  }) {
    final from = availableFrom(startDateTime);
    final until = availableUntil(startDateTime);
    if (now.isBefore(from)) return false;
    if (now.isAfter(until)) return false;
    return true;
  }
}
