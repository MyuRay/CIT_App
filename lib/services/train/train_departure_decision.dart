// 大学→最寄り駅向けの余裕判定（設計書 v1・純関数）

/// 5 / 2 / 0 分境界
enum TrainDecisionCategory {
  /// margin >= 5
  plenty,

  /// 2 <= margin <= 4
  slight,

  /// 0 <= margin <= 1
  tight,

  /// margin < 0
  recommendNext,

  /// 有効な次発時刻なし
  noData,
}

class TrainDepartureDecision {
  const TrainDepartureDecision({
    required this.category,
    required this.minutesUntilDepartureFromNow,
    required this.marginMinutes,
    this.minutesBetweenNextAndSecond,
    this.effectiveNextDeparture,
  });

  final TrainDecisionCategory category;

  /// 画面メイン「あと◯分」用（いまから次発まで）
  final int minutesUntilDepartureFromNow;

  /// nextDeparture - (now + walk) の丸め分（inMinutes）
  final int marginMinutes;

  /// 「逃すと次は◯分後」用。次発とその次の差分（分）
  final int? minutesBetweenNextAndSecond;

  final DateTime? effectiveNextDeparture;

  static TrainDepartureDecision noData() {
    return const TrainDepartureDecision(
      category: TrainDecisionCategory.noData,
      minutesUntilDepartureFromNow: 0,
      marginMinutes: 0,
      minutesBetweenNextAndSecond: null,
      effectiveNextDeparture: null,
    );
  }
}

/// [walkMinutesToStation] デフォルト 10 分（設計書どおり）
TrainDepartureDecision computeTrainDepartureDecision({
  required DateTime now,
  int walkMinutesToStation = 10,
  required DateTime? nextDepartureAt,
  required DateTime? secondDepartureAt,
}) {
  if (nextDepartureAt == null) {
    return TrainDepartureDecision.noData();
  }

  var next = nextDepartureAt;
  var second = secondDepartureAt;

  while (next.isBefore(now) || next.isAtSameMomentAs(now)) {
    if (second == null) {
      return TrainDepartureDecision.noData();
    }
    next = second;
    second = null;
  }

  final arrivalAtStation = now.add(Duration(minutes: walkMinutesToStation));
  final marginMinutes = next.difference(arrivalAtStation).inMinutes;

  final category = _categoryFromMargin(marginMinutes);

  final minutesUntilDepartureFromNow =
      next.difference(now).inMinutes < 0 ? 0 : next.difference(now).inMinutes;

  int? gap;
  if (second != null && second.isAfter(next)) {
    gap = second.difference(next).inMinutes;
  }

  return TrainDepartureDecision(
    category: category,
    minutesUntilDepartureFromNow: minutesUntilDepartureFromNow,
    marginMinutes: marginMinutes,
    minutesBetweenNextAndSecond: gap,
    effectiveNextDeparture: next,
  );
}

TrainDecisionCategory _categoryFromMargin(int marginMinutes) {
  if (marginMinutes >= 5) return TrainDecisionCategory.plenty;
  if (marginMinutes >= 2) return TrainDecisionCategory.slight;
  if (marginMinutes >= 0) return TrainDecisionCategory.tight;
  return TrainDecisionCategory.recommendNext;
}

String trainDecisionCategoryLabelJa(TrainDecisionCategory c) {
  switch (c) {
    case TrainDecisionCategory.plenty:
      return '余裕あり';
    case TrainDecisionCategory.slight:
      return 'やや余裕あり';
    case TrainDecisionCategory.tight:
      return 'ぎりぎり';
    case TrainDecisionCategory.recommendNext:
      return '次便推奨';
    case TrainDecisionCategory.noData:
      return '判定できません';
  }
}
