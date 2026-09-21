import 'package:excel/excel.dart';

import 'excel_lecture_fields.dart';

/// Locates the printed timetable without depending on an export's column widths.
class ExcelTimetableLayout {
  ExcelTimetableLayout._({
    required this.rows,
    required this.headerRow,
    required this.periodColumn,
    required this.dayColumns,
    required this.periodAnchors,
    required this.endRow,
  });

  final List<List<Data?>> rows;
  final int headerRow;
  final int periodColumn;
  final Map<String, int> dayColumns;
  final Map<int, int> periodAnchors;
  // Exclusive: campus legends and untimed courses must not enter the last slot.
  final int endRow;

  static const dayLabels = {
    'monday': '月',
    'tuesday': '火',
    'wednesday': '水',
    'thursday': '木',
    'friday': '金',
    'saturday': '土',
  };

  static ExcelTimetableLayout? detect(Sheet sheet) {
    final rows = sheet.rows;
    for (var row = 0; row < rows.length; row++) {
      final columns = <String, int>{};
      for (var col = 0; col < rows[row].length; col++) {
        final text = cellText(rows, col, row).replaceAll(RegExp(r'\s+'), '');
        for (final day in dayLabels.entries) {
          if (text == day.value ||
              text == '${day.value}曜' ||
              text == '${day.value}曜日') {
            columns[day.key] = col;
          }
        }
      }
      // Multiple labelled days distinguish a timetable from arbitrary numbers.
      if (columns.length < 2) continue;
      final firstDayColumn = columns.values.reduce((a, b) => a < b ? a : b);
      ExcelTimetableLayout? best;
      for (var col = firstDayColumn - 1; col >= 0; col--) {
        final candidate = _at(rows, row, col, columns);
        if (candidate != null &&
            (best == null ||
                candidate.periodAnchors.length > best.periodAnchors.length)) {
          best = candidate;
        }
      }
      if (best != null) return best;
    }

    // Keep accepting historical university files lacking readable day headers.
    if (RegExp(r'^Sheet[1-4]$').hasMatch(sheet.sheetName)) {
      return _at(rows, -1, 8, const {
        'monday': 14,
        'tuesday': 35,
        'wednesday': 56,
        'thursday': 77,
        'friday': 98,
        'saturday': 119,
      });
    }
    return null;
  }

  static ExcelTimetableLayout? _at(
    List<List<Data?>> rows,
    int headerRow,
    int periodColumn,
    Map<String, int> dayColumns,
  ) {
    final anchors = <int, int>{};
    var endRow = rows.length;
    var previousPeriod = 0;
    for (var row = headerRow + 1; row < rows.length; row++) {
      final label = cellText(rows, periodColumn, row);
      if (isTableFooter(label)) {
        endRow = row;
        break;
      }
      final period = _parsePeriod(label);
      if (period == null) continue;
      // A new table or a summary below this one must not become a second slot.
      if (period <= previousPeriod) {
        endRow = row;
        break;
      }
      anchors[row] = period;
      previousPeriod = period;
    }
    if (anchors.isEmpty) return null;
    return ExcelTimetableLayout._(
      rows: rows,
      headerRow: headerRow,
      periodColumn: periodColumn,
      dayColumns: dayColumns,
      periodAnchors: anchors,
      endRow: endRow,
    );
  }

  int blockEndRow(int startRow) {
    for (final row in periodAnchors.keys) {
      if (row > startRow) return row - 1;
    }
    return endRow - 1;
  }

  /// A printed period label can be below the first wrapped title line. Only
  /// move a boundary after the preceding lecture's unit count; never
  /// infer continuity from a shared teacher, classroom or title suffix.
  Iterable<({int period, List<String> values})> lectureBlocks(
    int column,
  ) sync* {
    final anchors = periodAnchors.keys.toList();
    final starts = List<int>.from(anchors);
    for (var index = 1; index < anchors.length; index++) {
      var afterFooter = false;
      int? titleStart;
      for (var row = anchors[index - 1] + 1; row < anchors[index]; row++) {
        final value = text(column, row);
        if (value.isEmpty) continue;
        if (ExcelLectureFields.isFooterRow(value)) {
          // An annotation such as "[定員有]" can itself wrap across rows.
          // Only the final unit count proves that a following line is a title.
          afterFooter = ExcelLectureFields.isUnitCountRow(value);
          titleStart = null;
        } else if (afterFooter) {
          titleStart ??= row;
        }
      }
      if (titleStart != null) starts[index] = titleStart;
    }

    for (var index = 0; index < anchors.length; index++) {
      final end = index + 1 < starts.length ? starts[index + 1] : endRow;
      yield (
        period: periodAnchors[anchors[index]]!,
        values: [
          for (var row = starts[index]; row < end; row++)
            if (text(column, row).isNotEmpty) text(column, row),
        ],
      );
    }
  }

  String text(int col, int row) => cellText(rows, col, row);

  static String cellText(List<List<Data?>> rows, int col, int row) {
    if (row < 0 || row >= rows.length || col < 0 || col >= rows[row].length) {
      return '';
    }
    return rows[row][col]?.value?.toString().trim() ?? '';
  }

  static bool isTableFooter(String text) =>
      text.contains('集中講義') ||
      text.contains('集中科目') ||
      text.contains('時間割外') ||
      (text.contains('キャンパス') && RegExp(r'[0-9０-９]+限').hasMatch(text));

  static int? _parsePeriod(String text) {
    var normalized = text.replaceAll(RegExp(r'\s+'), '');
    const full = '０１２３４５６７８９';
    for (var digit = 0; digit < full.length; digit++) {
      normalized = normalized.replaceAll(full[digit], '$digit');
    }
    final match = RegExp(
      r'^(?:第)?(10|[1-9])(?:時限|限)?(?:\.0)?$',
    ).firstMatch(normalized);
    return match == null ? null : int.parse(match.group(1)!);
  }
}
