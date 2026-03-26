import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/circle/circle_model.dart';

/// サークルデータをローカルJSONから読み込むサービス（デモ用）
class CircleService {
  static const _assetPath = 'assets/data/circles.json';

  /// デモ用の体験会日付（2026年4月の土日中心）
  static final List<String> _demoDates = [
    '2026-04-05', '2026-04-06', '2026-04-12', '2026-04-13',
    '2026-04-19', '2026-04-20', '2026-04-26', '2026-04-27',
  ];

  static const List<String> _places = [
    '津田沼校舎 2号館',
    '津田沼校舎 体育館',
    '新習志野 体育館',
    '新習志野 グラウンド',
    '芝園 グラウンド',
    '芝園 多目的ホール',
  ];

  static const List<String> _campuses = ['tsudanuma', 'narashino', 'shibazono'];

  /// サークル一覧を取得（体験会を追加）
  static Future<List<Circle>> loadCircles() async {
    final jsonStr = await rootBundle.loadString(_assetPath);
    final list = json.decode(jsonStr) as List<dynamic>;
    final circles = <Circle>[];

    for (var i = 0; i < list.length; i++) {
      final raw = list[i] as Map<String, dynamic>;
      final events = _createDemoEvents(i);
      raw['events'] = events.map((e) => e.toJson()).toList();
      circles.add(Circle.fromJson(raw, id: i + 1));
    }

    return circles;
  }

  /// デモ用の体験会を生成（サークルごとに1〜2件）
  static List<CircleEvent> _createDemoEvents(int index) {
    final events = <CircleEvent>[];
    final dateIdx = index % _demoDates.length;
    final date = _demoDates[dateIdx];
    final placeIdx = index % _places.length;
    final place = _places[placeIdx];
    final campusIdx = index % _campuses.length;
    final campus = _campuses[campusIdx];

    events.add(CircleEvent(
      date: date,
      time: '14:00-',
      place: place,
      campus: campus,
    ));

    if (index % 3 == 0) {
      final dateIdx2 = (index + 2) % _demoDates.length;
      final date2 = _demoDates[dateIdx2];
      final campusIdx2 = (index + 1) % _campuses.length;
      events.add(CircleEvent(
        date: date2,
        time: '10:00-',
        place: _places[(placeIdx + 1) % _places.length],
        campus: _campuses[campusIdx2],
      ));
    }

    return events;
  }

  /// デモ用マッチングスコア（タグ一致ベース）
  static int getMatchScore(Circle circle, List<String> selectedTags) {
    if (selectedTags.isEmpty) return 0;
    var score = 0;
    for (final tag in selectedTags) {
      if (circle.tags.contains(tag)) score += 10;
    }
    return score;
  }
}
