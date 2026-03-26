import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/classroom_map/classroom_map_model.dart';

/// 教室マップのデータを読み込むサービス
/// 写真提供後に教室一覧を拡充予定
class ClassroomMapService {
  static const String _assetPath = 'assets/data/classroom_map.json';

  static Map<String, dynamic>? _cachedData;

  static Future<Map<String, dynamic>> _loadData() async {
    if (_cachedData != null) return _cachedData!;
    final jsonStr = await rootBundle.loadString(_assetPath);
    _cachedData = json.decode(jsonStr) as Map<String, dynamic>;
    return _cachedData!;
  }

  /// キャンパス一覧と校舎マーカーを取得
  static Future<CampusMapData> getCampusMapData() async {
    final data = await _loadData();
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
    final data = await _loadData();
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
