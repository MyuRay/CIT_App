import 'package:cit_app/services/train/train_departure_decision.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeTrainDepartureDecision', () {
    final base = DateTime(2026, 4, 7, 10, 0);

    test('noData when next is null', () {
      final r = computeTrainDepartureDecision(
        now: base,
        nextDepartureAt: null,
        secondDepartureAt: null,
      );
      expect(r.category, TrainDecisionCategory.noData);
    });

    test('plenty when margin >= 5 (walk 10: arrival 10:10, dep 10:15 => margin 5)', () {
      final r = computeTrainDepartureDecision(
        now: base,
        walkMinutesToStation: 10,
        nextDepartureAt: DateTime(2026, 4, 7, 10, 15),
        secondDepartureAt: DateTime(2026, 4, 7, 10, 30),
      );
      expect(r.category, TrainDecisionCategory.plenty);
      expect(r.marginMinutes, 5);
      expect(r.minutesUntilDepartureFromNow, 15);
    });

    test('slight when margin 4', () {
      final r = computeTrainDepartureDecision(
        now: base,
        walkMinutesToStation: 10,
        nextDepartureAt: DateTime(2026, 4, 7, 10, 14),
        secondDepartureAt: null,
      );
      expect(r.category, TrainDecisionCategory.slight);
      expect(r.marginMinutes, 4);
    });

    test('slight when margin 2', () {
      final r = computeTrainDepartureDecision(
        now: base,
        walkMinutesToStation: 10,
        nextDepartureAt: DateTime(2026, 4, 7, 10, 12),
        secondDepartureAt: null,
      );
      expect(r.category, TrainDecisionCategory.slight);
      expect(r.marginMinutes, 2);
    });

    test('tight when margin 1', () {
      final r = computeTrainDepartureDecision(
        now: base,
        walkMinutesToStation: 10,
        nextDepartureAt: DateTime(2026, 4, 7, 10, 11),
        secondDepartureAt: null,
      );
      expect(r.category, TrainDecisionCategory.tight);
      expect(r.marginMinutes, 1);
    });

    test('tight when margin 0', () {
      final r = computeTrainDepartureDecision(
        now: base,
        walkMinutesToStation: 10,
        nextDepartureAt: DateTime(2026, 4, 7, 10, 10),
        secondDepartureAt: null,
      );
      expect(r.category, TrainDecisionCategory.tight);
      expect(r.marginMinutes, 0);
    });

    test('recommendNext when margin -1', () {
      final r = computeTrainDepartureDecision(
        now: base,
        walkMinutesToStation: 10,
        nextDepartureAt: DateTime(2026, 4, 7, 10, 9),
        secondDepartureAt: null,
      );
      expect(r.category, TrainDecisionCategory.recommendNext);
      expect(r.marginMinutes, -1);
    });

    test('shifts to second when first is in the past', () {
      final r = computeTrainDepartureDecision(
        now: base,
        walkMinutesToStation: 10,
        nextDepartureAt: DateTime(2026, 4, 7, 9, 55),
        secondDepartureAt: DateTime(2026, 4, 7, 10, 20),
      );
      expect(r.effectiveNextDeparture, DateTime(2026, 4, 7, 10, 20));
      expect(r.minutesUntilDepartureFromNow, 20);
    });

    test('minutesBetweenNextAndSecond when both future', () {
      final r = computeTrainDepartureDecision(
        now: base,
        walkMinutesToStation: 10,
        nextDepartureAt: DateTime(2026, 4, 7, 10, 20),
        secondDepartureAt: DateTime(2026, 4, 7, 10, 35),
      );
      expect(r.minutesBetweenNextAndSecond, 15);
    });
  });
}
