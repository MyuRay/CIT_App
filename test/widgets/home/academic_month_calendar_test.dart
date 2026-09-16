import 'package:cit_app/models/schedule/academic_calendar_event_model.dart';
import 'package:cit_app/widgets/common/app_system_safe_area.dart';
import 'package:cit_app/widgets/home/academic_month_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final months = List.generate(12, (index) => DateTime(2026, 4 + index));
final events = [
  for (final month in months)
    for (var index = 0; index < 6; index++)
      AcademicCalendarEvent(
        id: '${month.month}-$index',
        date: DateTime(month.year, month.month + 1, 0),
        title: '予定 $index',
      ),
];

Widget calendarApp(
  PageController controller, {
  bool sunday = true,
  double scale = 1,
  ValueChanged<int>? onPageChanged,
}) => MaterialApp(
  builder:
      (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: AppSystemSafeArea(child: child!),
      ),
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              AcademicCalendarPager(
                months: months,
                controller: controller,
                events: events,
                startsOnSunday: sunday,
                onPageChanged: onPageChanged ?? (_) {},
              ),
              const Text('カレンダーの次の内容'),
            ],
          ),
        ),
      ),
    ),
  ),
);

void main() {
  for (final width in [320.0, 390.0, 600.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final sunday in [true, false]) {
        testWidgets(
          'all months fit at width $width, scale $scale, Sunday start $sunday',
          (tester) async {
            tester.view.physicalSize = Size(width, 640);
            tester.view.devicePixelRatio = 1;
            tester.view.padding = const FakeViewPadding(bottom: 48);
            tester.view.viewPadding = const FakeViewPadding(bottom: 48);
            addTearDown(tester.view.reset);
            final controller = PageController();
            addTearDown(controller.dispose);
            await tester.pumpWidget(
              calendarApp(controller, sunday: sunday, scale: scale),
            );

            for (var index = 0; index < months.length; index++) {
              controller.jumpToPage(index);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              final month = months[index];
              final lastDay = DateTime(month.year, month.month + 1, 0).day;
              final lastCell = find.byKey(
                ValueKey('academic-day-${month.year}-${month.month}-$lastDay'),
              );
              expect(lastCell, findsOneWidget);
              expect(
                tester.getRect(lastCell).bottom,
                lessThanOrEqualTo(tester.getRect(find.byType(PageView)).bottom),
              );
              // A busy final day must retain every event marker.
              final markers = tester.widget<Wrap>(
                find.descendant(of: lastCell, matching: find.byType(Wrap)),
              );
              expect(markers.children, hasLength(6));
            }
            await tester.ensureVisible(find.text('カレンダーの次の内容'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(
              tester.getRect(find.text('カレンダーの次の内容')).bottom,
              lessThanOrEqualTo(640 - 48),
            );
          },
        );
      }
    }
  }

  testWidgets('swiping into a six-week month keeps the last week visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = PageController(initialPage: 3); // July 2026
    addTearDown(controller.dispose);
    var selected = 3;
    await tester.pumpWidget(
      calendarApp(controller, onPageChanged: (index) => selected = index),
    );
    final height = tester.getSize(find.byType(PageView)).height;
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(selected, 4);
    expect(find.text('2026年8月'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('academic-day-2026-8-31')),
      findsOneWidget,
    );
    expect(tester.getSize(find.byType(PageView)).height, height);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(calendarApp(controller, sunday: false, scale: 2));
    await tester.pumpAndSettle();
    expect(controller.page, 4);
    expect(tester.getSize(find.byType(PageView)).height, greaterThan(height));
    expect(tester.takeException(), isNull);
  });
}
