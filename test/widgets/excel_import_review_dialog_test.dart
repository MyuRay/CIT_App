import 'dart:io';
import 'dart:ui' as ui;

import 'package:cit_app/services/schedule/excel_schedule_import_service.dart';
import 'package:cit_app/widgets/schedule/excel_import_review_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/theme_test_fonts.dart';

const lecture = ImportedScheduleEntry(
  subjectName: '流通情報システム論',
  instructor: '山田 太郎',
  classroom: '644講義室',
  weekdayKey: 'tuesday',
  startPeriod: 1,
  duration: 2,
);
const draft = ScheduleImportDraft(
  entries: [lecture],
  warnings: ['集中講義「卒業研究」は曜日・時限がないため取り込んでいません。必要に応じて手動で追加してください。'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<Brightness, ThemeData> themes;
  ExcelImportReviewResult? result;
  var completed = false;
  final boundary = GlobalKey();
  setUpAll(() async => themes = await loadTestThemes());

  Future<void> mount(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double width = 390,
    double height = 844,
    double scale = 1,
  }) async {
    result = null;
    completed = false;
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
          body: Builder(
            builder:
                (context) => TextButton(
                  child: const Text('取り込みを開く'),
                  onPressed: () async {
                    result = await showExcelImportReviewDialog(
                      context,
                      draft,
                      sourceSemesterLabel: '2026年度 後期',
                      targetScheduleLabel: '後期の時間割',
                      onEditEntry:
                          (_, entry) async =>
                              entry.copyWith(classroom: '7205講義室'),
                    );
                    completed = true;
                  },
                ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('取り込みを開く'));
    await tester.pumpAndSettle();
  }

  testWidgets('defaults feedback on and retains reviewed lecture data', (
    tester,
  ) async {
    await mount(tester);
    expect(
      tester
          .widgetList<Checkbox>(find.byType(Checkbox))
          .map((box) => box.value),
      [false, true, true],
    );
    expect(find.textContaining('集中講義「卒業研究」'), findsOneWidget);
    expect(find.text('Excelの学期: 2026年度 後期'), findsOneWidget);
    expect(find.text('取り込み先: 後期の時間割'), findsOneWidget);
    await tester.tap(find.text('この内容で適用'));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    expect(result!.entries.single, lecture);
    expect(result!.clearExisting, isFalse);
    expect(result!.provideTrainingData, isTrue);
  });

  testWidgets('keeps editing and feedback opt-out available', (
    tester,
  ) async {
    await mount(tester);
    await tester.ensureVisible(find.byIcon(Icons.edit));
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    expect(find.textContaining('7205講義室'), findsOneWidget);
    await tester.ensureVisible(find.byType(Checkbox).last);
    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('この内容で適用'));
    await tester.pumpAndSettle();
    expect(result!.entries.single.classroom, '7205講義室');
    expect(result!.provideTrainingData, isFalse);
  });

  testWidgets(
    'deleting all entries disables applying and cancellation saves nothing',
    (tester) async {
      await mount(tester);
      await tester.ensureVisible(find.byIcon(Icons.delete_outline));
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(draft.entries, [lecture]);
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(completed, isTrue);
      expect(result, isNull);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'scrolls warnings and lectures on a small screen in ${brightness.name}',
      (tester) async {
        await mount(
          tester,
          brightness: brightness,
          width: 320,
          height: 568,
          scale: 2,
        );
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final applyRect = tester.getRect(
          find.widgetWithText(FilledButton, 'この内容で適用'),
        );
        expect(applyRect.bottom, lessThanOrEqualTo(568 - 48));
        await tester.tap(find.text('この内容で適用'));
        await tester.pumpAndSettle();
        expect(result!.entries.single, lecture);
      },
    );

    if (themePreviewDirectory.isNotEmpty) {
      testWidgets('preview ${brightness.name}', (tester) async {
        await mount(tester, brightness: brightness);
        await tester.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 1.5);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            '$themePreviewDirectory/excel-import-${brightness.name}.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
  }
}
