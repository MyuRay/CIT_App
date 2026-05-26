import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesNarashino3F3AppSchematic(CampusClassroomLocation room) {
  return room.campus == 'narashino' &&
      room.buildingId == '3' &&
      room.floor == 3;
}

/// 新習志野3号館3階（アプリ同梱フロア図、正規化座標 0〜1・左上原点）。
/// **教室番号と施設名称の両方が図にある区画のみ**検索・ピンに含める。
const List<CampusClassroomLocation> pilotNarashinoBuilding3Floor3 = [
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '3',
    buildingDisplayName: '3号館',
    floor: 3,
    roomCode: '3301',
    searchTerms: [
      '3301',
      '03301',
      '３３０１',
      '3301号室',
      '3301号',
      '物理第1実験室',
      '物理第１実験室',
      '物理第１実験',
    ],
    pinX: 0.09,
    pinY: 0.08,
    description: '3号館3階・物理第1実験室',
    pinLabel: '物理第1実験室',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '3',
    buildingDisplayName: '3号館',
    floor: 3,
    roomCode: '3302',
    searchTerms: [
      '3302',
      '03302',
      '３３０２',
      '3302号室',
      '3302号',
      '物理第2実験室',
      '物理第２実験室',
    ],
    pinX: 0.26,
    pinY: 0.08,
    description: '3号館3階・物理第2実験室',
    pinLabel: '物理第2実験室',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '3',
    buildingDisplayName: '3号館',
    floor: 3,
    roomCode: '3303',
    searchTerms: [
      '3303',
      '03303',
      '３３０３',
      '3303号室',
      '3303号',
      '物理第4実験室',
      '物理第４実験室',
    ],
    pinX: 0.41,
    pinY: 0.08,
    description: '3号館3階・物理第4実験室（3303）',
    pinLabel: '物理第4実験室',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '3',
    buildingDisplayName: '3号館',
    floor: 3,
    roomCode: '3304',
    searchTerms: [
      '3304',
      '03304',
      '３３０４',
      '3304号室',
      '3304号',
      '物理第3実験室',
      '物理第３実験室',
    ],
    pinX: 0.51,
    pinY: 0.08,
    description: '3号館3階・物理第3実験室',
    pinLabel: '物理第3実験室',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '3',
    buildingDisplayName: '3号館',
    floor: 3,
    roomCode: '3305',
    searchTerms: [
      '3305',
      '03305',
      '３３０５',
      '3305号室',
      '3305号',
      '物理第4実験室',
      '物理第４実験室',
    ],
    pinX: 0.70,
    pinY: 0.08,
    description: '3号館3階・物理第4実験室（3305）',
    pinLabel: '物理第4実験室',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '3',
    buildingDisplayName: '3号館',
    floor: 3,
    roomCode: '3306',
    searchTerms: [
      '3306',
      '03306',
      '３３０６',
      '3306号室',
      '3306号',
      '製図研究室',
      'せいず',
    ],
    pinX: 0.83,
    pinY: 0.05,
    description: '3号館3階・製図研究室',
    pinLabel: '製図研究室',
    pinMarkerScale: 0.7,
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '3',
    buildingDisplayName: '3号館',
    floor: 3,
    roomCode: '3307',
    searchTerms: [
      '3307',
      '03307',
      '３３０７',
      '3307号室',
      '3307号',
      '製図室',
      '製図',
    ],
    pinX: 0.86,
    pinY: 0.68,
    description: '3号館3階・製図室',
    pinLabel: '製図室',
  ),
];

List<CampusClassroomLocation> searchPilotNarashino3f3(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];

  bool matches(CampusClassroomLocation r) => pilotLocationMatchesQuery(r, q);

  return pilotNarashinoBuilding3Floor3.where(matches).toList();
}
