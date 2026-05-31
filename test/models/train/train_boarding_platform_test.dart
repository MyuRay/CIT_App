import 'package:cit_app/models/train/train_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatTrainBoardingPlatform', () {
    test('returns empty for null', () {
      expect(formatTrainBoardingPlatform(null), '');
    });

    test('appends 番ホーム when only number given', () {
      expect(formatTrainBoardingPlatform('3'), '3番ホーム');
    });

    test('keeps full label as-is', () {
      expect(formatTrainBoardingPlatform('1・2番ホーム'), '1・2番ホーム');
    });
  });
}
