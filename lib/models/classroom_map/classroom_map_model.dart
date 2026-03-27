// 教室マップ用のモデル
// 写真提供後に教室一覧を拡充予定

/// キャンパス種別
enum CampusType {
  tsudanuma('tsudanuma', '津田沼キャンパス'),
  narashino('narashino', '新習志野キャンパス');

  const CampusType(this.id, this.displayName);
  final String id;
  final String displayName;
}

/// 校舎情報（マップ上のマーカー用）
class BuildingMarker {
  const BuildingMarker({
    required this.buildingId,
    required this.buildingName,
    required this.latitude,
    required this.longitude,
    required this.facilities,
  });

  final String buildingId;
  final String buildingName;
  final double latitude;
  final double longitude;
  final List<String> facilities;

  factory BuildingMarker.fromJson(Map<String, dynamic> json) {
    return BuildingMarker(
      buildingId: json['buildingId'] as String,
      buildingName: json['buildingName'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      facilities: (json['facilities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

/// 階情報
class FloorInfo {
  const FloorInfo({
    required this.floor,
    required this.floorName,
    required this.rooms,
  });

  final int floor;
  final String floorName;
  final List<RoomInfo> rooms;

  factory FloorInfo.fromJson(Map<String, dynamic> json) {
    return FloorInfo(
      floor: json['floor'] as int,
      floorName: json['floorName'] as String? ?? '${json['floor']}階',
      rooms: (json['rooms'] as List<dynamic>?)
              ?.map((e) => RoomInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// 教室情報
class RoomInfo {
  const RoomInfo({
    required this.id,
    required this.name,
    this.type,
  });

  final String id;
  final String name;
  final String? type;

  factory RoomInfo.fromJson(Map<String, dynamic> json) {
    return RoomInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String?,
    );
  }
}

/// キャンパスマップ用のデータ
class CampusMapItem {
  const CampusMapItem({
    required this.id,
    required this.displayName,
    required this.centerLat,
    required this.centerLng,
    required this.buildings,
  });

  final String id;
  final String displayName;
  final double centerLat;
  final double centerLng;
  final List<BuildingMarker> buildings;
}

/// キャンパスマップの全体データ
class CampusMapData {
  const CampusMapData({required this.campuses});
  final List<CampusMapItem> campuses;
}

/// 校舎の教室一覧
class BuildingRooms {
  const BuildingRooms({
    required this.campusId,
    required this.buildingId,
    required this.buildingName,
    required this.floors,
  });

  final String campusId;
  final String buildingId;
  final String buildingName;
  final List<FloorInfo> floors;

  factory BuildingRooms.fromJson(Map<String, dynamic> json) {
    return BuildingRooms(
      campusId: json['campusId'] as String,
      buildingId: json['buildingId'] as String,
      buildingName: json['buildingName'] as String,
      floors: (json['floors'] as List<dynamic>?)
              ?.map((e) => FloorInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// 全教室をフラットに取得
  List<RoomInfo> get allRooms {
    return floors.expand((f) => f.rooms).toList();
  }
}
