import 'dart:convert';
import 'dart:io';

import 'package:cit_app/services/schedule/excel_schedule_import_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Local-only structural audit, not an accuracy score against labelled answers.
/// Usage: set CIT_IMPORT_TRAINING to the directory holding the supplied XLSX
/// files, then run this test. Raw workbooks stay outside Git and app assets.
void main() {
  final directory = Platform.environment['CIT_IMPORT_TRAINING'];
  test(
    'all supplied workbooks decode with usable semester drafts',
    () async {
      final files =
          Directory(directory!)
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => file.path.toLowerCase().endsWith('.xlsx'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      expect(files, isNotEmpty);
      final failures = <String>[];
      final records = <Map<String, Object>>[];
      var semesters = 0;
      var lectures = 0;
      var periods = 0;
      var missingInstructors = 0;
      var missingClassrooms = 0;
      for (var i = 0; i < files.length; i++) {
        try {
          final workbook = await ExcelScheduleImportService.parseWorkbookBytes(
            await files[i].readAsBytes(),
          );
          expect(workbook.semesters, isNotEmpty, reason: 'Sample ${i + 1}');
          final entries =
              workbook.semesters
                  .expand((semester) => semester.draft.entries)
                  .toList();
          expect(entries, isNotEmpty, reason: 'Sample ${i + 1}');
          semesters += workbook.semesters.length;
          lectures += entries.length;
          for (final entry in entries) {
            expect(entry.subjectName, isNotEmpty);
            expect(entry.startPeriod, inInclusiveRange(1, 10));
            expect(entry.duration, inInclusiveRange(1, 10));
            expect(
              entry.startPeriod + entry.duration - 1,
              lessThanOrEqualTo(10),
            );
            expect(entry.instructor, isNot(contains('キャンパス')));
            expect(entry.classroom, isNot(contains('キャンパス')));
            periods += entry.duration;
            if (entry.instructor.isEmpty) missingInstructors++;
            if (entry.classroom.isEmpty) missingClassrooms++;
          }
          records.add({
            'sample': i + 1,
            'semesters': workbook.semesters.length,
            'lectures': entries.length,
          });
        } catch (error) {
          // Do not put upload filenames or user IDs in the test output.
          failures.add('Sample ${i + 1}: ${error.runtimeType}');
        }
        if ((i + 1) % 50 == 0) {
          debugPrint('Audited ${i + 1}/${files.length} workbooks');
        }
      }
      final report = {
        'files': files.length,
        'semesters': semesters,
        'lectures': lectures,
        'periods': periods,
        'missingInstructors': missingInstructors,
        'missingClassrooms': missingClassrooms,
        'failures': failures,
        'samples': records,
      };
      final output = File('build/excel-training/corpus-audit.json');
      output.parent.createSync(recursive: true);
      output.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(report),
      );
      debugPrint(
        'Files: ${files.length}; terms: $semesters; lectures: $lectures; periods: $periods; failures: ${failures.length}',
      );
      expect(failures, isEmpty);
    },
    skip:
        directory == null
            ? 'Set CIT_IMPORT_TRAINING for the private local workbook audit.'
            : false,
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
