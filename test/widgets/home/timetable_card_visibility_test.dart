import 'package:cit_app/models/schedule/lecture_period_model.dart';
import 'package:cit_app/widgets/home/timetable_card_visibility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final settings = LecturePeriodSettings(
    springStartDate: DateTime(2026, 4, 11),
    springEndDate: DateTime(2026, 7, 18),
    fallStartDate: DateTime(2026, 9, 18),
    fallEndDate: DateTime(2026, 12, 22),
  );

  for (final date in [
    DateTime(2026, 4, 11),
    DateTime(2026, 6, 1, 12),
    DateTime(2026, 7, 18, 23, 59, 59),
    DateTime(2026, 9, 18),
    DateTime(2026, 10, 1, 12),
    DateTime(2026, 12, 22, 23, 59, 59),
  ]) {
    test(
      'shows during either lecture period including boundary day: $date',
      () {
        expect(
          isOutsideHomeTimetableLecturePeriod(settings: settings, date: date),
          isFalse,
        );
      },
    );
  }

  for (final date in [
    DateTime(2026, 4, 10, 23, 59, 59),
    DateTime(2026, 7, 19),
    DateTime(2026, 9, 17, 23, 59, 59),
    DateTime(2026, 12, 23),
  ]) {
    test('auto-hides outside both configured lecture periods: $date', () {
      expect(
        isOutsideHomeTimetableLecturePeriod(settings: settings, date: date),
        isTrue,
      );
    });
  }

  test('shows when settings are loading, unavailable or not configured', () {
    for (final settings in [
      null,
      const LecturePeriodSettings(),
      LecturePeriodSettings(fallStartDate: DateTime(2026, 9, 18)),
      LecturePeriodSettings(
        springStartDate: DateTime(2026, 7, 18),
        springEndDate: DateTime(2026, 4, 11),
      ),
    ]) {
      expect(
        isOutsideHomeTimetableLecturePeriod(
          settings: settings,
          date: DateTime(2026, 9, 18),
        ),
        isFalse,
      );
    }
  });

  test('returns to visible on the first lecture day after summer vacation', () {
    expect(
      isOutsideHomeTimetableLecturePeriod(
        settings: settings,
        date: DateTime(2026, 9, 17, 23, 59, 59),
      ),
      isTrue,
    );
    expect(
      isOutsideHomeTimetableLecturePeriod(
        settings: settings,
        date: DateTime(2026, 9, 18),
      ),
      isFalse,
    );
  });

  test('legacy lecture period settings still determine visibility', () {
    final legacy = LecturePeriodSettings.fromMap({
      'lectureStartDate': DateTime(2026, 4, 11),
      'lectureEndDate': DateTime(2026, 7, 18),
    });
    expect(
      isOutsideHomeTimetableLecturePeriod(
        settings: legacy,
        date: DateTime(2026, 4, 11),
      ),
      isFalse,
    );
    expect(
      isOutsideHomeTimetableLecturePeriod(
        settings: legacy,
        date: DateTime(2026, 7, 19),
      ),
      isTrue,
    );
  });
}
