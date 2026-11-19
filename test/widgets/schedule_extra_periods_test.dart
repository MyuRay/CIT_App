import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cit_app/core/providers/schedule_provider.dart';
import 'package:cit_app/models/schedule/schedule_model.dart';
import 'package:cit_app/screens/schedule/schedule_edit_screen.dart';
import 'package:cit_app/widgets/schedule/schedule_grid_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  late Schedule schedule;
  var calls = 0;
  setUp(() {
    schedule = DefaultTimeSlots.createDefault(id: 'week', userId: 'owner');
    calls = 0;
  });

  Future<void> mount(
    WidgetTester tester, {
    bool edit = true,
    bool export = false,
    bool saturday = true,
    double scale = 1,
    Future<void> Function()? beforeSave,
  }) async {
    tester.view.physicalSize = const Size(320, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: StatefulBuilder(
              builder:
                  (context, setState) => ScheduleGridWidget(
                    schedule: schedule,
                    isEditMode: edit,
                    forceFullHeight: export,
                    showSaturday: saturday,
                    onClassTap: (_, _, _) {},
                    onEmptySlotTap: (_, _) {},
                    onAddPeriod: () async {
                      calls++;
                      await beforeSave?.call();
                      setState(
                        () => schedule = schedule.withAdditionalPeriod(),
                      );
                    },
                  ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'plus below period ten adds complete rows and moves below the new last row',
    (tester) async {
      await mount(tester);
      final add = find.byKey(const ValueKey('schedule-add-period'));
      expect(
        tester.getTopLeft(add).dy,
        greaterThan(
          tester
              .getBottomLeft(
                find.byKey(const ValueKey('schedule-empty-monday-10')),
              )
              .dy,
        ),
      );
      await tester.tap(add);
      await tester.pumpAndSettle();
      for (final day in Weekday.values) {
        expect(
          find.byKey(ValueKey('schedule-empty-${day.name}-11')),
          findsOneWidget,
        );
      }
      expect(find.byTooltip('12限を追加'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('rapid repeat taps do not add multiple rows while saving', (
    tester,
  ) async {
    final pending = Completer<void>();
    await mount(tester, beforeSave: () => pending.future);
    final add = find.byKey(const ValueKey('schedule-add-period'));
    await tester.tap(add);
    await tester.pump();
    await tester.tap(add);
    expect(calls, 1);
    pending.complete();
    await tester.pumpAndSettle();
    expect(schedule.periodCount, 11);
  });

  testWidgets('failed row save leaves the visible timetable unchanged', (
    tester,
  ) async {
    await mount(tester, beforeSave: () async => throw StateError('offline'));
    await tester.tap(find.byKey(const ValueKey('schedule-add-period')));
    await tester.pumpAndSettle();
    expect(schedule.periodCount, 10);
    expect(
      find.byKey(const ValueKey('schedule-empty-monday-11')),
      findsNothing,
    );
    expect(find.textContaining('時限を追加できませんでした'), findsOneWidget);
  });

  for (final saturday in [true, false]) {
    testWidgets(
      'all fifteen rows fit without range errors, saturday=$saturday, large text and export',
      (tester) async {
        for (var i = 10; i < 15; i++) {
          schedule = schedule.withAdditionalPeriod();
        }
        await mount(tester, export: true, saturday: saturday, scale: 2);
        expect(
          find.byKey(const ValueKey('schedule-empty-monday-15')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('schedule-add-period')), findsNothing);
        expect(find.text('23:00\n24:00'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('schedule-empty-saturday-15')),
          saturday ? findsOneWidget : findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('added rows stay visible in viewing mode and plus is hidden', (
    tester,
  ) async {
    schedule = schedule.withAdditionalPeriod();
    await mount(tester, edit: false);
    expect(
      find.byKey(const ValueKey('schedule-empty-monday-11')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('schedule-add-period')), findsNothing);
  });

  testWidgets('period eleven editor opens with a fallback time definition', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          timeSlotsProvider.overrideWithValue(DefaultTimeSlots.citTimeSlots),
        ],
        child: const MaterialApp(
          home: ScheduleEditScreen(
            scheduleId: 'week',
            weekdayKey: 'monday',
            period: 11,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('19:00 - 20:00'), findsOneWidget);
    await tester.ensureVisible(find.text('2時間連続'));
    await tester.tap(find.text('2時間連続'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 800));
    await tester.pumpAndSettle();
    expect(find.text('11-12限 (19:00 - 21:00)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'export paints the final extended lesson instead of clipping it',
    (tester) async {
      schedule = Schedule(
        id: 'week',
        userId: 'owner',
        semester: '後期',
        timeSlots: DefaultTimeSlots.forPeriodCount(15),
        timetable: {
          'monday': {
            15: const ScheduleClass(
              id: 'late',
              subjectName: '最終時限の演習',
              classroom: '101',
              instructor: '',
              color: '#2196F3',
            ),
          },
        },
      );
      final key = GlobalKey();
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RepaintBoundary(
                key: key,
                child: ScheduleGridWidget(
                  schedule: schedule,
                  forceFullHeight: true,
                  enableScroll: false,
                  onClassTap: (_, _, _) {},
                  onEmptySlotTap: (_, _) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      expect(find.text('最終時限の演習'), findsOneWidget);
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        expect(image.height, greaterThan(900));
        if (Platform.environment['CIT_SCHEDULE_PREVIEW']
            case final String directory) {
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '$directory/extended-schedule.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
        }
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    },
  );
}
