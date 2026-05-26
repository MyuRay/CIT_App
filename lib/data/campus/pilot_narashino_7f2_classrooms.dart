import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesNarashino7F2AppSchematic(CampusClassroomLocation room) {
  return room.campus == 'narashino' &&
      room.buildingId == '7' &&
      room.floor == 2;
}

/// 新習志野7号館2階（同梱フロア図、正規化座標 0〜1・左上原点）。
/// 図面に室番と名称がある講義室のみ（7201〜7206）。階段・EV・WC等は検索対象外。
const List<CampusClassroomLocation> pilotNarashinoBuilding7Floor2 = [
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 2,
    roomCode: '7204',
    searchTerms: [
      '7204',
      '07204',
      '７２０４',
      '7204号室',
      '7204号',
      '7204講義室',
      '講義室7204',
      '7204 講義室',
    ],
    pinX: 0.10,
    pinY: 0.14,
    description: '7号館2階・7204講義室',
    pinLabel: '7204講義室',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 2,
    roomCode: '7205',
    searchTerms: [
      '7205',
      '07205',
      '７２０５',
      '7205号室',
      '7205号',
      '7205講義室',
      '講義室7205',
      '7205 講義室',
    ],
    pinX: 0.50,
    pinY: 0.15,
    description: '7号館2階・7205講義室',
    pinLabel: '7205講義室',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 2,
    roomCode: '7206',
    searchTerms: [
      '7206',
      '07206',
      '７２０６',
      '7206号室',
      '7206号',
      '7206講義室',
      '講義室7206',
      '7206 講義室',
    ],
    pinX: 0.90,
    pinY: 0.14,
    description: '7号館2階・7206講義室',
    pinLabel: '7206講義室',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 2,
    roomCode: '7203',
    searchTerms: [
      '7203',
      '07203',
      '７２０３',
      '7203号室',
      '7203号',
      '7203講義室',
      '講義室7203',
      '7203 講義室',
    ],
    pinX: 0.10,
    pinY: 0.78,
    description: '7号館2階・7203講義室',
    pinLabel: '7203講義室',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 2,
    roomCode: '7202',
    searchTerms: [
      '7202',
      '07202',
      '７２０２',
      '7202号室',
      '7202号',
      '7202講義室',
      '講義室7202',
      '7202 講義室',
    ],
    pinX: 0.50,
    pinY: 0.79,
    description: '7号館2階・7202講義室',
    pinLabel: '7202講義室',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 2,
    roomCode: '7201',
    searchTerms: [
      '7201',
      '07201',
      '７２０１',
      '7201号室',
      '7201号',
      '7201講義室',
      '講義室7201',
      '7201 講義室',
    ],
    pinX: 0.89,
    pinY: 0.77,
    description: '7号館2階・7201講義室',
    pinLabel: '7201講義室',
  ),
];

List<CampusClassroomLocation> searchPilotNarashino7f2(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) => pilotLocationMatchesQuery(r, q);
  return pilotNarashinoBuilding7Floor2.where(matches).toList();
}
