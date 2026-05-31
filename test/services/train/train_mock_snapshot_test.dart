import 'package:cit_app/models/train/train_snapshot.dart';
import 'package:cit_app/services/train/train_mock_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrainMockSnapshot', () {
    test('build returns two directions for tsudanuma', () {
      final now = DateTime(2026, 5, 17, 10, 0);
      final snap = TrainMockSnapshot.build('tsudanuma', now);
      expect(snap.stationName, '津田沼');
      expect(snap.directions.length, 2);
      expect(snap.delay.status, TrainDelayStatus.normal);
    });

    test('next departures are after now', () {
      final now = DateTime(2026, 5, 17, 10, 0);
      final times = TrainMockSnapshot.nextDepartures(now, 3, 5, 2);
      expect(times.length, 2);
      expect(times[0].isAfter(now), isTrue);
      expect(times[1].isAfter(times[0]), isTrue);
    });

    test('narashino uses keiyo-style directions', () {
      final snap = TrainMockSnapshot.build(
        'narashino',
        DateTime(2026, 5, 17, 18, 30),
      );
      expect(snap.stationName, '新習志野');
      expect(
        snap.directions.map((d) => d.directionKey),
        contains('kaihimmakuhari'),
      );
    });

    test('directions include boarding platform for mock', () {
      final snap = TrainMockSnapshot.build('tsudanuma', DateTime(2026, 5, 17, 10));
      final tokyo = snap.directions.firstWhere((d) => d.directionKey == 'tokyo');
      expect(tokyo.boardingPlatform, '1・2番ホーム');
    });
  });
}
