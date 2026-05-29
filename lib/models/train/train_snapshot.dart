import 'package:cloud_firestore/cloud_firestore.dart';

/// 最寄駅電車スナップショット（API JSON / 任意で Firestore とも同形）
class TrainSnapshot {
  const TrainSnapshot({
    required this.campusKey,
    required this.stationName,
    required this.updatedAt,
    required this.source,
    required this.delay,
    required this.directions,
  });

  final String campusKey;
  final String stationName;
  final DateTime updatedAt;
  final String source;
  final TrainDelayInfo delay;
  final List<TrainDirectionSnapshot> directions;

  /// API・ローカル JSON 用（ISO8601 文字列・epoch ms 対応）
  factory TrainSnapshot.fromMap(String campusKey, Map<String, dynamic> data) {
    final delayMap = data['delay'];
    final delay = TrainDelayInfo.fromJson(
      delayMap is Map<String, dynamic> ? delayMap : const {},
    );
    final dirList = data['directions'];
    final directions = <TrainDirectionSnapshot>[];
    if (dirList is List) {
      for (final e in dirList) {
        if (e is Map<String, dynamic>) {
          directions.add(TrainDirectionSnapshot.fromJson(e));
        } else if (e is Map) {
          directions.add(
            TrainDirectionSnapshot.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ),
          );
        }
      }
    }
    return TrainSnapshot(
      campusKey: campusKey,
      stationName: data['stationName'] as String? ?? '',
      updatedAt: parseTrainDateTime(data['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      source: data['source'] as String? ?? '',
      delay: delay,
      directions: directions,
    );
  }

  /// 後方互換: Firestore ドキュメントを Map にしたもの
  factory TrainSnapshot.fromFirestore(
    String campusKey,
    Map<String, dynamic> data,
  ) =>
      TrainSnapshot.fromMap(campusKey, data);
}

/// API / Firestore / キャッシュ共通の日時パース
DateTime? parseTrainDateTime(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is Timestamp) return v.toDate();
  if (v is String) {
    final d = DateTime.tryParse(v);
    if (d != null) return d;
  }
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  return null;
}

class TrainDelayInfo {
  const TrainDelayInfo({
    required this.status,
    this.message,
  });

  final TrainDelayStatus status;
  final String? message;

  factory TrainDelayInfo.fromJson(Map<String, dynamic> json) {
    final raw = json['status'] as String? ?? 'unknown';
    return TrainDelayInfo(
      status: parseTrainDelayStatus(raw),
      message: json['message'] as String?,
    );
  }
}

enum TrainDelayStatus { normal, delayed, suspended, unknown }

TrainDelayStatus parseTrainDelayStatus(String raw) {
  switch (raw) {
    case 'normal':
      return TrainDelayStatus.normal;
    case 'delayed':
      return TrainDelayStatus.delayed;
    case 'suspended':
      return TrainDelayStatus.suspended;
    default:
      return TrainDelayStatus.unknown;
  }
}

enum TrainTimetableType { weekday, saturday, holiday, unknown }

TrainTimetableType parseTrainTimetableType(String? raw) {
  switch (raw) {
    case 'weekday':
      return TrainTimetableType.weekday;
    case 'saturday':
      return TrainTimetableType.saturday;
    case 'holiday':
      return TrainTimetableType.holiday;
    default:
      return TrainTimetableType.unknown;
  }
}

class TrainDirectionSnapshot {
  const TrainDirectionSnapshot({
    required this.directionKey,
    required this.directionLabel,
    required this.nextDepartureAt,
    this.lineLabel,
    this.secondDepartureAt,
    this.timetableType = TrainTimetableType.unknown,
    this.boardingPlatform,
  });

  final String directionKey;
  final String directionLabel;

  /// 路線種別（例: 中央・総武線各駅停車）
  final String? lineLabel;
  final DateTime nextDepartureAt;
  final DateTime? secondDepartureAt;
  final TrainTimetableType timetableType;

  /// 乗車可能なホーム（例: `1・2番ホーム`）。ODPT 接続後は API から供給。
  final String? boardingPlatform;

  factory TrainDirectionSnapshot.fromJson(Map<String, dynamic> json) {
    return TrainDirectionSnapshot(
      directionKey: json['directionKey'] as String? ?? '',
      directionLabel: json['directionLabel'] as String? ?? '',
      lineLabel: json['lineLabel'] as String?,
      nextDepartureAt: parseTrainDateTime(json['nextDepartureAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      secondDepartureAt: parseTrainDateTime(json['secondDepartureAt']),
      timetableType: parseTrainTimetableType(
        json['timetableType'] as String?,
      ),
      boardingPlatform: json['boardingPlatform'] as String?,
    );
  }
}

/// 乗車ホーム表示用（`1・2番ホーム` など）
String formatTrainBoardingPlatform(String? raw) {
  final p = raw?.trim();
  if (p == null || p.isEmpty) return '';
  if (p.contains('ホーム') || p.contains('番')) return p;
  return '$p番ホーム';
}
