import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'excel_schedule_import_service.dart';
import 'excel_timetable_layout.dart';

class ExcelImportFeedbackService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<void> submitTrainingSample({
    required String userId,
    required Uint8List excelBytes,
    required List<String> sourceSheetNames,
    required List<ImportedScheduleEntry> autoExtractedEntries,
    required List<ImportedScheduleEntry> reviewedEntries,
    required List<String> parserWarnings,
  }) async {
    final now = DateTime.now();
    final millis = now.millisecondsSinceEpoch;
    final docId = '${userId}_$millis';
    // University filenames can contain a student number as well.
    const safeFileName = 'timetable.xlsx';
    final storagePath = 'excel_import_training/$userId/${docId}_$safeFileName';
    final maskedExcelBytes = prepareTrainingWorkbook(
      excelBytes,
      sourceSheetNames: sourceSheetNames,
    );

    final ref = _storage.ref().child(storagePath);
    final metadata = SettableMetadata(
      contentType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      customMetadata: {
        'source': 'excel_import_training',
        'userId': userId,
        'submittedAt': now.toIso8601String(),
        'privacyFilter': 'timetable_cells_only_v2',
      },
    );
    await ref.putData(maskedExcelBytes, metadata);
    final downloadUrl = await ref.getDownloadURL();

    await _firestore
        .collection('excel_import_training_submissions')
        .doc(docId)
        .set({
          'userId': userId,
          'originalFileName': safeFileName,
          'storagePath': storagePath,
          'storageUrl': downloadUrl,
          'consentForTraining': true,
          'privacyFilter': 'timetable_cells_only_v2',
          'providedAt': Timestamp.fromDate(now),
          'autoEntryCount': autoExtractedEntries.length,
          'reviewedEntryCount': reviewedEntries.length,
          'parserWarnings': parserWarnings,
          'autoExtractedEntries':
              autoExtractedEntries.map(_entryToMap).toList(),
          'reviewedEntries': reviewedEntries.map(_entryToMap).toList(),
        });
  }

  static Map<String, dynamic> _entryToMap(ImportedScheduleEntry entry) {
    return {
      'subjectName': entry.subjectName,
      'instructor': entry.instructor,
      'classroom': entry.classroom,
      'weekdayKey': entry.weekdayKey,
      'startPeriod': entry.startPeriod,
      'duration': entry.duration,
    };
  }

  /// Rebuilds only the timetable cells; original headers, shared strings,
  /// sheet names, document properties and unrelated sheets are never copied.
  static Uint8List prepareTrainingWorkbook(
    Uint8List excelBytes, {
    List<String>? sourceSheetNames,
  }) {
    final source = Excel.decodeBytes(excelBytes);
    final output = Excel.createExcel();
    var sheetCount = 0;
    for (final sheet in source.tables.values) {
      if (sourceSheetNames != null &&
          !sourceSheetNames.contains(sheet.sheetName)) {
        continue;
      }
      final layout = ExcelTimetableLayout.detect(sheet);
      if (layout == null) continue;
      final target = output['Sheet${++sheetCount}'];
      final firstRow = layout.periodAnchors.keys.first;
      final headerRow = layout.headerRow >= 0 ? layout.headerRow : firstRow - 1;
      // Keep relative row/column positions so wrapped text remains useful for
      // parser feedback, but copy values into a fresh workbook as literal text.
      void put(int column, int row, String value) {
        target
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: column,
                rowIndex: row - headerRow,
              ),
            )
            .value = TextCellValue(value);
      }

      for (final day in layout.dayColumns.entries) {
        put(
          day.value,
          headerRow,
          '${ExcelTimetableLayout.dayLabels[day.key]}曜日',
        );
      }
      for (final anchor in layout.periodAnchors.entries) {
        put(layout.periodColumn, anchor.key, '${anchor.value}');
        for (final column in layout.dayColumns.values) {
          // A blank period-label row can still have a wrapped lecture below it.
          // Preserve the full slot so the normal parser can recover boundaries.
          for (
            var row = anchor.key;
            row <= layout.blockEndRow(anchor.key);
            row++
          ) {
            final value = layout.text(column, row);
            if (value.isNotEmpty) put(column, row, value);
          }
        }
      }
    }
    if (sheetCount == 0) {
      throw const FormatException('時間割を確認できないためデータを提供できません。');
    }
    final encoded = output.encode();
    if (encoded == null) {
      throw StateError('個人情報を除いたExcelの作成に失敗しました。');
    }
    return Uint8List.fromList(encoded);
  }
}
