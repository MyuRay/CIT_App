import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/train/train_snapshot.dart';

/// 津田沼・東京方面・平日の静的時刻表（Functions と同じ JSON 由来をアセット同梱）
class TrainStaticSnapshot {
  TrainStaticSnapshot._();

  static const _assetPath = 'assets/train/tsudanuma_tokyo_weekday.json';

  static Map<String, dynamic>? _asset;

  static bool get supportsTsudanuma => true;

  static Future<void> ensureLoaded() async {
    if (_asset != null) return;
    final raw = await rootBundle.loadString(_assetPath);
    _asset = json.decode(raw) as Map<String, dynamic>;
  }

  /// 同梱データがあるキャンパスのみ非 null
  static TrainSnapshot? build(String campusKey, DateTime now) {
    if (campusKey == 'narashino') return null;
    final data = _asset;
    if (data == null) return null;

    final times = _timesForDate(data, now);
    final departures = pickUpcomingFromTimeList(times, now, 2);
    if (departures.isEmpty) return null;

    final timetableType = _timetableType(now);

    return TrainSnapshot(
      campusKey: 'tsudanuma',
      stationName: data['stationName'] as String? ?? '津田沼',
      updatedAt: now,
      source: data['source'] as String? ?? '静的時刻表（アプリ内）',
      delay: const TrainDelayInfo(status: TrainDelayStatus.normal),
      directions: [
        TrainDirectionSnapshot(
          directionKey: data['directionKey'] as String? ?? 'tokyo',
          lineLabel: data['lineLabel'] as String?,
          directionLabel:
              data['directionLabel'] as String? ?? '西船橋・両国方面 (西行)',
          nextDepartureAt: departures.first,
          secondDepartureAt: departures.length > 1 ? departures[1] : null,
          timetableType: timetableType,
          boardingPlatform: data['boardingPlatform'] as String?,
        ),
      ],
    );
  }

  static List<String> _timesForDate(Map<String, dynamic> data, DateTime now) {
    final weekday = (data['weekday'] as List?)?.cast<String>() ?? const [];
    // 土日データ未投入の間は平日時刻で表示（Functions static と同方針）
    return weekday;
  }

  static TrainTimetableType _timetableType(DateTime d) {
    switch (d.weekday) {
      case DateTime.saturday:
        return TrainTimetableType.saturday;
      case DateTime.sunday:
        return TrainTimetableType.holiday;
      default:
        return TrainTimetableType.weekday;
    }
  }

  /// Functions [pickFromTimeList] / [departureDateFromHHMM] と同じロジック
  static List<DateTime> pickUpcomingFromTimeList(
    List<String> times,
    DateTime now,
    int count,
  ) {
    if (count <= 0) return const [];

    final upcoming = <DateTime>[];
    for (final hhmm in times) {
      final dep = _departureDateFromHHMM(hhmm, now);
      if (dep == null || !dep.isAfter(now)) continue;
      upcoming.add(dep);
    }
    upcoming.sort((a, b) => a.compareTo(b));

    final unique = <DateTime>[];
    final seen = <int>{};
    for (final d in upcoming) {
      final key = d.millisecondsSinceEpoch;
      if (seen.contains(key)) continue;
      seen.add(key);
      unique.add(d);
      if (unique.length >= count) break;
    }
    return unique;
  }

  static DateTime? _departureDateFromHHMM(String hhmm, DateTime now) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(hhmm.trim());
    if (m == null) return null;
    final h = int.tryParse(m.group(1)!);
    final min = int.tryParse(m.group(2)!);
    if (h == null || min == null) return null;

    var d = DateTime(now.year, now.month, now.day, h, min);
    if (!d.isAfter(now)) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }
}

bool trainDirectionHasValidDeparture(TrainDirectionSnapshot d) {
  return d.nextDepartureAt.year >= 2000;
}

TrainSnapshot trainSnapshotWithValidDirections(TrainSnapshot snap) {
  final dirs =
      snap.directions.where(trainDirectionHasValidDeparture).toList();
  return TrainSnapshot(
    campusKey: snap.campusKey,
    stationName: snap.stationName,
    updatedAt: snap.updatedAt,
    source: snap.source,
    delay: snap.delay,
    directions: dirs,
  );
}
