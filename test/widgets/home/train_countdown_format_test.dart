import 'package:cit_app/widgets/home/train_access_home_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatTrainCountdown', () {
    test('shows minutes and zero-padded seconds', () {
      expect(
        formatTrainCountdown(const Duration(minutes: 5, seconds: 7)),
        'あと5分07秒',
      );
    });

    test('shows seconds only under one minute', () {
      expect(formatTrainCountdown(const Duration(seconds: 42)), 'あと42秒');
    });

    test('shows imminent when elapsed', () {
      expect(
        formatTrainCountdown(const Duration(seconds: 0)),
        'まもなく発車',
      );
      expect(
        formatTrainCountdown(const Duration(seconds: -3)),
        'まもなく発車',
      );
    });
  });
}
