import 'dart:io';
import 'dart:ui' as ui;

import 'package:cit_app/models/schedule/academic_year_model.dart';
import 'package:cit_app/models/schedule/schedule_model.dart';
import 'package:cit_app/services/schedule/excel_import_semester.dart';
import 'package:cit_app/services/schedule/excel_schedule_import_service.dart';
import 'package:cit_app/widgets/schedule/excel_import_semester_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/theme_test_fonts.dart';

const lecture = ImportedScheduleEntry(
  subjectName: '情報システム論',
  instructor: '山田 太郎',
  classroom: '644講義室',
  weekdayKey: 'tuesday',
  startPeriod: 1,
  duration: 2,
);
const spring = SemesterScheduleImport(
  semester: ExcelImportSemester(
    year: 2026,
    semester: AcademicSemester.firstSemester,
  ),
  sourceSheetNames: ['Sheet1', 'Sheet2'],
  draft: ScheduleImportDraft(entries: [lecture], warnings: []),
  label: '2026年度 前期',
);
const autumn = SemesterScheduleImport(
  semester: ExcelImportSemester(
    year: 2026,
    semester: AcademicSemester.secondSemester,
  ),
  sourceSheetNames: ['Sheet3', 'Sheet4'],
  draft: ScheduleImportDraft(entries: [lecture], warnings: []),
  label: '2026年度 後期',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<Brightness, ThemeData> themes;
  final boundary = GlobalKey();
  ExcelImportSelection? result;
  var completed = false;
  setUpAll(() async => themes = await loadTestThemes());

  Future<void> mount(
    WidgetTester tester, {
    List<SemesterScheduleImport> semesters = const [spring, autumn],
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
    final schedules = [
      DefaultTimeSlots.createDefault(
        id: 'spring',
        userId: 'owner',
        semester: '2026年度前期',
      ),
      DefaultTimeSlots.createDefault(
        id: 'autumn',
        userId: 'owner',
        semester: '2026年度後期',
      ),
    ];
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
                  child: const Text('Excelを選ぶ'),
                  onPressed: () async {
                    result = await showExcelImportSemesterDialog(
                      context,
                      workbook: ScheduleWorkbookImport(semesters: semesters),
                      schedules: schedules,
                      selectedScheduleId: 'spring',
                    );
                    completed = true;
                  },
                ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Excelを選ぶ'));
    await tester.pumpAndSettle();
  }

  testWidgets('four sheets require choosing a semester before continuing', (
    tester,
  ) async {
    await mount(tester);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.text('1講義・2シート'), findsNWidgets(2));
    await tester.tap(find.text('2026年度 後期'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('内容を確認'));
    await tester.pumpAndSettle();
    expect(result!.source, autumn);
    expect(result!.target.id, 'autumn');
    expect(completed, isTrue);
  });

  testWidgets('two sheets identify the only available semester', (
    tester,
  ) async {
    await mount(tester, semesters: [autumn]);
    expect(find.text('2026年度 前期'), findsNothing);
    expect(find.text('2026年度 後期'), findsOneWidget);
    await tester.tap(find.text('内容を確認'));
    await tester.pumpAndSettle();
    expect(result!.source, autumn);
    expect(result!.target.id, 'autumn');
  });

  testWidgets(
    'switching source and selecting a destination are reflected in the result',
    (tester) async {
      await mount(tester);
      await tester.tap(find.text('2026年度 後期'));
      await tester.tap(find.text('2026年度 前期'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2026年度後期').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('内容を確認'));
      await tester.pumpAndSettle();
      expect(result!.source, spring);
      expect(result!.target.id, 'autumn');
    },
  );

  testWidgets('cancelling a semester selection has no import result', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.text('2026年度 後期'));
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    expect(result, isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'semester selection fits small large-text screens in ${brightness.name}',
      (tester) async {
        await mount(
          tester,
          brightness: brightness,
          width: 320,
          height: 568,
          scale: 2,
        );
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('2026年度 後期'));
        await tester.tap(find.text('2026年度 後期'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byType(DropdownButtonFormField<String>),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.widgetWithText(FilledButton, '内容を確認')).bottom,
          lessThanOrEqualTo(520),
        );
        await tester.tap(find.text('内容を確認'));
        await tester.pumpAndSettle();
        expect(result!.source, autumn);
      },
    );

    if (themePreviewDirectory.isNotEmpty) {
      testWidgets('semester selection preview ${brightness.name}', (
        tester,
      ) async {
        await mount(tester, brightness: brightness);
        await tester.tap(find.text('2026年度 後期'));
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 1.5);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            '$themePreviewDirectory/excel-semester-${brightness.name}.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
  }
}
