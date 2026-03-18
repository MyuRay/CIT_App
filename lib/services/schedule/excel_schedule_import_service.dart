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
    String pendingCoursePrefix = '';
    for (final row in blockValues) {
      final normalized = _normalizeTitle(row);
      final piece = _continuationPiece(normalized, subject);
      if (piece.isNotEmpty) {
        subject += piece;
        pendingCoursePrefix = '';
        continue;
      }

      final inlineSuffix = _extractInlineContinuation(normalized, subject);
      if (inlineSuffix.isNotEmpty) {
        subject += inlineSuffix;
        pendingCoursePrefix = _extractCoursePrefixToken(normalized);
        continue;
      }

      final courseSuffix = _extractCourseSuffixContinuation(
        normalized,
        subject,
        pendingCoursePrefix,
      );
      if (courseSuffix.isNotEmpty) {
        subject += courseSuffix;
        pendingCoursePrefix = '';
        continue;
      }
      pendingCoursePrefix = '';

      if (_isSubjectMetaRow(normalized)) {
        break;
      }

      // タイトル直後の短い断片(例:「カー」「ス」)を補完して欠落を減らす
      if (_looksLikeSubjectFragment(normalized)) {
        subject += normalized;
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
    if (token.startsWith('律')) return token;
    if (token == '演習' || token == '実習') return token;
    if (token.startsWith('の')) return token;
    if (token.startsWith('および')) {
      return normalized.contains('演習') ? 'および演習' : token;
    }
    if (token.startsWith('び演習')) return token;
    if (token.startsWith('・')) return token;
    if (_shouldAppendTrailingNumber(current, token)) {
      return token;
    }
    return '';
  }

  static bool _shouldAppendTrailingNumber(String current, String token) {
    if (!RegExp(r'^[0-9０-９]{1,2}$').hasMatch(token)) return false;
    final compactCurrent = current.replaceAll(RegExp(r'\s+'), '');
    if (compactCurrent.isEmpty) return false;
    if (compactCurrent.endsWith(token)) return false;
    if (RegExp(r'[0-9０-９]$').hasMatch(compactCurrent)) return false;

    // 数字終端を持ちやすい科目名（例: 概論1 / 英語2 / ○○デザイン1）
    return RegExp(
      r'(概論|基礎|入門|応用|演習|実習|理論|デザイン|サイエンス|英語|数学|法|論|学)$',
    ).hasMatch(compactCurrent);
  }

  static String _extractInlineContinuation(String rowText, String current) {
    // 例: 「数理・データサイ」 + 「エンス・AI入門 経デ_P1」 =>
    // 「数理・データサイエンス・AI入門 経デ_P1」
    if (!RegExp(r'[ァ-ヶー]$').hasMatch(current)) return '';
    final token = rowText.split(RegExp(r'[ \u3000]')).first;
    if (token.isEmpty) return '';
    // 教員名(漢字開始)の誤連結を避けるため、先頭がカタカナの語のみ対象
    final matched = RegExp(r'^([ァ-ヶー][ァ-ヶー・A-Za-z0-9０-９一-龥_]{1,20})')
        .firstMatch(token);
    if (matched == null) return '';
    final suffix = matched.group(1)!;
    if (suffix.length < 2) return '';
    if (current.endsWith(suffix)) return '';
    var out = suffix;

    // 同一行に「経デ_P1」のようなサフィックスがある場合は併せて連結
    final parts = rowText.split(RegExp(r'[ \u3000]+'));
    if (parts.length >= 2 &&
        RegExp(r'^[A-Za-z一-龥々ァ-ヶー0-9０-９]+_[A-Za-z0-9]+$')
            .hasMatch(parts[1])) {
      out += ' ${parts[1]}';
    }
    return out;
  }

  static String _extractCourseSuffixContinuation(
    String rowText,
    String current,
    String pendingPrefix,
  ) {
    // 例: 「経デ_P1」が次行に単独であるケースを連結
    if (!RegExp(r'^[A-Za-z一-龥々ァ-ヶー0-9０-９]+_[A-Za-z0-9]+$')
        .hasMatch(rowText)) {
      return '';
    }
    final normalized = pendingPrefix.isNotEmpty && !rowText.startsWith(pendingPrefix)
        ? '$pendingPrefix$rowText'
        : rowText;
    if (current.contains(normalized)) return '';
    return ' $normalized';
  }

  static String _extractCoursePrefixToken(String rowText) {
    final parts = rowText.split(RegExp(r'[ \u3000]+'));
    if (parts.length < 2) return '';
    final token = parts[1];
    if (RegExp(r'^[A-Za-z一-龥々ァ-ヶー0-9０-９]{1,3}$').hasMatch(token)) {
      return token;
    }
    return '';
  }

  static String _cleanupSubject(String text) {
    var t = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    t = t.replaceAll('および演習演習', 'および演習');
    t = t.replaceAll('および演習ース', 'および演習');
    t = t.replaceAll('概論論', '概論');
    t = t.replaceAll(RegExp(r'および演習[ァ-ヶー]$'), 'および演習');
    t = t.replaceAll(RegExp(r'\s+経$'), '');
    t = t.replaceAll(RegExp(r'\s+経情$'), '');
    t = t.replaceAll(RegExp(r'\s+経情.*コース$'), '');
    t = t.replaceAll(RegExp(r'\s*[ァ-ヶーA-Za-z0-9０-９]{1,8}コース$'), '');
    t = t.replaceAll(RegExp(r'\s+コース$'), '');
    t = t.replaceAll(RegExp(r'\s+\d+年$'), '');
    return _normalizeFullWidthDigits(t.trim());
  }

  static bool _isSubjectMetaRow(String rowText) {
    final t = rowText.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.isEmpty) return true;
    if (_looksLikeInstructor(t)) return true;
    if (RegExp(r'(講義室|演習室|キャンパス|オンライン|単位|時限)').hasMatch(t)) {
      return true;
    }
    if (t.contains('[') || t.contains(']')) return true;
    if (RegExp(r'[0-9０-９]{1,2}[:：][0-9０-９]{2}').hasMatch(t)) return true;
    return false;
  }

  static bool _looksLikeSubjectFragment(String rowText) {
    final compact = rowText.replaceAll(RegExp(r'\s+'), '');
    if (compact.isEmpty) return false;
    if (compact.length > 4) return false;
    if (compact.endsWith('コース')) return false;
    if (RegExp(r'^[0-9０-９]+$').hasMatch(compact)) return false;
    if (RegExp(r'^(?:[-_・]+)$').hasMatch(compact)) return false;
    return RegExp(r'^[A-Za-z0-9０-９ぁ-んァ-ヶー]+$').hasMatch(compact);
  }

  static String _canonicalSubject(String text) {
    var t = _cleanupSubject(text);
    t = t.replaceAll(' 経情マネ', '').replaceAll(' 経情・PM', '').trim();
    return t;
  }

  static String _extractInstructor(List<String> blockValues) {
    final normalizedRows = blockValues
        .map((row) => row.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((row) => row.isNotEmpty)
        .toList();

    for (int i = 0; i < normalizedRows.length; i++) {
      final single = normalizedRows[i];
      if (_looksLikeInstructor(single)) {
        // 2行結合でより自然な講師名が作れる場合はそちらを優先
        if (i + 1 < normalizedRows.length) {
          final merged = _mergeInstructorSplit(single, normalizedRows[i + 1]);
          if (merged.isNotEmpty) return merged;
        }
        return single;
      }
      if (i + 1 < normalizedRows.length) {
        final merged = _mergeInstructorSplit(single, normalizedRows[i + 1]);
        if (merged.isNotEmpty) return merged;
      }
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
    // 科目名分割片（例: 「メント デジ」）の誤検出を避ける
    if (_looksLikeCourseFragmentPair(text)) return false;
    return RegExp(r'^[A-Za-z一-龥々]{1,8}[ 　][A-Za-z一-龥々]{1,8}$').hasMatch(text) ||
        RegExp(r'^[ァ-ヶー]{2,20}[ 　][ァ-ヶー]{1,20}$').hasMatch(text) ||
        RegExp(
          r"^[A-Za-zＡ-Ｚａ-ｚ][A-Za-zＡ-Ｚａ-ｚ'\.\-]{0,30}[ 　][A-Za-zＡ-Ｚａ-ｚ][A-Za-zＡ-Ｚａ-ｚ'\.\-]{0,30}$",
        ).hasMatch(text) ||
        RegExp(
          r'^[A-Za-zＡ-Ｚａ-ｚ][\.．][A-Za-zＡ-Ｚａ-ｚ][\.．][ 　][ァ-ヶーA-Za-zＡ-Ｚａ-ｚ一-龥々]{2,24}$',
        ).hasMatch(text);
  }

  static bool _looksLikeCourseFragmentPair(String text) {
    final parts = text.split(RegExp(r'[ \u3000]+')).where((e) => e.isNotEmpty).toList();
    if (parts.length != 2) return false;
    final first = parts[0];
    final second = parts[1];
    if (!(RegExp(r'^[ァ-ヶー]+$').hasMatch(first) && RegExp(r'^[ァ-ヶー]+$').hasMatch(second))) {
      return false;
    }
    const ngTokens = {'ネ', 'コース', 'デジ', 'マネ', 'メント', 'ジメント', 'ント'};
    if (ngTokens.contains(first) || ngTokens.contains(second)) return true;
    final combined = '$first$second';
    return combined.contains('デジ') ||
        combined.contains('マネ') ||
        combined.contains('コース') ||
        combined.contains('メント');
  }

  static String _mergeInstructorSplit(String first, String second) {
    final firstText = first.replaceAll(RegExp(r'\s+'), ' ').trim();
    final secondText = second.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (firstText.isEmpty || secondText.isEmpty) return '';

    if (_looksLikeInstructorInitialsPrefix(firstText) &&
        RegExp(r'^[ァ-ヶーA-Za-zＡ-Ｚａ-ｚ]{1,12}$').hasMatch(secondText)) {
      return '$firstText$secondText';
    }

    if (_looksLikeInstructorFragment(firstText) &&
        _looksLikeInstructorFragment(secondText)) {
      final mergedWithSpace = '$firstText $secondText';
      if (_looksLikeInstructor(mergedWithSpace)) return mergedWithSpace;
      final mergedNoSpace = '$firstText$secondText';
      if (_looksLikeInstructor(mergedNoSpace)) return mergedNoSpace;
    }
    return '';
  }

  static bool _looksLikeInstructorInitialsPrefix(String text) {
    return RegExp(
      r'^[A-Za-zＡ-Ｚａ-ｚ][\.．][A-Za-zＡ-Ｚａ-ｚ][\.．][ 　][ァ-ヶーA-Za-zＡ-Ｚａ-ｚ一-龥々]{1,20}$',
    ).hasMatch(text);
  }

  static bool _looksLikeInstructorFragment(String text) {
    if (text.isEmpty) return false;
    if (RegExp(r'[0-9０-９]').hasMatch(text)) return false;
    if (RegExp(r'(講義室|演習室|キャンパス|オンライン|単位|\[|\])').hasMatch(text)) {
      return false;
    }
    return RegExp(r"^[A-Za-zＡ-Ｚａ-ｚァ-ヶー一-龥々'\.\-]{1,24}$").hasMatch(text);
  }

  static int _findInstructorRowEndIndex(List<String> normalizedRows) {
    for (int i = 0; i < normalizedRows.length; i++) {
      final current = normalizedRows[i];
      final next = i + 1 < normalizedRows.length ? normalizedRows[i + 1] : '';
      if (_looksLikeInstructor(current)) {
        final merged = next.isEmpty ? '' : _mergeInstructorSplit(current, next);
        return merged.isNotEmpty ? i + 1 : i;
      }
      if (next.isNotEmpty && _mergeInstructorSplit(current, next).isNotEmpty) {
        return i + 1;
      }
    }
    return -1;
  }

  static String _extractClassroom(List<String> blockValues) {
    final normalizedRows = blockValues
        .map((row) => _normalizeFullWidthDigits(row.replaceAll(RegExp(r'\s+'), ' ').trim()))
        .where((row) => row.isNotEmpty)
        .toList();

    // 講師名の次行以降は教室が置かれやすいため最優先で見る
    final instructorEndIndex = _findInstructorRowEndIndex(normalizedRows);
    if (instructorEndIndex >= 0) {
      final classroomStart = instructorEndIndex + 1;
      int classroomEnd = normalizedRows.length - 1;
      for (int i = classroomStart; i < normalizedRows.length; i++) {
        if (_looksLikeCampusRow(normalizedRows[i])) {
          classroomEnd = i - 1;
          break;
        }
      }
      if (classroomStart <= classroomEnd) {
        final classroomRows = normalizedRows
            .sublist(classroomStart, classroomEnd + 1)
            .where((row) => !_looksLikeClassroomNoiseRow(row))
            .toList();

        // 範囲全体を先に連結して判定（例: 12号館6階 + 各科共用製図室）
        final mergedAll = _extractClassroomFromText(
          classroomRows.map((row) => row.replaceAll(' ', '')).join(),
        );
        if (mergedAll.isNotEmpty) return mergedAll;

        // 次に隣接2行連結で判定
        for (int i = 0; i < classroomRows.length - 1; i++) {
          final mergedNoSpace =
              '${classroomRows[i].replaceAll(' ', '')}${classroomRows[i + 1].replaceAll(' ', '')}';
          final merged = _extractClassroomFromText(mergedNoSpace);
          if (merged.isNotEmpty) return merged;
        }

        // 最後に1行単位で判定
        for (final row in classroomRows) {
          final direct = _extractClassroomFromText(row);
          if (direct.isNotEmpty) return direct;
        }
      }
    }

    // 1行で完結する教室情報を優先抽出
    for (final row in normalizedRows) {
      final direct = _extractClassroomFromText(row);
      if (direct.isNotEmpty) return direct;
    }

    // 2行に分割される教室情報（例:「12号館6階」+「各科共用製図室」）を補完
    for (int i = 0; i < normalizedRows.length - 1; i++) {
      final mergedNoSpace =
          '${normalizedRows[i].replaceAll(' ', '')}${normalizedRows[i + 1].replaceAll(' ', '')}';
      final merged = _extractClassroomFromText(mergedNoSpace);
      if (merged.isNotEmpty) return merged;
    }

    for (final row in normalizedRows) {
      final t = row.replaceAll(RegExp(r'\s+'), '');
      if (t.contains('オンライン') || (t.contains('オン') && t.contains('ライン'))) {
        return 'オンライン';
      }
    }
    return '';
  }

  static String _extractClassroomFromText(String text) {
    final t = _normalizeFullWidthDigits(text.replaceAll(RegExp(r'\s+'), ' ').trim());
    if (t.isEmpty) return '';
    final beforeSlash = t.split(RegExp(r'[／/]')).first.trim();
    if (beforeSlash.isEmpty) return '';

    final compact = beforeSlash.replaceAll(' ', '');
    final flexibleMatch = RegExp(
      r'^([0-9]{1,2})号館([0-9]{1,2})階フレキシブルワークスペース(津田沼|新習志野)?[／/]?$',
    ).firstMatch(compact);
    if (flexibleMatch != null) {
      final building = flexibleMatch.group(1)!;
      final floor = flexibleMatch.group(2)!;
      final campus = flexibleMatch.group(3);
      return campus == null
          ? '${building}号館${floor}階 フレキシブルワークスペース'
          : '${building}号館${floor}階 フレキシブルワークスペース $campus';
    }

    final patterns = <RegExp>[
      // 棟名付き（例: 食堂棟3階講義室1）
      RegExp(
        r'([A-Za-z一-龥ァ-ンー]+棟[0-9]{1,2}階[A-Za-z0-9一-龥ァ-ンー]*?(?:講義室|演習室|製図室|実験室|実習室)[0-9]{0,2})',
      ),
      // 号館・階付きの教室情報（例: 12号館6階各科共用製図室 / 食堂棟3階講義室1）
      RegExp(
        r'([0-9]{1,2}(?:号館|号棟|棟)[0-9]{1,2}階[A-Za-z0-9一-龥ァ-ンー]*?(?:講義室|演習室|製図室|実験室|実習室)[0-9]{0,2})',
      ),
      // 階のみ + 室名（例: 6階各科共用製図室）
      RegExp(
        r'([0-9]{1,2}階[A-Za-z0-9一-龥ァ-ンー]*?(?:講義室|演習室|製図室|実験室|実習室)[0-9]{0,2})',
      ),
      // 既存形式（例: 7205講義室）
      RegExp(r'([0-9A-Za-z一-龥ァ-ンー]+(?:講義室|演習室|製図室|実験室|実習室)[0-9]{0,2})'),
    ];

    for (final pattern in patterns) {
      final m = pattern.firstMatch(beforeSlash);
      if (m != null) {
        return m.group(1) ?? '';
      }
    }
    return '';
  }

  static bool _looksLikeCampusRow(String rowText) {
    final compact = rowText.replaceAll(RegExp(r'\s+'), '');
    if (compact.isEmpty) return false;
    if (compact.contains('ワークスペース') ||
        compact.contains('講義室') ||
        compact.contains('演習室') ||
        compact.contains('製図室') ||
        compact.contains('実験室') ||
        compact.contains('実習室')) {
      return false;
    }
    return compact.contains('キャンパ') || compact == 'ス';
  }

  static bool _looksLikeClassroomNoiseRow(String rowText) {
    final compact = rowText.replaceAll(RegExp(r'\s+'), '');
    return compact.isEmpty
        || compact.startsWith('[')
        || compact.contains('単位')
        || compact.contains('複数回');
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
