import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cit_app/models/schedule/schedule_model.dart';
import 'package:cit_app/services/schedule/schedule_class_edit.dart';
import 'package:cit_app/widgets/schedule/schedule_class_move_dialog.dart';
import 'package:cit_app/widgets/schedule/schedule_grid_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/theme_test_fonts.dart';

const lesson = ScheduleClass(
  id: 'lesson',
  subjectName: '情報工学',
  classroom: '3号館',
  instructor: '担当教員',
  color: '#2196F3',
  notes: 'メモ',
  duration: 2,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<Brightness, ThemeData> themes;
  late Schedule schedule;
  final boundary = GlobalKey();
  setUpAll(() async {
    themes = await loadTestThemes();
    final empty = DefaultTimeSlots.createDefault(
      id: 'schedule',
      userId: 'owner',
      semester: '2026年度前期',
    );
    schedule = Schedule(
      id: empty.id,
      userId: empty.userId,
      semester: empty.semester,
      timeSlots: empty.timeSlots,
      timetable: applyScheduleClassEdit(
        schedule: empty,
        weekdayKey: 'monday',
        period: 1,
        replacement: lesson,
      ),
    );
  });

  Future<void> mountDialog(
    WidgetTester tester,
    Future<void> Function(String, int) onMove, {
    Brightness brightness = Brightness.light,
    double width = 390,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 844);
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
          body: Builder(
            builder:
                (context) => TextButton(
                  onPressed:
                      () => showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder:
                            (_) => ScheduleClassMoveDialog(
                              schedule: schedule,
                              weekdayKey: 'monday',
                              period: 1,
                              scheduleClass: lesson,
                              onMove: onMove,
                            ),
                      ),
                  child: const Text('移動先を選ぶ'),
                ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('移動先を選ぶ'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'edit mode long press opens movement without invoking normal edit',
    (tester) async {
      var taps = 0;
      String? selected;
      Widget grid(bool edit) => MaterialApp(
        theme: themes[Brightness.light],
        home: Scaffold(
          body: ScheduleGridWidget(
            schedule: schedule,
            isEditMode: edit,
            onClassTap: (_, _, _) => taps++,
            onEmptySlotTap: (_, _) {},
            onClassLongPress:
                (day, period, value) => selected = '$day/$period/${value.id}',
          ),
        ),
      );
      await tester.pumpWidget(grid(true));
      await tester.longPress(find.text('情報工学'));
      expect(selected, 'monday/1/lesson');
      expect(taps, 0);
      await tester.pumpWidget(grid(false));
      final detector = tester.widget<GestureDetector>(
        find
            .ancestor(
              of: find.text('情報工学'),
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      expect(detector.onLongPress, isNull);
    },
  );

  testWidgets(
    'chooses weekday and period, prevents out-of-range, and saves once',
    (tester) async {
      final done = Completer<void>();
      var calls = 0;
      String? destination;
      await mountDialog(tester, (day, period) {
        calls++;
        destination = '$day/$period';
        return done.future;
      });
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.text('土曜'));
      await tester.tap(find.text('10限'));
      await tester.pumpAndSettle();
      expect(find.text('連続講義は1限から10限の範囲に収めてください'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.text('9限'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ここに移動'));
      await tester.pump();
      expect(destination, 'saturday/9');
      await tester.tap(find.text('移動中…'));
      expect(calls, 1);
      done.complete();
      await tester.pumpAndSettle();
      expect(find.byType(ScheduleClassMoveDialog), findsNothing);
    },
  );

  testWidgets(
    'failed save keeps destination for retry and cancel performs no write',
    (tester) async {
      var calls = 0;
      await mountDialog(tester, (_, _) async {
        calls++;
        throw StateError('移動先が更新されました');
      });
      await tester.tap(find.text('水曜'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ここに移動'));
      await tester.pumpAndSettle();
      expect(find.text('移動先が更新されました'), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '水曜'))
            .selected,
        isTrue,
      );
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.byType(ScheduleClassMoveDialog), findsNothing);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets('move picker supports $brightness and 200 percent text', (
      tester,
    ) async {
      await mountDialog(tester, (_, _) async {}, brightness: brightness);
      if (themePreviewDirectory.isNotEmpty) {
        await tester.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
          final image = await render.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            '$themePreviewDirectory/schedule-move-${brightness.name}.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      await mountDialog(
        tester,
        (_, _) async {},
        brightness: brightness,
        width: 320,
        scale: 2,
      );
      await tester.ensureVisible(find.text('10限'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('ここに移動'), findsOneWidget);
    });
  }
}
