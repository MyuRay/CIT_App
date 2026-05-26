import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesNarashino12F3AppSchematic(CampusClassroomLocation room) {
  return room.campus == 'narashino' &&
      room.buildingId == '12' &&
      room.floor == 3;
}

/// 新習志野12号館3階（同梱フロア図、正規化座標 0〜1・左上原点）。
/// 緑の実習系区画のみ。廊下・トイレ・階段・エレベータ等は検索しない。
const List<CampusClassroomLocation> pilotNarashinoBuilding12Floor3 = [
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '12',
    buildingDisplayName: '12号館',
    floor: 3,
    roomCode: '工作実習室',
    searchTerms: [
      '工作実習室',
      'こうさくじっしつ',
      '工作',
      '12号館 工作実習室',
      '12号館3階工作実習室',
    ],
    pinX: 0.27,
    pinY: 0.17,
    description: '12号館3階・工作実習室',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '12',
    buildingDisplayName: '12号館',
    floor: 3,
    roomCode: '教室棟実習室2',
    searchTerms: [
      '教室棟実習室2',
      '教室棟実習室２',
      '教室 棟 実習室 2',
      '教室 棟 実習室２',
      '実習室2',
      '実習室２',
      '教室棟 実習室2',
      '12号館 実習室2',
      '12号館3階教室兼棟実習室2',
      '12号館3階教室兼棟実習室２',
    ],
    pinX: 0.62,
    pinY: 0.23,
    description: '12号館3階・教室棟実習室2',
    pinLabel: '教室棟 実習室2',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '12',
    buildingDisplayName: '12号館',
    floor: 3,
    roomCode: '教室棟実習室1',
    searchTerms: [
      '教室棟実習室1',
      '教室棟実習室１',
      '教室 棟 実習室 1',
      '教室 棟 実習室１',
      '実習室1',
      '実習室１',
      '教室棟 実習室1',
      '12号館 実習室1',
      '12号館3階教室兼棟実習室1',
      '12号館3階教室兼棟実習室１',
    ],
    pinX: 0.52,
    pinY: 0.80,
    description: '12号館3階・教室棟実習室1',
    pinLabel: '教室棟 実習室1',
  ),
];

List<CampusClassroomLocation> searchPilotNarashino12f3(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) =>
      pilotLocationMatchesQuery(r, q);
  return pilotNarashinoBuilding12Floor3.where(matches).toList();
}
