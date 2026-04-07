import 'package:cloud_firestore/cloud_firestore.dart';

enum TrainDelayStatus { normal, delayed, suspended, unknown }

extension TrainDelayStatusX on TrainDelayStatus {
  String get label {
    switch (this) {
      case TrainDelayStatus.normal:
        return '平常運転';
      case TrainDelayStatus.delayed:
        return '遅延あり';
      case TrainDelayStatus.suspended:
        return '運転見合わせ';
      case TrainDelayStatus.unknown:
        return '情報不明';
    }
  }
}

class TrainDirectionSnapshot {
  const TrainDirectionSnapshot({
    required this.directionKey,
    required this.directionLabel,
    required this.nextDepartureAt,
    required this.secondDepartureAt,
    this.timetableType,
  });

  final String directionKey;
  final String directionLabel;
  final DateTime nextDepartureAt;
  final DateTime secondDepartureAt;
  final String? timetableType;

  TrainDirectionSnapshot copyWith({
    String? directionKey,
    String? directionLabel,
    DateTime? nextDepartureAt,
    DateTime? secondDepartureAt,
    String? timetableType,
  }) {
    return TrainDirectionSnapshot(
      directionKey: directionKey ?? this.directionKey,
      directionLabel: directionLabel ?? this.directionLabel,
      nextDepartureAt: nextDepartureAt ?? this.nextDepartureAt,
      secondDepartureAt: secondDepartureAt ?? this.secondDepartureAt,
      timetableType: timetableType ?? this.timetableType,
    );
  }

  factory TrainDirectionSnapshot.fromJson(Map<String, dynamic> json) {
    return TrainDirectionSnapshot(
      directionKey: json['directionKey'] as String? ?? '',
      directionLabel: json['directionLabel'] as String? ?? '',
      nextDepartureAt: _parseDateTime(json['nextDepartureAt']) ?? DateTime.now(),
      secondDepartureAt:
          _parseDateTime(json['secondDepartureAt']) ?? DateTime.now(),
      timetableType: json['timetableType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'directionKey': directionKey,
      'directionLabel': directionLabel,
      'nextDepartureAt': nextDepartureAt.toIso8601String(),
      'secondDepartureAt': secondDepartureAt.toIso8601String(),
      'timetableType': timetableType,
    };
  }
}

class TrainSnapshot {
  const TrainSnapshot({
    required this.campusKey,
    required this.stationName,
    required this.updatedAt,
    required this.source,
    required this.delayStatus,
    this.delayMessage,
    required this.directions,
  });

  final String campusKey;
  final String stationName;
  final DateTime updatedAt;
  final String source;
  final TrainDelayStatus delayStatus;
  final String? delayMessage;
  final List<TrainDirectionSnapshot> directions;

  TrainDirectionSnapshot? findDirection(String directionKey) {
    try {
      return directions.firstWhere((d) => d.directionKey == directionKey);
    } catch (_) {
      return null;
    }
  }

  List<TrainDirectionSnapshot> orderedByPreferredDirection(String directionKey) {
    final preferred = findDirection(directionKey);
    if (preferred == null) return directions;
    return [
      preferred,
      ...directions.where((d) => d.directionKey != directionKey),
    ];
  }

  factory TrainSnapshot.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['delayStatus'] as String? ?? 'unknown').trim();
    final status = TrainDelayStatus.values.firstWhere(
      (v) => v.name == rawStatus,
      orElse: () => TrainDelayStatus.unknown,
    );
    final rawDirections = (json['directions'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map(TrainDirectionSnapshot.fromJson)
        .toList();

    return TrainSnapshot(
      campusKey: json['campusKey'] as String? ?? '',
      stationName: json['stationName'] as String? ?? '',
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
      source: json['source'] as String? ?? '',
      delayStatus: status,
      delayMessage: json['delayMessage'] as String?,
      directions: rawDirections,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'campusKey': campusKey,
      'stationName': stationName,
      'updatedAt': updatedAt.toIso8601String(),
      'source': source,
      'delayStatus': delayStatus.name,
      'delayMessage': delayMessage,
      'directions': directions.map((e) => e.toJson()).toList(),
    };
  }
}

DateTime? _parseDateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
