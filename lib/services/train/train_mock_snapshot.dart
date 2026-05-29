import '../../models/train/train_snapshot.dart';

/// ODPT 接続前のローカルモック（[TrainSnapshot] と同形）。
///
/// 現在時刻から「次発・次々発」を生成するため、UI の余裕判定をその場で試せる。
class TrainMockSnapshot {
  TrainMockSnapshot._();

  static const _configs = <String, _CampusMockConfig>{
    'tsudanuma': _CampusMockConfig(
      stationName: '津田沼',
      source: 'モックデータ（ODPT接続前・津田沼）',
      directions: [
        _DirectionMockConfig(
          directionKey: 'tokyo',
          lineLabel: '中央・総武線各駅停車',
          directionLabel: '西船橋・両国方面 (西行)',
          slotOffsetMin: 3,
          intervalMin: 5,
          boardingPlatform: '1・2番ホーム',
        ),
        _DirectionMockConfig(
          directionKey: 'chiba',
          directionLabel: '千葉方面',
          slotOffsetMin: 1,
          intervalMin: 7,
          boardingPlatform: '3・4番ホーム',
        ),
      ],
    ),
    'narashino': _CampusMockConfig(
      stationName: '新習志野',
      source: 'モックデータ（ODPT接続前・新習志野）',
      directions: [
        _DirectionMockConfig(
          directionKey: 'kaihimmakuhari',
          directionLabel: '海浜幕張方面',
          slotOffsetMin: 2,
          intervalMin: 6,
          boardingPlatform: '1・2番ホーム',
        ),
        _DirectionMockConfig(
          directionKey: 'tokyo',
          directionLabel: '東京・舞浜方面',
          slotOffsetMin: 4,
          intervalMin: 8,
          boardingPlatform: '3・4番ホーム',
        ),
      ],
    ),
  };

  static TrainSnapshot build(String campusKey, DateTime now) {
    final key = campusKey == 'narashino' ? 'narashino' : 'tsudanuma';
    final cfg = _configs[key]!;
    final timetableType = _timetableType(now);

    final directions = [
      for (final d in cfg.directions)
        TrainDirectionSnapshot(
          directionKey: d.directionKey,
          lineLabel: d.lineLabel,
          directionLabel: d.directionLabel,
          nextDepartureAt: nextDepartures(
            now,
            d.slotOffsetMin,
            d.intervalMin,
            1,
          ).first,
          secondDepartureAt: nextDepartures(
            now,
            d.slotOffsetMin,
            d.intervalMin,
            2,
          )[1],
          timetableType: timetableType,
          boardingPlatform: d.boardingPlatform,
        ),
    ];

    return TrainSnapshot(
      campusKey: key,
      stationName: cfg.stationName,
      updatedAt: now,
      source: cfg.source,
      delay: const TrainDelayInfo(status: TrainDelayStatus.normal),
      directions: directions,
    );
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

  /// テスト・Functions モックと同じ刻みロジック
  static List<DateTime> nextDepartures(
    DateTime now,
    int slotOffsetMin,
    int intervalMin,
    int count,
  ) {
    if (count <= 0) return const [];
    var cursor = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    ).add(Duration(minutes: slotOffsetMin));
    while (!cursor.isAfter(now)) {
      cursor = cursor.add(Duration(minutes: intervalMin));
    }
    final out = <DateTime>[];
    for (var i = 0; i < count; i++) {
      out.add(cursor);
      cursor = cursor.add(Duration(minutes: intervalMin));
    }
    return out;
  }
}

class _CampusMockConfig {
  const _CampusMockConfig({
    required this.stationName,
    required this.source,
    required this.directions,
  });

  final String stationName;
  final String source;
  final List<_DirectionMockConfig> directions;
}

class _DirectionMockConfig {
  const _DirectionMockConfig({
    required this.directionKey,
    required this.directionLabel,
    this.lineLabel,
    required this.slotOffsetMin,
    required this.intervalMin,
    required this.boardingPlatform,
  });

  final String directionKey;
  final String directionLabel;
  final String? lineLabel;
  final int slotOffsetMin;
  final int intervalMin;
  final String boardingPlatform;
}
