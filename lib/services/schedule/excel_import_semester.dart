import '../../models/schedule/academic_year_model.dart';
import 'excel_timetable_layout.dart';

/// Only the printed header identifies a semester; page order does not.
class ExcelImportSemester {
  const ExcelImportSemester({this.year, this.semester});

  final int? year;
  final AcademicSemester? semester;

  String get key => '${year ?? "unknown"}_${semester?.key ?? "unknown"}';
  String get label =>
      '${year == null ? "" : "$year年度 "}${semester?.displayName ?? "学期不明"}';

  static ExcelImportSemester read(ExcelTimetableLayout layout) {
    final headerEnd =
        layout.headerRow >= 0
            ? layout.headerRow
            : layout.periodAnchors.keys.first;
    final cells = layout.rows
        .take(headerEnd)
        .expand((row) => row)
        .map((cell) => cell?.value?.toString() ?? '');
    return fromHeader(cells.join('\n'));
  }

  static ExcelImportSemester fromHeader(String header) {
    var normalized = header.replaceAll(RegExp(r'[ \u3000\t]'), '');
    const full = '０１２３４５６７８９';
    for (var digit = 0; digit < full.length; digit++) {
      normalized = normalized.replaceAll(full[digit], '$digit');
    }
    final years =
        RegExp(r'(\d{4})年度?')
            .allMatches(normalized)
            .map((match) => int.parse(match.group(1)!))
            .toSet();
    final terms = <AcademicSemester>{};
    for (final match in RegExp(r'前期|後期|春学期|秋学期').allMatches(normalized)) {
      terms.add(
        match[0] == '前期' || match[0] == '春学期'
            ? AcademicSemester.firstSemester
            : AcademicSemester.secondSemester,
      );
    }
    return ExcelImportSemester(
      year: years.length == 1 ? years.single : null,
      semester: terms.length == 1 ? terms.single : null,
    );
  }
}
