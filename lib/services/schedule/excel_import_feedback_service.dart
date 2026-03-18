import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'excel_schedule_import_service.dart';

class ExcelImportFeedbackService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<void> submitTrainingSample({
    required String userId,
    required String originalFileName,
    required Uint8List excelBytes,
    required List<ImportedScheduleEntry> autoExtractedEntries,
    required List<ImportedScheduleEntry> reviewedEntries,
    required List<String> parserWarnings,
  }) async {
    final now = DateTime.now();
    final millis = now.millisecondsSinceEpoch;
    final docId = '${userId}_$millis';
    final safeFileName = _sanitizeFileName(originalFileName);
    final storagePath = 'excel_import_training/$userId/${docId}_$safeFileName';
    final maskedExcelBytes = _maskExcelBytesFixedCells(excelBytes);

    final ref = _storage.ref().child(storagePath);
    final metadata = SettableMetadata(
      contentType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      customMetadata: {
        'source': 'excel_import_training',
        'userId': userId,
        'submittedAt': now.toIso8601String(),
        'maskedCells': 'Sheet1!I4,Sheet1!AG4,Sheet2!I4,Sheet2!AG4',
      },
    );
    await ref.putData(maskedExcelBytes, metadata);
    final downloadUrl = await ref.getDownloadURL();

    await _firestore.collection('excel_import_training_submissions').doc(docId).set({
      'userId': userId,
      'originalFileName': originalFileName,
      'storagePath': storagePath,
      'storageUrl': downloadUrl,
      'consentForTraining': true,
      'excelMaskedByFixedCells': true,
      'maskedCells': ['Sheet1!I4', 'Sheet1!AG4', 'Sheet2!I4', 'Sheet2!AG4'],
      'providedAt': Timestamp.fromDate(now),
      'autoEntryCount': autoExtractedEntries.length,
      'reviewedEntryCount': reviewedEntries.length,
      'parserWarnings': parserWarnings,
      'autoExtractedEntries': autoExtractedEntries.map(_entryToMap).toList(),
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

  static String _sanitizeFileName(String fileName) {
    final trimmed = fileName.trim();
    if (trimmed.isEmpty) return 'unknown.xlsx';
    return trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  static Uint8List _maskExcelBytesFixedCells(Uint8List excelBytes) {
    final excel = Excel.decodeBytes(excelBytes);

    const targets = <String>['Sheet1', 'Sheet2'];
    for (final name in targets) {
      final sheet = excel.tables[name];
      if (sheet == null) continue;
      _maskCell(sheet, col: 8, row: 3); // I4
      _maskCell(sheet, col: 32, row: 3); // AG4
    }

    final encoded = excel.encode();
    if (encoded == null) return excelBytes;
    return Uint8List.fromList(encoded);
  }

  static void _maskCell(Sheet sheet, {required int col, required int row}) {
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .value = TextCellValue('<MASKED>');
  }
}
