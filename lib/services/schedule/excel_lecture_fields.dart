/// Extracts the fields in one printed university timetable cell.
///
/// Exported lines are physical wraps, not field boundaries. Read the teacher
/// nearest the location/footer first, then reassemble each field independently.
/// No student identifiers or person-name lookup table is used.
class ExcelLectureFields {
  const ExcelLectureFields({
    required this.subjectName,
    required this.instructor,
    required this.classroom,
  });

  final String subjectName;
  final String instructor;
  final String classroom;

  static ExcelLectureFields parse(List<String> sourceRows) {
    final rows =
        sourceRows
            .map((row) => row.replaceAll('_x000D_', '').trim())
            .where((row) => row.isNotEmpty)
            .toList();
    if (rows.isEmpty) {
      return const ExcelLectureFields(
        subjectName: '',
        instructor: '',
        classroom: '',
      );
    }
    final footer = rows.indexWhere(isFooterRow, 1);
    if (footer >= 0) rows.removeRange(footer, rows.length);

    var locationStart = rows.length;
    for (var i = 1; i < rows.length; i++) {
      if (_startsLocation(rows.sublist(i).join())) {
        locationStart = i;
        break;
      }
    }
    final teacher = _findTeacher(rows, locationStart);
    final subjectEnd = teacher?.start ?? locationStart;
    final locationRows = rows.skip(
      teacher == null ? locationStart : teacher.end + 1,
    );
    return ExcelLectureFields(
      subjectName: _subject(rows.take(subjectEnd).toList()),
      instructor: teacher?.name ?? '',
      classroom: _classroom(locationRows.join()),
    );
  }

  /// Printed annotations and unit counts mark the end of a lecture's fields.
  static bool isFooterRow(String text) =>
      RegExp(r'^[\[［【]').hasMatch(text) ||
      isUnitCountRow(text) ||
      text.contains('キャンパス（1限') ||
      text.contains('キャンパス(1限');

  static bool isUnitCountRow(String text) =>
      RegExp(r'^[0-9]+(?:\.[0-9]+)?\s*単位$').hasMatch(_normalize(text));

  static bool _startsLocation(String text) {
    final compact = _normalize(text).replaceAll(' ', '');
    return RegExp(
      r'^(?:新習志野|津田沼)(?:キャンパス|[/／])|'
      r'^(?:オンライン|オンデマンド)(?:[/／]|新習志野|津田沼|$)|'
      r'^(?:体育館|グラウンド|食堂棟|物理第|化学第|生命科学科|電子工学実験室)|'
      r'^[0-9]+(?:号館|号棟|棟|階|(?:PC)?(?:講義室|演習室|教室|実習室|実験室|製図室|工作室))',
    ).hasMatch(compact);
  }

  static ({int start, int end, String name})? _findTeacher(
    List<String> rows,
    int end,
  ) {
    for (var last = end - 1; last >= 1; last--) {
      if (RegExp(r'^[●○＊*・×xXー－—\s]+$').hasMatch(rows[last]) ||
          const {'未定', '非公開', '担当未定'}.contains(rows[last])) {
        return (start: last, end: last, name: '');
      }
      // Initials/foreign surnames and external lecturers may wrap again.
      for (var first = (last - 2).clamp(1, last); first < last; first++) {
        final prefix = _normalize(rows[first]);
        if (!prefix.contains(' ') ||
            (!_couldBeTeacher(prefix) && !_lecturerPrefix.hasMatch(prefix))) {
          continue;
        }
        // Complete Japanese names are not extended with a following place name.
        // The observed wraps are foreign initials and external lecturer roles.
        if (!RegExp(r'^[A-Za-z][.．]|講$').hasMatch(prefix) &&
            !_lecturerPrefix.hasMatch(prefix)) {
          continue;
        }
        final continuations = rows.sublist(first + 1, last + 1);
        if (!continuations.every(_isNameContinuation)) continue;
        final name = _normalize(rows.sublist(first, last + 1).join());
        if (_couldBeTeacher(name)) return (start: first, end: last, name: name);
      }
      final single = _normalize(rows[last]);
      if (_couldBeTeacher(single)) {
        return (start: last, end: last, name: single);
      }
    }
    return null;
  }

  // Include kana and CJK compatibility characters (for example, 﨑). A course
  // fragment such as "番 偶数" must never win over the actual instructor.
  static const _nameChars =
      r"A-Za-z\u3400-\u9fff\uf900-\ufaff々〆ヶヵぁ-んァ-ヶー.'’．\-";
  static final _person = RegExp(
    '^[$_nameChars]{1,35}(?: [$_nameChars]{1,35}){1,3}\$',
  );
  static final _lecturer = RegExp(
    '^[${_nameChars}0-9]{1,35} [${_nameChars}0-9]{0,35}(?:講師|教授|教員)[0-9]*\$',
  );
  static final _lecturerPrefix = RegExp(
    '^[$_nameChars]+[0-9]+ [$_nameChars]+\$',
  );
  static final _courseMetadata = RegExp(
    r'学番|クラス|コース|奇数|偶数|演習|実験|基礎|入門|キャンパス|単位|[_※]|[()（）]|'
    r'号館|別館|講義室|教室|製図室|工作室|ワークスペース|ラボ|体育館',
  );

  static bool _couldBeTeacher(String text) {
    if (_courseMetadata.hasMatch(text) || _startsLocation(text)) return false;
    if (_lecturer.hasMatch(text)) return true;
    // A lecturer's role can be split as "田中講" / "師".
    if (RegExp(r'^[^ ]+[0-9]? [^ ]+講$').hasMatch(text)) return true;
    return _person.hasMatch(text);
  }

  static bool _isNameContinuation(String text) {
    final value = _normalize(text);
    return RegExp('^[$_nameChars]{1,15}\$').hasMatch(value) &&
        !RegExp(r'科|室|階|館|キャン|共用|工作|演習|実験|コース').hasMatch(value) &&
        !_departments.contains(value);
  }

  // Whole standalone department labels are separate from the lecture title;
  // a label split in the middle is joined normally. These are course labels,
  // not a dictionary of students, lecturers, or complete lecture names.
  static const _departments = {
    '機械',
    '機電',
    '材料',
    '応化',
    '電電',
    '電子',
    '都市',
    '建築',
    '情工',
    '情報',
    '高度',
    '未ロ',
    '生命',
    '認知',
    '知能',
    '宇宙',
    '通信',
    '経情',
    '経デ',
    'デジ',
    'デ科',
    'デザ',
    'NS',
    'PM',
  };

  static String _subject(List<String> rows) {
    if (rows.isEmpty) return '';
    var joined = rows.first;
    for (final row in rows.skip(1)) {
      final normalized = _normalize(row);
      final previous = _normalize(joined);
      final hasQualifier = previous.contains(' ');
      final qualifier = normalized.split('※').first.trim();
      final separateLabel =
          !hasQualifier &&
          _departments.any(
            (department) =>
                RegExp('^$department(?:\$|[_0-9 ・(])').hasMatch(qualifier),
          );
      final separateYear = RegExp(r'^[0-9]+年$').hasMatch(normalized);
      joined += '${separateLabel || separateYear ? ' ' : ''}$row';
    }
    // ※ introduces an alternative curriculum's name, not part of this title.
    var title = _normalize(joined.split('※').first);
    // Preserve the existing omission of trailing course/year administration.
    title = title.replaceFirst(RegExp(r'\s+[^\s]*コース(?:\s*[0-9]+年)?$'), '');
    title = title.replaceFirst(RegExp(r'\s+[0-9]+年$'), '');
    return title.trim();
  }

  static String _classroom(String text) {
    var room = _normalize(
      text.split(RegExp(r'[/／]')).first,
    ).replaceAll(' ', '');
    if (room.isEmpty) return '';
    // Campus-only exports contain no classroom; do not invent a room from a
    // different student's timetable or a similarly named course.
    room = room.split('キャンパス').first;
    if (room == '新習志野' || room == '津田沼') return '';
    if (room.contains('フレキシブルワークスペース')) {
      room = room.replaceFirst('フレキシブルワークスペース', ' フレキシブルワークスペース');
      room = room.replaceFirstMapped(RegExp(r'(新習志野|津田沼)$'), (m) => ' ${m[0]}');
    } else {
      room = room.replaceFirst(RegExp(r'(新習志野|津田沼)$'), '');
    }
    return room.trim();
  }

  static String _normalize(String text) =>
      String.fromCharCodes(
        text.runes.map((c) => c >= 0xff01 && c <= 0xff5e ? c - 0xfee0 : c),
      ).replaceAll(RegExp(r'\s+'), ' ').trim();
}
