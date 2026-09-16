import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cit_app/models/schedule/schedule_model.dart';
import 'package:cit_app/services/schedule/schedule_class_edit.dart';
import 'package:cit_app/widgets/schedule/schedule_grid_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/theme_test_fonts.dart';

const _lesson = ScheduleClass(
  id: 'lesson',
  subjectName: '情報工学',
  classroom: '3号館',
  instructor: '担当教員',
  color: '#2196F3',
  notes: 'メモを保持',
  duration: 2,
);
const _other = ScheduleClass(
  id: 'other',
  subjectName: '数学',
  classroom: '',
  instructor: '',
  color: '#E53935',
);

Schedule _withTimetable(
  Schedule original,
  Map<String, Map<int, ScheduleClass?>> timetable,
) => Schedule(
  id: original.id,
  userId: original.userId,
  semester: original.semester,
  timeSlots: original.timeSlots,
  timetable: timetable,
);

Finder _cell(String day, int period, {bool empty = false}) =>
    find.byKey(ValueKey('schedule-${empty ? 'empty' : 'class'}-$day-$period'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<Brightness, ThemeData> themes;
  late Schedule schedule;
  late List<String> moves;
  late VoidCallback redraw;
  var taps = 0;
  final boundary = GlobalKey();

  setUpAll(() async => themes = await loadTestThemes());
  setUp(() {
    final empty = DefaultTimeSlots.createDefault(
      id: 'schedule',
      userId: 'owner',
      semester: '2026年度前期',
    );
    schedule = _withTimetable(
      empty,
      applyScheduleClassEdit(
        schedule: empty,
        weekdayKey: 'monday',
        period: 1,
        replacement: _lesson,
      ),
    );
    moves = [];
    taps = 0;
  });

  void occupy(String day, int period) {
    schedule = _withTimetable(
      schedule,
      applyScheduleClassEdit(
        schedule: schedule,
        weekdayKey: day,
        period: period,
        replacement: _other,
      ),
    );
  }

  Future<void> mount(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double width = 390,
    double height = 900,
    double scale = 1,
    bool edit = true,
    bool outerScroll = false,
    Future<void> Function()? save,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: themes[brightness],
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                padding: const EdgeInsets.only(bottom: 48),
              ),
              child: RepaintBoundary(key: boundary, child: child!),
            ),
        home: Scaffold(
          appBar: AppBar(title: const Text('時間割')),
          body: SafeArea(
            child: StatefulBuilder(
              builder: (context, setState) {
                redraw = () => setState(() {});
                final grid = ScheduleGridWidget(
                  schedule: schedule,
                  isEditMode: edit,
                  enableScroll: !outerScroll,
                  onClassTap: (_, _, _) => taps++,
                  onEmptySlotTap: (_, _) {},
                  onClassMove: (day, period, lesson, toDay, toPeriod) async {
                    moves.add('$day/$period/${lesson.id}->$toDay/$toPeriod');
                    await save?.call();
                    schedule = _withTimetable(
                      schedule,
                      applyScheduleClassMove(
                        schedule: schedule,
                        fromWeekdayKey: day,
                        fromPeriod: period,
                        toWeekdayKey: toDay,
                        toPeriod: toPeriod,
                        expectedClass: lesson,
                      ),
                    );
                    if (context.mounted) setState(() {});
                  },
                );
                return outerScroll ? SingleChildScrollView(child: grid) : grid;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<TestGesture> pickUp(WidgetTester tester) async {
    final rect = tester.getRect(_cell('monday', 1));
    final gesture = await tester.startGesture(
      Offset(rect.center.dx, rect.top + 24),
    );
    await tester.pump(const Duration(milliseconds: 600));
    return gesture;
  }

  Future<void> moveTo(
    WidgetTester tester,
    TestGesture gesture,
    String day,
    int period, {
    bool empty = true,
  }) async {
    await gesture.moveTo(tester.getCenter(_cell(day, period, empty: empty)));
    await tester.pump();
  }

  testWidgets('drag moves every period and retains lesson identity and data', (
    tester,
  ) async {
    await mount(tester);
    final gesture = await pickUp(tester);
    await moveTo(tester, gesture, 'wednesday', 4);
    expect(find.byKey(const ValueKey('schedule-drop-preview')), findsOneWidget);
    expect(find.text('4限へ'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(moves, ['monday/1/lesson->wednesday/4']);
    expect(taps, 0);
    expect(schedule.timetable['monday']![1], isNull);
    expect(schedule.timetable['monday']![2], isNull);
    expect(schedule.timetable['wednesday']![4]!.toJson(), _lesson.toJson());
    expect(schedule.timetable['wednesday']![5]!.isStartCell, isFalse);
    expect(_cell('monday', 1), findsNothing);
    expect(_cell('wednesday', 4), findsOneWidget);
  });

  for (final occupiedPeriod in [4, 5]) {
    testWidgets(
      'collision in destination period $occupiedPeriod restores source',
      (tester) async {
        occupy('tuesday', occupiedPeriod);
        await mount(tester);
        final gesture = await pickUp(tester);
        await moveTo(tester, gesture, 'tuesday', 4, empty: occupiedPeriod != 4);
        expect(
          find.byKey(const ValueKey('schedule-drop-overlap')),
          findsOneWidget,
        );
        expect(find.text('重複'), findsOneWidget);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(moves, isEmpty);
        expect(find.textContaining('重複：'), findsOneWidget);
        expect(find.textContaining('元の位置に戻しました'), findsOneWidget);
        expect(_cell('monday', 1), findsOneWidget);
        expect(schedule.timetable['monday']![1]!.toJson(), _lesson.toJson());
        expect(schedule.timetable['monday']![2]!.id, _lesson.id);
        expect(schedule.timetable['tuesday']![occupiedPeriod]!.id, _other.id);
        expect(
          find.byKey(const ValueKey('schedule-drop-overlap')),
          findsNothing,
        );
      },
    );
  }

  testWidgets('shift inside source continuation is allowed', (tester) async {
    await mount(tester);
    final gesture = await pickUp(tester);
    final source = tester.getRect(_cell('monday', 1));
    await gesture.moveTo(Offset(source.center.dx, source.bottom - 20));
    await tester.pump();
    expect(find.text('2限へ'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(moves, ['monday/1/lesson->monday/2']);
    expect(schedule.timetable['monday']![1], isNull);
    expect(schedule.timetable['monday']![2]!.isStartCell, isTrue);
    expect(schedule.timetable['monday']![3]!.isStartCell, isFalse);
  });

  testWidgets('lesson extending past period ten cannot be dropped', (
    tester,
  ) async {
    await mount(tester);
    final gesture = await pickUp(tester);
    await moveTo(tester, gesture, 'friday', 10);
    expect(find.text('移動不可'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(moves, isEmpty);
    expect(_cell('monday', 1), findsOneWidget);
    expect(find.textContaining('1限から10限'), findsOneWidget);
  });

  testWidgets('concurrent collision while saving leaves both lessons intact', (
    tester,
  ) async {
    final done = Completer<void>();
    await mount(tester, save: () => done.future);
    final gesture = await pickUp(tester);
    await moveTo(tester, gesture, 'tuesday', 4);
    await gesture.up();
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.tap(_cell('monday', 1), warnIfMissed: false);
    expect(taps, 0);
    occupy('tuesday', 5);
    redraw();
    done.complete();
    await tester.pumpAndSettle();
    expect(moves.length, 1);
    expect(find.textContaining('重複：'), findsOneWidget);
    expect(schedule.timetable['monday']![1]!.id, _lesson.id);
    expect(schedule.timetable['tuesday']![5]!.id, _other.id);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('network failure restores source and allows retry', (
    tester,
  ) async {
    var attempts = 0;
    await mount(
      tester,
      save: () async {
        if (attempts++ == 0) throw Exception('offline');
      },
    );
    final first = await pickUp(tester);
    await moveTo(tester, first, 'tuesday', 4);
    await first.up();
    await tester.pumpAndSettle();
    expect(_cell('monday', 1), findsOneWidget);
    expect(find.textContaining('通信状況を確認'), findsOneWidget);
    final second = await pickUp(tester);
    await moveTo(tester, second, 'wednesday', 3);
    await second.up();
    await tester.pumpAndSettle();
    expect(_cell('wednesday', 3), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets(
    'stationary long press, outside drop and cancellation do not save',
    (tester) async {
      await mount(tester);
      var gesture = await pickUp(tester);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(moves, isEmpty);
      gesture = await pickUp(tester);
      await gesture.moveTo(const Offset(20, 20));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(moves, isEmpty);
      gesture = await pickUp(tester);
      await moveTo(tester, gesture, 'tuesday', 4);
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(moves, isEmpty);
      expect(_cell('monday', 1), findsOneWidget);
      expect(find.text('2コマを移動'), findsNothing);
    },
  );

  testWidgets('ordinary tap still edits and viewing mode cannot drag', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(_cell('monday', 1));
    expect(taps, 1);
    await mount(tester, edit: false);
    final gesture = await pickUp(tester);
    await moveTo(tester, gesture, 'tuesday', 4);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(moves, isEmpty);
    expect(find.text('2コマを移動'), findsNothing);
  });

  for (final outerScroll in [false, true]) {
    testWidgets('edge scroll reaches offscreen periods (outer: $outerScroll)', (
      tester,
    ) async {
      await mount(tester, height: 420, outerScroll: outerScroll);
      final gesture = await pickUp(tester);
      final viewport = tester.getRect(find.byType(Scrollable));
      final x = tester.getCenter(_cell('tuesday', 1, empty: true)).dx;
      await gesture.moveTo(Offset(x, viewport.bottom - 15));
      for (var i = 0; i < 45; i++) {
        await tester.pump(const Duration(milliseconds: 32));
      }
      final position =
          tester.state<ScrollableState>(find.byType(Scrollable)).position;
      expect(position.pixels, greaterThan(250));
      final target = tester.getCenter(_cell('tuesday', 9, empty: true));
      expect(viewport.contains(target), isTrue);
      await gesture.moveTo(target);
      await tester.pump();
      expect(find.text('9限へ'), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(moves, ['monday/1/lesson->tuesday/9']);
      expect(schedule.timetable['tuesday']![10]!.id, _lesson.id);
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets('drag preview fits narrow large text in $brightness', (
      tester,
    ) async {
      occupy('tuesday', 5);
      await mount(tester, brightness: brightness, width: 320, scale: 2);
      final gesture = await pickUp(tester);
      await moveTo(tester, gesture, 'tuesday', 4);
      expect(find.text('重複'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (themePreviewDirectory.isNotEmpty) {
        await tester.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
          final image = await render.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            '$themePreviewDirectory/schedule-drag-${brightness.name}.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
