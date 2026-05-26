import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesNarashino7F1AppSchematic(CampusClassroomLocation room) {
  return room.campus == 'narashino' &&
      room.buildingId == '7' &&
      room.floor == 1;
}

/// 新習志野7号館1階（同梱フロア図、正規化座標 0〜1・左上原点）。
/// 図面に室番と名称がある講義室のみ（7101〜7105）。階段・EV・WC等は検索対象外。
const List<CampusClassroomLocation> pilotNarashinoBuilding7Floor1 = [
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 1,
    roomCode: '7104',
    searchTerms: [
      '7104',
      '07104',
      '７１０４',
      '7104号室',
      '7104号',
      '7104講義室',
      '講義室7104',
      '7104 講義室',
    ],
    pinX: 0.20,
    pinY: 0.10,
    description: '7号館1階・7104講義室',
    pinLabel: '7104講義室',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 1,
    roomCode: '7105',
    searchTerms: [
      '7105',
      '07105',
      '７１０５',
      '7105号室',
      '7105号',
      '7105講義室',
      '講義室7105',
      '7105 講義室',
    ],
    pinX: 0.79,
    pinY: 0.10,
    description: '7号館1階・7105講義室',
    pinLabel: '7105講義室',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 1,
    roomCode: '7103',
    searchTerms: [
      '7103',
      '07103',
      '７１０３',
      '7103号室',
      '7103号',
      '7103講義室',
      '講義室7103',
      '7103 講義室',
    ],
    pinX: 0.17,
    pinY: 0.75,
    description: '7号館1階・7103講義室',
    pinLabel: '7103講義室',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 1,
    roomCode: '7102',
    searchTerms: [
      '7102',
      '07102',
      '７１０２',
      '7102号室',
      '7102号',
      '7102講義室',
      '講義室7102',
      '7102 講義室',
    ],
    pinX: 0.50,
    pinY: 0.75,
    description: '7号館1階・7102講義室',
    pinLabel: '7102講義室',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 1,
    roomCode: '7101',
    searchTerms: [
      '7101',
      '07101',
      '７１０１',
      '7101号室',
      '7101号',
      '7101講義室',
      '講義室7101',
      '7101 講義室',
    ],
    pinX: 0.75,
    pinY: 0.78,
    description: '7号館1階・7101講義室',
    pinLabel: '7101講義室',
  ),
];

List<CampusClassroomLocation> searchPilotNarashino7f1(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) => pilotLocationMatchesQuery(r, q);
  return pilotNarashinoBuilding7Floor1.where(matches).toList();
}
