import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../models/schedule/schedule_model.dart';
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

class ExcelScheduleImportService {
  static const Map<String, int> _dayStartColumns = {
    'monday': 14, // O
    'tuesday': 35, // AJ
    'wednesday': 56, // BE
    'thursday': 77, // BZ
    'friday': 98, // CU
    'saturday': 119, // DP
  };

  static const Map<String, String> _dayLabels = {
    'monday': '月',
    'tuesday': '火',
    'wednesday': '水',
    'thursday': '木',
    'friday': '金',
    'saturday': '土',
  };

  static Future<ScheduleImportDraft> parseExcelBytes(Uint8List bytes) async {
    final warnings = <String>[];
    final byKey = <String, ImportedScheduleEntry>{};

    final excel = Excel.decodeBytes(bytes);
    for (final sheetName in excel.tables.keys) {
      if (sheetName != 'Sheet1' && sheetName != 'Sheet2') {
        continue;
      }
      final sheet = excel.tables[sheetName];
      if (sheet == null) continue;

      final periodAnchorMap = _collectPeriodAnchorMap(sheet);
      if (periodAnchorMap.isEmpty) {
        warnings.add('$sheetName: 時限アンカー(1-10)を検出できませんでした。');
        continue;
      }
      final anchorRows = periodAnchorMap.keys.toList()..sort();

      final rows = sheet.maxRows;
      for (final dayEntry in _dayStartColumns.entries) {
        final weekdayKey = dayEntry.key;
        final col = dayEntry.value;

        for (final startRow in anchorRows) {
          final title = _cellText(sheet, col, startRow);
          if (!_isLikelyLectureTitle(title)) {
            continue;
          }

          final period = _periodFromAnchorRow(periodAnchorMap, startRow);
          if (period == null) continue;

          final endRow = _blockEndRow(anchorRows, startRow, rows);
          final blockValues = <String>[];
          for (int r = startRow + 1; r <= endRow; r++) {
            final v = _cellText(sheet, col, r);
            if (v.isNotEmpty) {
              blockValues.add(v);
            }
          }

          final subject = _buildSubject(title, blockValues);
          if (subject.isEmpty) continue;
          final instructor = _extractInstructor(blockValues);
          final classroom = _extractClassroom(blockValues);

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
      warnings.add('有効な講義データを抽出できませんでした。');
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

    final updated = clearExisting
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
        warnings.add('${e.subjectName}: ${e.startPeriod}限開始で${e.duration}コマは範囲外です。');
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
      final color = autoColorAdjacent
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

  static Map<int, int> _collectPeriodAnchorMap(Sheet sheet) {
    final rows = sheet.maxRows;
    final anchors = <int, int>{};
    const iCol = 8; // I
    for (int r = 0; r < rows; r++) {
      final t = _cellText(sheet, iCol, r);
      final n = int.tryParse(t);
      if (n != null && n >= 1 && n <= 10) {
        anchors[r] = n;
      }
    }
    return anchors;
  }

  static int? _periodFromAnchorRow(Map<int, int> anchors, int row) {
    final anchorRows = anchors.keys.toList()..sort();
    int? nearest;
    for (final r in anchorRows) {
      if (r <= row) nearest = r;
      if (r > row) break;
    }
    if (nearest == null) return null;
    return anchors[nearest];
  }

  static int _blockEndRow(List<int> anchors, int row, int maxRows) {
    final next = anchors.where((r) => r > row);
    if (next.isEmpty) {
      return (row + 12 < maxRows) ? row + 12 : maxRows - 1;
    }
    final end = next.first - 1;
    return end > row ? end : row;
  }

  static String _cellText(Sheet sheet, int col, int row) {
    final data = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .value;
    if (data == null) return '';
    final s = data.toString().trim();
    return s == 'null' ? '' : s;
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

  static String _buildSubject(String title, List<String> blockValues) {
    String subject = _normalizeTitle(title);
    for (final row in blockValues) {
      final piece = _continuationPiece(row, subject);
      if (piece.isNotEmpty) {
        subject += piece;
      }
    }
    return _cleanupSubject(subject);
  }

  static String _normalizeTitle(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _continuationPiece(String rowText, String current) {
    final normalized = rowText.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return '';
    final token = normalized.split(RegExp(r'[ \u3000]')).first;
    if (token == '論') return token;
    if (token == '演習' || token == '実習') return token;
    if (token.startsWith('および')) {
      return normalized.contains('演習') ? 'および演習' : token;
    }
    if (token.startsWith('び演習')) return token;
    if (token.startsWith('・')) return token;
    if (current.contains('キャリアデザイン') &&
        RegExp(r'^[0-9０-９]+$').hasMatch(token)) {
      return token;
    }
    return '';
  }

  static String _cleanupSubject(String text) {
    var t = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    t = t.replaceAll('および演習演習', 'および演習');
    t = t.replaceAll(RegExp(r'\s+経情.*コース$'), '');
    t = t.replaceAll(RegExp(r'\s+コース$'), '');
    t = t.replaceAll(RegExp(r'\s+\d+年$'), '');
    return _normalizeFullWidthDigits(t.trim());
  }

  static String _canonicalSubject(String text) {
    var t = _cleanupSubject(text);
    t = t.replaceAll(' 経情マネ', '').replaceAll(' 経情・PM', '').trim();
    return t;
  }

  static String _extractInstructor(List<String> blockValues) {
    for (final row in blockValues) {
      final t = row.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (_looksLikeInstructor(t)) return t;
    }
    return '';
  }

  static bool _looksLikeInstructor(String text) {
    if (text.isEmpty) return false;
    const ng = [
      '講義室',
      '演習室',
      'キャンパス',
      'オンライン',
      '単位',
      '[',
      ']',
      'コース',
      '時限',
      '09:00',
      '10:00',
      '／',
    ];
    if (ng.any(text.contains)) return false;
    return RegExp(r'^[A-Za-z一-龥々]{1,8}[ 　][A-Za-z一-龥々]{1,8}$')
        .hasMatch(text);
  }

  static String _extractClassroom(List<String> blockValues) {
    for (final row in blockValues) {
      final t = row.replaceAll(RegExp(r'\s+'), ' ').trim();
      final m = RegExp(r'([０-９0-9A-Za-z一-龥ァ-ンー]+(?:講義室|演習室))')
          .firstMatch(t);
      if (m != null) return _normalizeFullWidthDigits(m.group(1)!);
    }
    for (final row in blockValues) {
      final t = row.replaceAll(RegExp(r'\s+'), '');
      if (t.contains('オンライン') || (t.contains('オン') && t.contains('ライン'))) {
        return 'オンライン';
      }
    }
    return '';
  }

  static String _normalizeFullWidthDigits(String input) {
    const full = '０１２３４５６７８９';
    const half = '0123456789';
    var out = input;
    for (int i = 0; i < full.length; i++) {
      out = out.replaceAll(full[i], half[i]);
    }
    return out;
  }

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
    for (int i = 0; i < duration; i++) {
      final period = startPeriod + i;

      final leftDay =
          (dayIndex > 0) ? dayOrder[dayIndex - 1] : null;
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

    for (final color in palette) {
      if (!neighborColors.contains(color)) {
        return color;
      }
    }
    return palette.first;
  }
}
