class TrainDecisionResult {
  const TrainDecisionResult({
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.marginMinutes,
    required this.minutesToNextDeparture,
    required this.minutesUntilFollowingDeparture,
    required this.arrivalAtStation,
  });

  final String primaryLabel;
  final String secondaryLabel;
  final int marginMinutes;
  final int minutesToNextDeparture;
  final int minutesUntilFollowingDeparture;
  final DateTime arrivalAtStation;
}

class TrainDecisionService {
  static const int defaultWalkingMinutes = 10;

  static TrainDecisionResult evaluate({
    required DateTime now,
    required DateTime nextDepartureAt,
    required DateTime secondDepartureAt,
    int walkingMinutes = defaultWalkingMinutes,
  }) {
    final arrivalAtStation = now.add(Duration(minutes: walkingMinutes));
    final marginMinutes = _floorMinutes(
      nextDepartureAt.difference(arrivalAtStation),
    );
    final minutesToNextDeparture = _floorMinutes(nextDepartureAt.difference(now));
    final minutesUntilFollowingDeparture = _floorMinutes(
      secondDepartureAt.difference(nextDepartureAt),
    );

    if (marginMinutes >= 5) {
      return TrainDecisionResult(
        primaryLabel: '余裕あり',
        secondaryLabel: '歩いて間に合う見込み',
        marginMinutes: marginMinutes,
        minutesToNextDeparture: minutesToNextDeparture,
        minutesUntilFollowingDeparture: minutesUntilFollowingDeparture,
        arrivalAtStation: arrivalAtStation,
      );
    }
    if (marginMinutes >= 2) {
      return TrainDecisionResult(
        primaryLabel: 'やや余裕あり',
        secondaryLabel: '急ぎ足で間に合う見込み',
        marginMinutes: marginMinutes,
        minutesToNextDeparture: minutesToNextDeparture,
        minutesUntilFollowingDeparture: minutesUntilFollowingDeparture,
        arrivalAtStation: arrivalAtStation,
      );
    }
    if (marginMinutes >= 0) {
      return TrainDecisionResult(
        primaryLabel: 'ぎりぎり',
        secondaryLabel: '次便もご確認ください',
        marginMinutes: marginMinutes,
        minutesToNextDeparture: minutesToNextDeparture,
        minutesUntilFollowingDeparture: minutesUntilFollowingDeparture,
        arrivalAtStation: arrivalAtStation,
      );
    }

    return TrainDecisionResult(
      primaryLabel: '次便推奨',
      secondaryLabel: 'この便は厳しい見込み',
      marginMinutes: marginMinutes,
      minutesToNextDeparture: minutesToNextDeparture,
      minutesUntilFollowingDeparture: minutesUntilFollowingDeparture,
      arrivalAtStation: arrivalAtStation,
    );
  }

  static int _floorMinutes(Duration duration) {
    final seconds = duration.inSeconds;
    if (seconds >= 0) return seconds ~/ 60;
    return -((-seconds + 59) ~/ 60);
  }
}
