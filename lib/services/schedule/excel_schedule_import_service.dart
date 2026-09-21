import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../models/schedule/schedule_model.dart';
import 'excel_import_semester.dart';
import 'excel_lecture_fields.dart';
import 'excel_timetable_layout.dart';
import 'schedule_service.dart';

class ImportedScheduleEntry {
  const ImportedScheduleEntry({
    required this.subjectName,
    required this.instructor,
    required this.classroom,
    required this.weekdayKey,
    required this.startPeriod,
    required this.duration,
  });

  final String subjectName;
  final String instructor;
  final String classroom;
  final String weekdayKey;
  final int startPeriod;
  final int duration;

  ImportedScheduleEntry copyWith({
    String? subjectName,
    String? instructor,
    String? classroom,
    String? weekdayKey,
    int? startPeriod,
    int? duration,
  }) {
    return ImportedScheduleEntry(
      subjectName: subjectName ?? this.subjectName,
      instructor: instructor ?? this.instructor,
      classroom: classroom ?? this.classroom,
      weekdayKey: weekdayKey ?? this.weekdayKey,
      startPeriod: startPeriod ?? this.startPeriod,
      duration: duration ?? this.duration,
    );
  }
}

class ScheduleImportDraft {
  const ScheduleImportDraft({required this.entries, required this.warnings});

  final List<ImportedScheduleEntry> entries;
  final List<String> warnings;
}

class ScheduleImportResult {
  const ScheduleImportResult({
    required this.appliedCount,
    required this.warnings,
  });

  final int appliedCount;
  final List<String> warnings;
}

class SemesterScheduleImport {
  const SemesterScheduleImport({
    required this.semester,
    required this.sourceSheetNames,
    required this.draft,
    required this.label,
  });

  final ExcelImportSemester semester;
  final List<String> sourceSheetNames;
  final ScheduleImportDraft draft;
  final String label;
}

class ScheduleWorkbookImport {
  const ScheduleWorkbookImport({required this.semesters});
  final List<SemesterScheduleImport> semesters;
}

class _ImportPage {
  _ImportPage(this.name, this.layout)
    : semester = ExcelImportSemester.read(layout);
  final String name;
  final ExcelTimetableLayout layout;
  final ExcelImportSemester semester;
}

class ExcelScheduleImportService {
  static const Map<String, String> _dayLabels = {
    'monday': '月',
    'tuesday': '火',
    'wednesday': '水',
    'thursday': '木',
    'friday': '金',
    'saturday': '土',
  };

  static Future<ScheduleImportDraft> parseExcelBytes(Uint8List bytes) async {
    final workbook = await parseWorkbookBytes(bytes);
    if (workbook.semesters.length > 1) {
      throw const FormatException('複数の学期が含まれています。取り込む学期を選択してください。');
    }
    if (workbook.semesters.isEmpty) {
      return const ScheduleImportDraft(
        entries: [],
        warnings: ['曜日・時限のある講義が見つかりませんでした。大学の学生時間割表（Excel形式）を選択してください。'],
      );
    }
    return workbook.semesters.single.draft;
  }

  static Future<ScheduleWorkbookImport> parseWorkbookBytes(
    Uint8List bytes,
  ) async {
    final excel = Excel.decodeBytes(bytes);
    final pages = <_ImportPage>[];
    for (final sheet in excel.tables.values) {
      final layout = ExcelTimetableLayout.detect(sheet);
      if (layout != null) pages.add(_ImportPage(sheet.sheetName, layout));
    }
    final groups = <List<_ImportPage>>[];
    for (final page in pages) {
      List<_ImportPage>? group;
      if (page.semester.semester != null) {
        for (final existing in groups) {
          if (existing.first.semester.key == page.semester.key) {
            group = existing;
            break;
          }
        }
      } else {
        // A headerless continuation can join only one unambiguous preceding
        // page range. Repeated periods start a separate, explicitly unknown term.
        final firstPeriod = page.layout.periodAnchors.values.first;
        final candidates =
            groups
                .where(
                  (existing) =>
                      existing.last.layout.periodAnchors.values.last <
                          firstPeriod &&
                      (page.semester.year == null ||
                          existing.first.semester.year == page.semester.year),
                )
                .toList();
        if (candidates.length == 1) group = candidates.single;
      }
      if (group == null) {
        groups.add([page]);
      } else {
        group.add(page);
      }
    }
    final semesters = <SemesterScheduleImport>[];
    for (var index = 0; index < groups.length; index++) {
      final group = groups[index];
      final semester = group.first.semester;
      final draft = _parsePages(group);
      final label =
          semester.semester == null
              ? '${semester.label}（候補${index + 1}）'
              : semester.label;
      semesters.add(
        SemesterScheduleImport(
          semester: semester,
          sourceSheetNames: List.unmodifiable(group.map((page) => page.name)),
          label: label,
          draft: ScheduleImportDraft(
            entries: draft.entries,
            warnings: [
              if (semester.semester == null)
                '学期の見出しを判別できませんでした。講義内容と取り込み先を確認してください。',
              ...draft.warnings,
            ],
          ),
        ),
      );
    }
    // Known terms follow academic-year order, regardless of Excel tab order.
    semesters.sort((a, b) {
      final years = (a.semester.year ?? 9999).compareTo(
        b.semester.year ?? 9999,
      );
      if (years != 0) return years;
      final termOrder = (a.semester.semester?.index ?? 99).compareTo(
        b.semester.semester?.index ?? 99,
      );
      return termOrder != 0 ? termOrder : a.label.compareTo(b.label);
    });
    return ScheduleWorkbookImport(semesters: semesters);
  }

  static ScheduleImportDraft _parsePages(List<_ImportPage> pages) {
    final warnings = <String>[];
    final byKey = <String, ImportedScheduleEntry>{};

    for (final page in pages) {
      final layout = page.layout;
      _addUntimedCourseWarnings(layout, warnings);

      for (final dayEntry in layout.dayColumns.entries) {
        final weekdayKey = dayEntry.key;
        final col = dayEntry.value;

        for (final block in layout.lectureBlocks(col)) {
          if (block.values.isEmpty ||
              !_isLikelyLectureTitle(block.values.first)) {
            continue;
          }

          final period = block.period;
          final fields = ExcelLectureFields.parse(block.values);
          final subject = fields.subjectName;
          if (subject.isEmpty) continue;
          final instructor = fields.instructor;
          final classroom = fields.classroom;
          if (instructor.isEmpty) {
            final warning =
                '「$subject」の担当教員は未記載・非公開、または判別できませんでした。取り込み前に確認してください。';
            if (!warnings.contains(warning)) warnings.add(warning);
          }

          final key = '$weekdayKey|$period|${_canonicalSubject(subject)}';
          final candidate = ImportedScheduleEntry(
            subjectName: subject,
            instructor: instructor,
            classroom: classroom,
            weekdayKey: weekdayKey,
            startPeriod: period,
            duration: 1,
          );

          final prev = byKey[key];
          if (prev == null) {
            byKey[key] = candidate;
          } else {
            // 情報量が多い方を採用
            final prevScore =
                (prev.instructor.isNotEmpty ? 1 : 0) +
                (prev.classroom.isNotEmpty ? 1 : 0);
            final nextScore =
                (candidate.instructor.isNotEmpty ? 1 : 0) +
                (candidate.classroom.isNotEmpty ? 1 : 0);
            if (nextScore > prevScore) {
              byKey[key] = candidate;
            }
          }
        }
      }
    }

    final merged = _mergeConsecutive(byKey.values.toList());
    if (merged.isEmpty) {
      warnings.add('曜日・時限のある講義が見つかりませんでした。大学の学生時間割表（Excel形式）を選択してください。');
    }
    return ScheduleImportDraft(entries: merged, warnings: warnings);
  }

  static Future<ScheduleImportResult> applyImport({
    required String scheduleId,
    required List<ImportedScheduleEntry> entries,
    required bool clearExisting,
    required bool autoColorAdjacent,
  }) async {
    final warnings = <String>[];
    final schedule = await ScheduleService.getScheduleById(scheduleId);
    if (schedule == null) {
      throw Exception('時間割が見つかりません');
    }

    final updated =
        clearExisting
            ? DefaultTimeSlots.createEmptyTimetable()
            : _copyTimetable(schedule.timetable);

    int applied = 0;
    for (final e in entries) {
      if (e.subjectName.trim().isEmpty) {
        warnings.add('空の講義名エントリをスキップしました。');
        continue;
      }
      if (e.startPeriod < 1 || e.startPeriod > 10 || e.duration < 1) {
        warnings.add('${e.subjectName}: 時限情報が不正なためスキップしました。');
        continue;
      }
      final end = e.startPeriod + e.duration - 1;
      if (end > 10) {
        warnings.add(
          '${e.subjectName}: ${e.startPeriod}限開始で${e.duration}コマは範囲外です。',
        );
        continue;
      }
      if (!updated.containsKey(e.weekdayKey)) {
        warnings.add('${e.subjectName}: 曜日キー(${e.weekdayKey})が不正です。');
        continue;
      }

      _removeOverlappingClasses(
        timetable: updated,
        weekdayKey: e.weekdayKey,
        startPeriod: e.startPeriod,
        endPeriod: end,
      );

      final classId = DateTime.now().microsecondsSinceEpoch.toString();
      final color =
          autoColorAdjacent
              ? _pickColorForEntry(
                timetable: updated,
                weekdayKey: e.weekdayKey,
                startPeriod: e.startPeriod,
                duration: e.duration,
              )
              : '#2196F3';
      for (int i = 0; i < e.duration; i++) {
        final period = e.startPeriod + i;
        updated[e.weekdayKey]![period] = ScheduleClass(
          id: classId,
          subjectName: e.subjectName.trim(),
          classroom: e.classroom.trim(),
          instructor: e.instructor.trim(),
          color: color,
          duration: e.duration,
          isStartCell: i == 0,
        );
      }
      applied++;
    }

    final newSchedule = Schedule(
      id: schedule.id,
      userId: schedule.userId,
      name: schedule.name,
      semester: schedule.semester,
      timetable: updated,
      timeSlots: schedule.timeSlots,
      createdAt: schedule.createdAt,
      updatedAt: DateTime.now(),
    );
    await ScheduleService.updateSchedule(newSchedule);
    return ScheduleImportResult(appliedCount: applied, warnings: warnings);
  }

  static void _addUntimedCourseWarnings(
    ExcelTimetableLayout layout,
    List<String> warnings,
  ) {
    var inUntimedSection = false;
    for (var row = layout.endRow; row < layout.rows.length; row++) {
      final text = layout.text(layout.periodColumn, row);
      if (text.contains('集中講義') || text.contains('集中科目')) {
        inUntimedSection = true;
        continue;
      }
      if (!inUntimedSection || text.isEmpty || text.contains('授業科目')) {
        continue;
      }
      if (_isLikelyLectureTitle(text)) {
        final title = text.replaceAll(RegExp(r'\s*\[.*?\]'), '').trim();
        final warning = '集中講義「$title」は曜日・時限がないため取り込んでいません。必要に応じて手動で追加してください。';
        if (!warnings.contains(warning)) warnings.add(warning);
      }
    }
  }

  static bool _isLikelyLectureTitle(String text) {
    if (text.isEmpty) return false;
    if (text.contains('講義室') ||
        text.contains('演習室') ||
        text.contains('キャンパス') ||
        text.contains('教員') ||
        text.contains('教授') ||
        text.contains('講師') ||
        text.contains('単位') ||
        text == '1' ||
        text == '2' ||
        text == '3' ||
        text == '4' ||
        text == '5' ||
        text == '6' ||
        text == '7' ||
        text == '8' ||
        text == '9' ||
        text == '10') {
      return false;
    }
    return true;
  }

  static String _canonicalSubject(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim();
  static List<ImportedScheduleEntry> _mergeConsecutive(
    List<ImportedScheduleEntry> entries,
  ) {
    final grouped = <String, List<ImportedScheduleEntry>>{};
    for (final e in entries) {
      final key =
          '${e.weekdayKey}|${_canonicalSubject(e.subjectName)}|${e.instructor}|${e.classroom}';
      grouped.putIfAbsent(key, () => []).add(e);
    }

    final merged = <ImportedScheduleEntry>[];
    for (final list in grouped.values) {
      list.sort((a, b) => a.startPeriod.compareTo(b.startPeriod));
      int start = list.first.startPeriod;
      int prev = list.first.startPeriod;
      final first = list.first;

      for (int i = 1; i < list.length; i++) {
        final p = list[i].startPeriod;
        if (p == prev + 1) {
          prev = p;
          continue;
        }
        merged.add(
          first.copyWith(startPeriod: start, duration: prev - start + 1),
        );
        start = p;
        prev = p;
      }
      merged.add(
        first.copyWith(startPeriod: start, duration: prev - start + 1),
      );
    }

    merged.sort((a, b) {
      final dayOrder = _dayLabels.keys.toList();
      final da = dayOrder.indexOf(a.weekdayKey);
      final db = dayOrder.indexOf(b.weekdayKey);
      if (da != db) return da.compareTo(db);
      return a.startPeriod.compareTo(b.startPeriod);
    });
    return merged;
  }

  static Map<String, Map<int, ScheduleClass?>> _copyTimetable(
    Map<String, Map<int, ScheduleClass?>> timetable,
  ) {
    final copied = <String, Map<int, ScheduleClass?>>{};
    for (final day in timetable.entries) {
      copied[day.key] = <int, ScheduleClass?>{};
      for (final p in day.value.entries) {
        copied[day.key]![p.key] = p.value;
      }
    }
    return copied;
  }

  static void _removeOverlappingClasses({
    required Map<String, Map<int, ScheduleClass?>> timetable,
    required String weekdayKey,
    required int startPeriod,
    required int endPeriod,
  }) {
    final day = timetable[weekdayKey];
    if (day == null) return;

    final affectedIds = <String>{};
    for (int p = startPeriod; p <= endPeriod; p++) {
      final existing = day[p];
      if (existing != null) affectedIds.add(existing.id);
    }
    if (affectedIds.isEmpty) return;

    for (final entry in day.entries.toList()) {
      if (entry.value != null && affectedIds.contains(entry.value!.id)) {
        day[entry.key] = null;
      }
    }
  }

  static String _pickColorForEntry({
    required Map<String, Map<int, ScheduleClass?>> timetable,
    required String weekdayKey,
    required int startPeriod,
    required int duration,
  }) {
    const palette = <String>[
      '#42A5F5',
      '#66BB6A',
      '#FFA726',
      '#AB47BC',
      '#26A69A',
      '#EC407A',
      '#5C6BC0',
      '#D4E157',
      '#8D6E63',
      '#29B6F6',
    ];

    final dayOrder = <String>[
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
    ];
    final dayIndex = dayOrder.indexOf(weekdayKey);

    final neighborColors = <String>{};
    final usedInSameDayColors = <String>{};

    // 同じ曜日では隣接していなくても同色を避ける
    final sameDay = timetable[weekdayKey];
    if (sameDay != null) {
      for (final c in sameDay.values) {
        if (c != null && c.color.isNotEmpty) {
          usedInSameDayColors.add(c.color);
        }
      }
    }

    for (int i = 0; i < duration; i++) {
      final period = startPeriod + i;

      final leftDay = (dayIndex > 0) ? dayOrder[dayIndex - 1] : null;
      final rightDay =
          (dayIndex >= 0 && dayIndex < dayOrder.length - 1)
              ? dayOrder[dayIndex + 1]
              : null;

      void collectColor(String? day, int p) {
        if (day == null) return;
        final c = timetable[day]?[p];
        if (c != null && c.color.isNotEmpty) {
          neighborColors.add(c.color);
        }
      }

      collectColor(leftDay, period); // 左
      collectColor(rightDay, period); // 右
      collectColor(weekdayKey, period - 1); // 上
      collectColor(weekdayKey, period + 1); // 下
    }

    final blockedColors = <String>{...neighborColors, ...usedInSameDayColors};
    for (final color in palette) {
      if (!blockedColors.contains(color)) {
        return color;
      }
    }
    return palette.first;
  }
}
