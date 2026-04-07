import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../data/classroom_map_json.dart';
import '../../models/classroom_map/classroom_map_model.dart';

/// 教室マップのデータを読み込むサービス
/// 写真提供後に教室一覧を拡充予定
///
/// データは [kClassroomMapJson] のみ（rootBundle は使わない）。
class ClassroomMapService {
  static Map<String, dynamic>? _cachedData;

  static Map<String, dynamic> _parsedJson() {
    if (_cachedData != null) return _cachedData!;
    try {
      _cachedData = json.decode(kClassroomMapJson) as Map<String, dynamic>;
    } catch (e, st) {
      debugPrint('ClassroomMapService: JSON decode failed: $e\n$st');
      rethrow;
    }
    return _cachedData!;
  }

  /// キャンパス一覧と校舎マーカーを取得
  static Future<CampusMapData> getCampusMapData() async {
    final data = _parsedJson();
    final campuses = <CampusMapItem>[];

    for (final c in (data['campuses'] as List<dynamic>)) {
      final campusJson = c as Map<String, dynamic>;
      final buildings = <BuildingMarker>[];
      for (final b in (campusJson['buildings'] as List<dynamic>)) {
        buildings.add(BuildingMarker.fromJson(b as Map<String, dynamic>));
      }
      campuses.add(CampusMapItem(
        id: campusJson['id'] as String,
        displayName: campusJson['displayName'] as String,
        centerLat: (campusJson['centerLat'] as num).toDouble(),
        centerLng: (campusJson['centerLng'] as num).toDouble(),
        buildings: buildings,
      ));
    }
    return CampusMapData(campuses: campuses);
  }

  /// 校舎別の教室一覧を取得
  static Future<List<BuildingRooms>> getBuildingRooms() async {
    final data = _parsedJson();
    final list = <BuildingRooms>[];
    for (final b in (data['buildingRooms'] as List<dynamic>)) {
      list.add(BuildingRooms.fromJson(b as Map<String, dynamic>));
    }
    return list;
  }

  /// 指定キャンパスの校舎マーカーを取得
  static Future<List<BuildingMarker>> getBuildingMarkers(String campusId) async {
    final mapData = await getCampusMapData();
    final campus = mapData.campuses.firstWhere(
      (c) => c.id == campusId,
      orElse: () => throw StateError('Campus not found: $campusId'),
    );
    return campus.buildings;
  }
}
