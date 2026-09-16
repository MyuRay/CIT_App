typedef BusDepartureData = Map<String, dynamic>;

const busDayLabels = {'weekday': '平日', 'saturday': '土曜', 'sunday': '日曜'};

String busDepartureDay(BusDepartureData entry) =>
    entry['dayType'] as String? ?? 'weekday';

int busDepartureMinute(BusDepartureData entry) =>
    (entry['hour'] as int) * 60 + (entry['minute'] as int);

String formatBusMinute(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';

List<BusDepartureData> copyBusDepartures(Iterable<BusDepartureData> entries) =>
    entries.map((entry) => Map<String, dynamic>.from(entry)).toList();

bool busTimetableDataEquals(Object? a, Object? b) {
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every(
          (key) => b.containsKey(key) && busTimetableDataEquals(a[key], b[key]),
        );
  }
  if (a is List && b is List) {
    return a.length == b.length &&
        Iterable.generate(
          a.length,
        ).every((i) => busTimetableDataEquals(a[i], b[i]));
  }
  return a == b;
}

String _normalizeTimeInput(String value) => String.fromCharCodes(
  value.runes.map(
    (rune) => rune >= 0xff10 && rune <= 0xff19 ? rune - 0xfee0 : rune,
  ),
).replaceAll('：', ':').replaceAll('　', ' ');

int parseBusTime(String input) {
  final value = _normalizeTimeInput(input).trim();
  final colon = RegExp(r'^(\d{1,2}):(\d{1,2})$').firstMatch(value);
  final compact = RegExp(r'^\d{3,4}$').hasMatch(value);
  if (colon == null && !compact) {
    throw FormatException('「$input」は時刻として読めません。08:30 または 830 の形式で入力してください。');
  }
  final hour =
      colon != null
          ? int.parse(colon[1]!)
          : int.parse(value.substring(0, value.length - 2));
  final minute =
      colon != null
          ? int.parse(colon[2]!)
          : int.parse(value.substring(value.length - 2));
  if (hour > 23 || minute > 59) {
    throw FormatException('「$input」は範囲外です。時は0〜23、分は0〜59で入力してください。');
  }
  return hour * 60 + minute;
}

/// Accepts full times or hour rows, including pasted spreadsheet columns.
/// Invalid tokens reject the whole input instead of silently dropping a bus.
List<int> parseBusTimeList(String input) {
  final normalized = _normalizeTimeInput(
    input,
  ).replaceAll(RegExp('[,、;；]'), ' ');
  final times = <int>[];
  final lines = normalized.split(RegExp(r'\r?\n'));
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    try {
      final row = RegExp(
        r'^(\d{1,2})(?:時\s*|:\s+|\t+)(\d{1,2}(?:\s+\d{1,2})*)$',
      ).firstMatch(line);
      if (row != null) {
        for (final minute in row[2]!.split(RegExp(r'\s+'))) {
          times.add(parseBusTime('${row[1]}:$minute'));
        }
      } else {
        for (final token in line.split(RegExp(r'\s+'))) {
          times.add(parseBusTime(token));
        }
      }
    } on FormatException catch (error) {
      throw FormatException('${i + 1}行目：${error.message}');
    }
  }
  if (times.isEmpty) throw const FormatException('登録する時刻を入力してください。');
  return times;
}

List<int> generateBusTimes(String start, String end, String interval) {
  final first = parseBusTime(start);
  final last = parseBusTime(end);
  final step = int.tryParse(_normalizeTimeInput(interval).trim());
  if (step == null || step < 1 || step > 1440) {
    throw const FormatException('間隔は1〜1440分の整数で入力してください。');
  }
  if (last < first) {
    throw const FormatException('終了時刻は開始時刻以降にしてください。日付をまたぐ場合は分けて登録します。');
  }
  return [for (var time = first; time <= last; time += step) time];
}

int _departureSequence = 0;
BusDepartureData newBusDeparture(
  int minute,
  String dayType, {
  String? note,
  bool active = true,
}) => {
  'id': 'bus_${DateTime.now().microsecondsSinceEpoch}_${_departureSequence++}',
  'hour': minute ~/ 60,
  'minute': minute % 60,
  'dayType': dayType,
  'note': note?.trim().isEmpty == true ? null : note?.trim(),
  'isActive': active,
};

List<BusDepartureData> mergeBusDepartures(
  List<BusDepartureData> current,
  List<BusDepartureData> incoming,
  String dayType, {
  bool replace = false,
}) {
  final result = copyBusDepartures(
    current.where((e) => !replace || busDepartureDay(e) != dayType),
  );
  final occupied =
      result
          .where((e) => busDepartureDay(e) == dayType)
          .map(busDepartureMinute)
          .toSet();
  for (final entry in incoming) {
    if (occupied.add(busDepartureMinute(entry))) {
      result.add({...entry, 'dayType': dayType});
    }
  }
  result.sort((a, b) {
    final byTime = busDepartureMinute(a).compareTo(busDepartureMinute(b));
    return byTime != 0
        ? byTime
        : busDepartureDay(a).compareTo(busDepartureDay(b));
  });
  return result;
}

void validateBusDepartures(List<BusDepartureData> entries) {
  for (final entry in entries) {
    final hour = entry['hour'];
    final minute = entry['minute'];
    if (hour is! int ||
        hour < 0 ||
        hour > 23 ||
        minute is! int ||
        minute < 0 ||
        minute > 59 ||
        !busDayLabels.containsKey(busDepartureDay(entry))) {
      throw const FormatException('時刻または曜日が不正な便があります。ダイヤを確認してください。');
    }
  }
}

class BusTimetableRoute {
  const BusTimetableRoute({
    required this.id,
    required this.name,
    required this.entries,
  });
  final String id;
  final String name;
  final List<BusDepartureData> entries;
}
