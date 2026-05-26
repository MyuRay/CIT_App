import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesNarashino12F1AppSchematic(CampusClassroomLocation room) {
  return room.campus == 'narashino' &&
      room.buildingId == '12' &&
      room.floor == 1;
}

/// 新習志野12号館1階（同梱フロア図、正規化座標 0〜1・左上原点）。
/// 緑・主要施設として載せたい区画のみ（事務室・保健室）。学生ホール・共有ホール・トイレ等は検索しない。
const List<CampusClassroomLocation> pilotNarashinoBuilding12Floor1 = [
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '12',
    buildingDisplayName: '12号館',
    floor: 1,
    roomCode: '事務室',
    searchTerms: [
      '事務室',
      'じむしつ',
      '事務',
      '12号館事務室',
      '12号館 事務室',
    ],
    pinX: 0.38,
    pinY: 0.79,
    description: '12号館1階・事務室',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '12',
    buildingDisplayName: '12号館',
    floor: 1,
    roomCode: '保健室',
    searchTerms: [
      '保健室',
      'ほけんしつ',
      '保健',
      '12号館保健室',
      '12号館 保健室',
    ],
    pinX: 0.82,
    pinY: 0.84,
    description: '12号館1階・保健室',
  ),
];

List<CampusClassroomLocation> searchPilotNarashino12f1(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) =>
      pilotLocationMatchesQuery(r, q);
  return pilotNarashinoBuilding12Floor1.where(matches).toList();
}
