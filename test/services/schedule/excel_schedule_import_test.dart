import 'dart:io';
import 'dart:typed_data';

import 'package:cit_app/models/schedule/schedule_model.dart';
import 'package:cit_app/models/schedule/academic_year_model.dart';
import 'package:cit_app/services/schedule/excel_import_feedback_service.dart';
import 'package:cit_app/services/schedule/excel_schedule_import_service.dart';
import 'package:cit_app/services/schedule/schedule_service.dart';
import 'package:excel/excel.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// Anonymous fixtures retain the university export's merged/variable-height rows.
Excel universityWorkbook({
  bool legacy = false,
  bool headers = true,
  String firstSheet = 'Sheet1',
  String secondSheet = 'Sheet2',
  int offset = 0,
}) {
  final book = Excel.createExcel();
  if (firstSheet != 'Sheet1') book.rename('Sheet1', firstSheet);
  final columns = legacy ? [14, 35, 56, 77, 98, 119] : [3, 9, 15, 21, 27, 33];
  final periodColumn = (legacy ? 8 : 2) + offset;
  final days = ['月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日'];
  for (final name in [firstSheet, secondSheet]) {
    final sheet = book[name];
    setCell(sheet, 2, 3, '学籍番号');
    setCell(sheet, 9, 3, 'S9999999');
    setCell(sheet, 2, 4, '氏名');
    setCell(sheet, 9, 4, '取込 太郎');
    setCell(sheet, 2, 6, '2026年度 後期');
    if (headers) {
      for (var day = 0; day < columns.length; day++) {
        setCell(sheet, columns[day] + offset, 7, days[day]);
        sheet.merge(
          CellIndex.indexByColumnRow(
            columnIndex: columns[day] + offset,
            rowIndex: 7,
          ),
          CellIndex.indexByColumnRow(
            columnIndex: columns[day] + offset + 4,
            rowIndex: 7,
          ),
        );
      }
    }
  }
  final sheet = book[firstSheet];
  final anchors = [8, 16, 24, 28, 32, 36, 41, 45, 49];
  for (var index = 0; index < anchors.length; index++) {
    setCell(sheet, periodColumn, anchors[index], '${index + 1}');
  }
  for (final row in [8, 16]) {
    final values = [
      '流通情報システム',
      '論 経情マネコース',
      '3年',
      '山田 太郎',
      '６４４講義室／津',
      '田沼キャンパス',
      '[複数回]',
      '2単位',
    ];
    for (var index = 0; index < values.length; index++) {
      setCell(sheet, columns[1] + offset, row + index, values[index]);
    }
  }
  final second = book[secondSheet];
  setCell(second, periodColumn, 8, '10');
  setCell(second, periodColumn, 12, '津田沼キャンパス（1限 09:00～10:00）');
  setCell(second, periodColumn, 14, '集中講義');
  setCell(second, periodColumn, 15, '授業科目');
  setCell(second, periodColumn, 16, '卒業研究 経情 [複数学期]');
  setCell(second, columns[3] + offset, 16, '教室');
  return book;
}

void setCell(Sheet sheet, int col, int row, String value) {
  sheet
      .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
      .value = TextCellValue(value);
}

Uint8List workbookBytes(Excel book) => Uint8List.fromList(book.encode()!);

// Some printed exports place the next lecture's first line just above its
// period number. The previous lecture has already ended with its unit footer.
Excel wrappedBoundaryWorkbook({
  bool differentNextLecture = false,
  int secondTitleRow = 17,
}) {
  final book = Excel.createExcel();
  final sheet = book['Sheet1'];
  setCell(sheet, 2, 6, '2026年度 後期');
  setCell(sheet, 9, 7, '火曜日');
  setCell(sheet, 27, 7, '金曜日');
  setCell(sheet, 2, 8, '3');
  setCell(sheet, 2, 18, '4');
  setCell(sheet, 2, 28, '5');
  setCell(sheet, 2, 38, '集中講義');
  for (final col in [9, 27]) {
    for (final row in [8, secondTitleRow]) {
      final values = [
        if (differentNextLecture && row == secondTitleRow)
          '別の講義 経デ'
        else if (col == 9)
          '人間工学概論 経デ'
        else
          'システム方法論 経',
        col == 9 || differentNextLecture ? '2年 ※経情' : 'デ2年 ※経P',
        '山田 太郎',
        col == 9 ? '５２０９講義室／' : '６２１講義室／',
        '新習志野キャンパス',
        '[複数回]',
        '2単位',
      ];
      for (var index = 0; index < values.length; index++) {
        setCell(sheet, col, row + index, values[index]);
      }
    }
  }
  return book;
}

Excel bothSemestersWorkbook({bool legacy = false, bool headers = true}) {
  final book = universityWorkbook(legacy: legacy, headers: headers);
  book.copy('Sheet1', 'Sheet3');
  book.copy('Sheet2', 'Sheet4');
  for (final sheet in ['Sheet1', 'Sheet2']) {
    setCell(book[sheet], 2, 6, '2026年度 前期');
  }
  final column = legacy ? 35 : 9;
  for (final row in [8, 16]) {
    setCell(book['Sheet3'], column, row, '後期特別');
    setCell(book['Sheet3'], column, row + 1, '演習');
  }
  setCell(book['Sheet2'], legacy ? 8 : 2, 16, '前期集中科目');
  setCell(book['Sheet4'], legacy ? 8 : 2, 16, '後期集中科目');
  return book;
}

void expectAutumnLecture(ScheduleImportDraft draft) {
  expect(draft.entries, hasLength(1));
  final lecture = draft.entries.single;
  expect(lecture.subjectName, '流通情報システム論');
  expect(lecture.weekdayKey, 'tuesday');
  expect(lecture.startPeriod, 1);
  expect(lecture.duration, 2);
  expect(lecture.classroom, '644講義室');
  expect(draft.warnings, hasLength(1));
  expect(draft.warnings.single, contains('卒業研究'));
}

void main() {
  test(
    'keeps wrapped titles above a period number in one continuous lecture',
    () async {
      final draft = await ExcelScheduleImportService.parseExcelBytes(
        workbookBytes(wrappedBoundaryWorkbook()),
      );
      expect(draft.entries, hasLength(2));
      expect(draft.entries.map((e) => e.subjectName), [
        '人間工学概論 経デ2年',
        'システム方法論 経デ2年',
      ]);
      for (final entry in draft.entries) {
        expect(entry.startPeriod, 3);
        expect(entry.duration, 2);
        expect(entry.instructor, '山田 太郎');
      }
      expect(draft.entries.map((e) => e.classroom), ['5209講義室', '621講義室']);
      expect(draft.warnings, isEmpty);
    },
  );

  test(
    'a shifted boundary does not merge different courses with the same teacher and room',
    () async {
      final draft = await ExcelScheduleImportService.parseExcelBytes(
        workbookBytes(wrappedBoundaryWorkbook(differentNextLecture: true)),
      );
      expect(draft.entries, hasLength(4));
      expect(
        draft.entries
            .where((e) => e.startPeriod == 4)
            .map((e) => e.subjectName),
        everyElement('別の講義 経デ2年'),
      );
      expect(draft.entries.every((e) => e.duration == 1), isTrue);
    },
  );

  test(
    'feedback preserves the shifted lecture boundary without personal headers',
    () async {
      final book = wrappedBoundaryWorkbook();
      setCell(book['Sheet1'], 9, 3, '保存しない個人情報');
      final sanitized = ExcelImportFeedbackService.prepareTrainingWorkbook(
        workbookBytes(book),
      );
      final draft = await ExcelScheduleImportService.parseExcelBytes(sanitized);
      expect(draft.entries, hasLength(2));
      expect(draft.entries.every((e) => e.duration == 2), isTrue);
      expect(
        Excel.decodeBytes(sanitized).tables.values
            .expand((sheet) => sheet.rows)
            .expand((row) => row)
            .any(
              (cell) => cell?.value?.toString().contains('保存しない個人情報') ?? false,
            ),
        isFalse,
      );
    },
  );

  test(
    'reads a title below a blank period row, including after feedback sanitization',
    () async {
      final bytes = workbookBytes(wrappedBoundaryWorkbook(secondTitleRow: 19));
      for (final input in [
        bytes,
        ExcelImportFeedbackService.prepareTrainingWorkbook(bytes),
      ]) {
        final draft = await ExcelScheduleImportService.parseExcelBytes(input);
        expect(draft.entries, hasLength(2));
        expect(draft.entries.every((e) => e.duration == 2), isTrue);
        expect(draft.entries.first.subjectName, '人間工学概論 経デ2年');
      }
    },
  );

  test(
    'does not turn a wrapped footer into a lecture in the following empty slot',
    () async {
      final book = universityWorkbook();
      for (var row = 14; row < 24; row++) {
        setCell(book['Sheet1'], 9, row, '');
      }
      setCell(book['Sheet1'], 9, 14, '[複数回] [定');
      setCell(book['Sheet1'], 9, 15, '員有]');
      setCell(book['Sheet1'], 9, 16, '2単位');
      final draft = await ExcelScheduleImportService.parseExcelBytes(
        workbookBytes(book),
      );
      expect(draft.entries, hasLength(1));
      expect(draft.entries.single.subjectName, '流通情報システム論');
      expect(draft.entries.single.duration, 1);
    },
  );

  test(
    'saves a recovered continuous lecture as one shared class across both cells',
    () async {
      final db = FakeFirebaseFirestore();
      ScheduleService.firestoreOverride = db;
      addTearDown(() => ScheduleService.firestoreOverride = null);
      final schedule = DefaultTimeSlots.createDefault(
        id: 'wrapped-import',
        userId: 'owner',
        semester: '2026年度後期',
      );
      await db.collection('schedules').doc(schedule.id).set(schedule.toJson());
      final draft = await ExcelScheduleImportService.parseExcelBytes(
        workbookBytes(wrappedBoundaryWorkbook()),
      );
      final result = await ExcelScheduleImportService.applyImport(
        scheduleId: schedule.id,
        entries: draft.entries,
        clearExisting: false,
        autoColorAdjacent: true,
      );
      expect(result.appliedCount, 2);
      final saved = (await ScheduleService.getScheduleById(schedule.id))!;
      for (final day in ['tuesday', 'friday']) {
        final first = saved.timetable[day]![3]!;
        final continuation = saved.timetable[day]![4]!;
        expect(first.id, continuation.id);
        expect(first.subjectName, continuation.subjectName);
        expect(first.duration, 2);
        expect(continuation.duration, 2);
        expect(first.isStartCell, isTrue);
        expect(continuation.isStartCell, isFalse);
        expect(saved.timetable[day]![5], isNull);
      }
    },
  );

  test(
    'masked instructor remains empty and is identified for review',
    () async {
      final book = universityWorkbook();
      for (final row in [8, 16]) {
        setCell(book['Sheet1'], 9, row + 3, '●●●●');
      }
      final draft = await ExcelScheduleImportService.parseExcelBytes(
        workbookBytes(book),
      );
      expect(draft.entries, hasLength(1));
      expect(draft.entries.single.subjectName, '流通情報システム論');
      expect(draft.entries.single.classroom, '644講義室');
      expect(draft.entries.single.instructor, isEmpty);
      expect(
        draft.warnings.where((warning) => warning.contains('担当教員')),
        hasLength(1),
      );
    },
  );

  test('imports compact autumn export and excludes untimed courses', () async {
    final draft = await ExcelScheduleImportService.parseExcelBytes(
      workbookBytes(universityWorkbook()),
    );
    expectAutumnLecture(draft);
    expect(draft.entries.single.instructor, '山田 太郎');
  });

  test('keeps the wide legacy university layout supported', () async {
    final draft = await ExcelScheduleImportService.parseExcelBytes(
      workbookBytes(universityWorkbook(legacy: true)),
    );
    expectAutumnLecture(draft);
  });

  test(
    'keeps legacy files without readable weekday headers supported',
    () async {
      final draft = await ExcelScheduleImportService.parseExcelBytes(
        workbookBytes(universityWorkbook(legacy: true, headers: false)),
      );
      expectAutumnLecture(draft);
    },
  );

  test('detects labelled sheets after renaming and column insertion', () async {
    final book = universityWorkbook(
      firstSheet: '後期時間割',
      secondSheet: '続き',
      offset: 4,
    );
    setCell(book['説明'], 0, 0, '1');
    setCell(book['説明'], 1, 0, '取り込まないデータ');
    final draft = await ExcelScheduleImportService.parseExcelBytes(
      workbookBytes(book),
    );
    expectAutumnLecture(draft);
  });

  test(
    'supports all weekdays, period ten and numeric or fullwidth anchors',
    () async {
      final book = universityWorkbook();
      final first = book['Sheet1'];
      final columns = [3, 9, 15, 21, 27, 33];
      for (var day = 0; day < columns.length; day++) {
        setCell(first, columns[day], 24, '科目${day + 1}');
      }
      setCell(first, 2, 24, '第３時限');
      book['Sheet2']
          .cell(CellIndex.indexByString('C9'))
          .value = const IntCellValue(10);
      setCell(book['Sheet2'], 33, 8, '土曜特別演習');
      setCell(book['Sheet2'], 33, 9, '鈴木 次郎');
      setCell(book['Sheet2'], 33, 10, '７２０５講義室');
      final draft = await ExcelScheduleImportService.parseExcelBytes(
        workbookBytes(book),
      );
      expect(draft.entries, hasLength(8));
      expect(
        draft.entries
            .where((e) => e.startPeriod == 3)
            .map((e) => e.weekdayKey)
            .toSet(),
        {'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'},
      );
      final last = draft.entries.last;
      expect(last.startPeriod, 10);
      expect(last.subjectName, '土曜特別演習');
      expect(last.instructor, '鈴木 次郎');
      expect(last.classroom, '7205講義室');
    },
  );

  test('does not merge separate meetings of the same subject', () async {
    final book = universityWorkbook();
    // Keep the second occurrence identical but move it from period 2 to 3.
    setCell(book['Sheet1'], 2, 16, '3');
    setCell(book['Sheet1'], 2, 24, '4');
    final draft = await ExcelScheduleImportService.parseExcelBytes(
      workbookBytes(book),
    );
    expect(draft.entries, hasLength(2));
    expect(draft.entries.map((e) => e.startPeriod), [1, 3]);
    expect(draft.entries.every((e) => e.duration == 1), isTrue);
  });

  test('merges a continuous lecture across the two export pages', () async {
    final book = universityWorkbook();
    for (final location in [(book['Sheet1'], 49), (book['Sheet2'], 8)]) {
      setCell(location.$1, 21, location.$2, '実践演習');
      setCell(location.$1, 21, location.$2 + 1, '山田 太郎');
      setCell(location.$1, 21, location.$2 + 2, '９１０講義室');
    }
    final draft = await ExcelScheduleImportService.parseExcelBytes(
      workbookBytes(book),
    );
    final lecture = draft.entries.singleWhere(
      (e) => e.weekdayKey == 'thursday',
    );
    expect(lecture.startPeriod, 9);
    expect(lecture.duration, 2);
    expect(lecture.classroom, '910講義室');
  });

  test(
    'optional feedback excludes personal headers and unrelated sheets',
    () async {
      final book = universityWorkbook(
        firstSheet: 'S9999999の時間割',
        secondSheet: '後期の続き',
      );
      setCell(book['個人情報'], 0, 0, '保存しない氏名');
      setCell(book['S9999999の時間割'], 8, 3, '旧形式の学籍番号');
      setCell(book['S9999999の時間割'], 32, 3, '旧形式の氏名');
      final prepared = ExcelImportFeedbackService.prepareTrainingWorkbook(
        workbookBytes(book),
      );
      final filtered = Excel.decodeBytes(prepared);
      expect(filtered.tables.keys, ['Sheet1', 'Sheet2']);
      final cells = filtered.tables.values
          .expand((sheet) => sheet.rows)
          .expand((row) => row)
          .map((cell) => cell?.value.toString() ?? '')
          .join('|');
      for (final privateValue in [
        '学籍番号',
        '氏名',
        'S9999999',
        '取込 太郎',
        '個人情報',
        '卒業研究',
      ]) {
        expect(cells, isNot(contains(privateValue)));
      }
      final parsed = await ExcelScheduleImportService.parseExcelBytes(prepared);
      expect(parsed.entries, hasLength(1));
      expect(parsed.entries.single.subjectName, '流通情報システム論');
      expect(parsed.entries.single.instructor, '山田 太郎');
      expect(parsed.entries.single.duration, 2);
    },
  );

  test(
    'optional feedback preserves old layout data without exposing headers',
    () async {
      final prepared = ExcelImportFeedbackService.prepareTrainingWorkbook(
        workbookBytes(universityWorkbook(legacy: true, headers: false)),
      );
      final parsed = await ExcelScheduleImportService.parseExcelBytes(prepared);
      expect(parsed.entries, hasLength(1));
      expect(parsed.entries.single.subjectName, '流通情報システム論');
    },
  );

  test(
    'optional feedback refuses an unrecognized file instead of returning the source',
    () {
      expect(
        () => ExcelImportFeedbackService.prepareTrainingWorkbook(
          workbookBytes(Excel.createExcel()),
        ),
        throwsFormatException,
      );
      expect(
        () => ExcelImportFeedbackService.prepareTrainingWorkbook(
          Uint8List.fromList([1, 2, 3]),
        ),
        throwsA(anything),
      );
    },
  );

  test('rejects unrelated workbooks with a useful message', () async {
    final book = Excel.createExcel();
    setCell(book['Sheet1'], 0, 0, '2026年後期');
    final draft = await ExcelScheduleImportService.parseExcelBytes(
      workbookBytes(book),
    );
    expect(draft.entries, isEmpty);
    expect(draft.warnings.single, contains('学生時間割表'));
  });

  test(
    'writes the imported double period into the selected autumn schedule',
    () async {
      final db = FakeFirebaseFirestore();
      ScheduleService.firestoreOverride = db;
      addTearDown(() => ScheduleService.firestoreOverride = null);
      for (final id in ['spring', 'autumn']) {
        final schedule = DefaultTimeSlots.createDefault(
          id: id,
          userId: 'owner',
          semester: id == 'autumn' ? '2026年度後期' : '2026年度前期',
        );
        await db.collection('schedules').doc(id).set(schedule.toJson());
      }
      final draft = await ExcelScheduleImportService.parseExcelBytes(
        workbookBytes(universityWorkbook()),
      );
      final result = await ExcelScheduleImportService.applyImport(
        scheduleId: 'autumn',
        entries: draft.entries,
        clearExisting: false,
        autoColorAdjacent: true,
      );
      expect(result.appliedCount, 1);
      final saved = (await ScheduleService.getScheduleById('autumn'))!;
      final first = saved.timetable['tuesday']![1]!;
      final continuation = saved.timetable['tuesday']![2]!;
      expect(first.subjectName, '流通情報システム論');
      expect(first.duration, 2);
      expect(first.id, continuation.id);
      expect(first.isStartCell, isTrue);
      expect(continuation.isStartCell, isFalse);
      expect(first.classroom, '644講義室');
      final spring = (await ScheduleService.getScheduleById('spring'))!;
      expect(
        spring.timetable.values
            .expand((day) => day.values)
            .every((e) => e == null),
        isTrue,
      );
    },
  );

  for (final term in ['前期', '後期']) {
    test('identifies a two-sheet $term workbook', () async {
      final book = universityWorkbook();
      for (final sheet in book.tables.values) {
        setCell(sheet, 2, 6, '2026年度 $term');
      }
      final parsed = await ExcelScheduleImportService.parseWorkbookBytes(
        workbookBytes(book),
      );
      expect(parsed.semesters, hasLength(1));
      expect(parsed.semesters.single.label, '2026年度 $term');
      expect(parsed.semesters.single.sourceSheetNames, ['Sheet1', 'Sheet2']);
    });
  }

  for (final legacy in [false, true]) {
    test('separates both semesters in four sheets (legacy=$legacy)', () async {
      final bytes = workbookBytes(
        bothSemestersWorkbook(legacy: legacy, headers: !legacy),
      );
      final parsed = await ExcelScheduleImportService.parseWorkbookBytes(bytes);
      expect(parsed.semesters.map((term) => term.label), [
        '2026年度 前期',
        '2026年度 後期',
      ]);
      expect(parsed.semesters.first.sourceSheetNames, ['Sheet1', 'Sheet2']);
      expect(parsed.semesters.last.sourceSheetNames, ['Sheet3', 'Sheet4']);
      expect(
        parsed.semesters.first.draft.entries.single.subjectName,
        '流通情報システム論',
      );
      expect(parsed.semesters.last.draft.entries.single.subjectName, '後期特別演習');
      expect(
        parsed.semesters.every((s) => s.draft.entries.single.duration == 2),
        isTrue,
      );
      // Never let a caller accidentally apply a flattened year-long timetable.
      await expectLater(
        ExcelScheduleImportService.parseExcelBytes(bytes),
        throwsFormatException,
      );
    });
  }

  test(
    'header labels win over tab order and keep different academic years separate',
    () async {
      final book = bothSemestersWorkbook();
      setCell(book['Sheet1'], 2, 6, '２０２５年度 秋学期');
      setCell(book['Sheet2'], 2, 6, '2025年度 後期');
      final parsed = await ExcelScheduleImportService.parseWorkbookBytes(
        workbookBytes(book),
      );
      expect(parsed.semesters.map((term) => term.label), [
        '2025年度 後期',
        '2026年度 後期',
      ]);
      for (final sheet in ['Sheet1', 'Sheet2']) {
        setCell(book[sheet], 2, 6, '2026年度 後期');
      }
      for (final sheet in ['Sheet3', 'Sheet4']) {
        setCell(book[sheet], 2, 6, '2026年度 春学期');
      }
      final reversed = await ExcelScheduleImportService.parseWorkbookBytes(
        workbookBytes(book),
      );
      expect(reversed.semesters.first.sourceSheetNames, ['Sheet3', 'Sheet4']);
      expect(
        reversed.semesters.first.semester.semester,
        AcademicSemester.firstSemester,
      );
    },
  );

  test(
    'unlabelled four-sheet file stays in separate candidates without guessing a semester',
    () async {
      final book = bothSemestersWorkbook();
      for (final sheet in book.tables.values) {
        setCell(sheet, 2, 6, '');
      }
      final parsed = await ExcelScheduleImportService.parseWorkbookBytes(
        workbookBytes(book),
      );
      expect(parsed.semesters, hasLength(2));
      expect(
        parsed.semesters.every((s) => s.semester.semester == null),
        isTrue,
      );
      expect(
        parsed.semesters.every((s) => s.draft.entries.length == 1),
        isTrue,
      );
      expect(parsed.semesters.first.label, contains('候補1'));
      expect(parsed.semesters.last.label, contains('候補2'));
    },
  );

  test(
    'empty semester remains identifiable and selectable without borrowing the other semester',
    () async {
      final book = bothSemestersWorkbook();
      for (var row = 8; row <= 23; row++) {
        setCell(book['Sheet1'], 9, row, '');
      }
      final parsed = await ExcelScheduleImportService.parseWorkbookBytes(
        workbookBytes(book),
      );
      expect(parsed.semesters.first.draft.entries, isEmpty);
      expect(parsed.semesters.last.draft.entries, hasLength(1));
    },
  );

  test('feedback only includes the selected semester sheets', () async {
    final bytes = workbookBytes(bothSemestersWorkbook());
    final parsed = await ExcelScheduleImportService.parseWorkbookBytes(bytes);
    final autumn = parsed.semesters.last;
    final sanitized = ExcelImportFeedbackService.prepareTrainingWorkbook(
      bytes,
      sourceSheetNames: autumn.sourceSheetNames,
    );
    final preview = await ExcelScheduleImportService.parseExcelBytes(sanitized);
    expect(preview.entries, hasLength(1));
    expect(preview.entries.single.subjectName, '後期特別演習');
    expect(Excel.decodeBytes(sanitized).tables, hasLength(2));
    expect(
      () => ExcelImportFeedbackService.prepareTrainingWorkbook(
        bytes,
        sourceSheetNames: [],
      ),
      throwsFormatException,
    );
  });

  test(
    'applying the selected semester does not import classes from its sibling',
    () async {
      final db = FakeFirebaseFirestore();
      ScheduleService.firestoreOverride = db;
      addTearDown(() => ScheduleService.firestoreOverride = null);
      final saved = DefaultTimeSlots.createDefault(
        id: 'autumn',
        userId: 'owner',
        semester: '2026年度後期',
      );
      await db.collection('schedules').doc(saved.id).set(saved.toJson());
      final parsed = await ExcelScheduleImportService.parseWorkbookBytes(
        workbookBytes(bothSemestersWorkbook()),
      );
      await ExcelScheduleImportService.applyImport(
        scheduleId: saved.id,
        entries: parsed.semesters.last.draft.entries,
        clearExisting: true,
        autoColorAdjacent: true,
      );
      final result = (await ScheduleService.getScheduleById(saved.id))!;
      expect(result.timetable['tuesday']![1]!.subjectName, '後期特別演習');
      expect(result.timetable['tuesday']![2]!.subjectName, '後期特別演習');
      expect(
        result.timetable.values
            .expand((day) => day.values)
            .whereType<ScheduleClass>()
            .map((c) => c.subjectName)
            .toSet(),
        {'後期特別演習'},
      );
    },
  );

  // Local acceptance check; never commit a student's source workbook.
  const sourcePath = String.fromEnvironment('CIT_IMPORT_SAMPLE');
  test(
    'accepts the supplied university export',
    () async {
      final bytes = await File(sourcePath).readAsBytes();
      final draft = await ExcelScheduleImportService.parseExcelBytes(bytes);
      expectAutumnLecture(draft);
      expect(draft.entries.single.instructor, isNotEmpty);
      final workbook = await ExcelScheduleImportService.parseWorkbookBytes(
        bytes,
      );
      expect(workbook.semesters.single.label, '2026年度 後期');
      expect(workbook.semesters.single.sourceSheetNames, hasLength(2));
    },
    skip:
        sourcePath.isEmpty
            ? 'Set CIT_IMPORT_SAMPLE to verify the local source file.'
            : false,
  );
}
