import 'package:cit_app/services/train/train_static_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pickUpcomingFromTimeList returns next two after now', () {
    final now = DateTime(2026, 5, 26, 8, 45);
    final deps = TrainStaticSnapshot.pickUpcomingFromTimeList(
      const ['08:40', '08:49', '08:57', '09:04'],
      now,
      2,
    );
    expect(deps.length, 2);
    expect(deps[0].hour, 8);
    expect(deps[0].minute, 49);
    expect(deps[1].minute, 57);
  });
}
