import 'dart:convert';
import 'dart:io';

import 'package:cit_app/services/schedule/excel_lecture_fields.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Expected values were manually transcribed from distinct export patterns.
  // Only lecture cells are kept; instructor names are replaced with fictitious
  // names, preserving kana, compatibility kanji, initials and wrapping.
  final cases =
      jsonDecode(
            File('test/fixtures/excel_import_cases.json').readAsStringSync(),
          )
          as List;
  for (final fixture in cases) {
    test('${fixture['id']}: ${fixture['expected']['subjectName']}', () {
      final fields = ExcelLectureFields.parse(
        List<String>.from(fixture['rows']),
      );
      expect({
        'subjectName': fields.subjectName,
        'instructor': fields.instructor,
        'classroom': fields.classroom,
      }, fixture['expected']);
    });
  }

  test('does not manufacture fields from an empty cell', () {
    final fields = ExcelLectureFields.parse(['', '  ']);
    expect(fields.subjectName, isEmpty);
    expect(fields.instructor, isEmpty);
    expect(fields.classroom, isEmpty);
  });

  test('a title continuation mentioning online is not a classroom', () {
    final fields = ExcelLectureFields.parse([
      '情報ネットワーク ',
      'オンライン解析',
      '山田 太郎',
      '新習志野キャンパス',
      '2単位',
    ]);
    expect(fields.subjectName, '情報ネットワークオンライン解析');
    expect(fields.instructor, '山田 太郎');
    expect(fields.classroom, isEmpty);
  });

  test('retains an unfamiliar room between the teacher and campus', () {
    final fields = ExcelLectureFields.parse([
      '総合演習',
      '山田 太郎',
      '別館研究スペース',
      '／新習志野キャンパス',
      '2単位',
    ]);
    expect(fields.subjectName, '総合演習');
    expect(fields.instructor, '山田 太郎');
    expect(fields.classroom, '別館研究スペース');
  });

  test(
    'does not append an unfamiliar location to a complete Japanese name',
    () {
      final fields = ExcelLectureFields.parse([
        '総合演習',
        '山田 太郎',
        '特設ラボ',
        '／新習志野キャンパス',
        '2単位',
      ]);
      expect(fields.instructor, '山田 太郎');
      expect(fields.classroom, '特設ラボ');
    },
  );
}
