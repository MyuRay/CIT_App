import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesNarashino12F4AppSchematic(CampusClassroomLocation room) {
  return room.campus == 'narashino' &&
      room.buildingId == '12' &&
      room.floor == 4;
}

/// 新習志野12号館4階（同梱フロア図、正規化座標 0〜1・左上原点）。
/// 緑の工作室のみ。廊下・トイレ・階段・エレベータ等は検索しない。
const List<CampusClassroomLocation> pilotNarashinoBuilding12Floor4 = [
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '12',
    buildingDisplayName: '12号館',
    floor: 4,
    roomCode: '各科共同工作室',
    searchTerms: [
      '各科共同工作室',
      '各科 共同工作室',
      '共同工作室',
      '各科共同',
      '12号館 各科共同工作室',
      '12号館4階各科共同工作室',
      '共通工作室',
    ],
    pinX: 0.53,
    pinY: 0.24,
    description: '12号館4階・各科共同工作室（北側エリア・目安）',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '12',
    buildingDisplayName: '12号館',
    floor: 4,
    roomCode: '学生自由工作室',
    searchTerms: [
      '学生自由工作室',
      '学生 自由工作室',
      '自由工作室',
      '学生工作室',
      '12号館 自由工作室',
      '12号館4階自由工作室',
    ],
    pinX: 0.53,
    pinY: 0.73,
    description: '12号館4階・学生自由工作室（南側エリア・目安）',
  ),
];

List<CampusClassroomLocation> searchPilotNarashino12f4(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) =>
      pilotLocationMatchesQuery(r, q);
  return pilotNarashinoBuilding12Floor4.where(matches).toList();
}
