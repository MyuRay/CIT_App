import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesTsudanuma6F3AppFloorMap(CampusClassroomLocation room) {
  return room.campus == 'tsudanuma' &&
      room.buildingId == '6' &&
      room.floor == 3;
}

/// 津田沼6号館3階（アプリ同梱フロア図、正規化座標 0〜1・左上原点）。
/// 631〜633（北側）、634〜636（南側）。講師控室はパイロットに含めない。
List<CampusClassroomLocation> get pilotTsudanumaBuilding6Floor3 => [
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '6',
    buildingDisplayName: '6号館',
    floor: 3,
    roomCode: '060331',
    searchTerms: [
      '060331',
      '60331',
      '０６０３３１',
      '060331号室',
      '060331号',
      '631',
      '６３１',
      '631講義室',
      '631 講義室',
      '六号館631',
      '6号館631',
    ],
    pinX: 0.32,
    pinY: 0.13,
    description: '3階・631 講義室',
    pinLabel: '631 講義室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '6',
    buildingDisplayName: '6号館',
    floor: 3,
    roomCode: '060332',
    searchTerms: [
      '060332',
      '60332',
      '０６０３３２',
      '060332号室',
      '060332号',
      '632',
      '６３２',
      '632講義室',
      '632 講義室',
      '六号館632',
      '6号館632',
    ],
    pinX: 0.57,
    pinY: 0.13,
    description: '3階・632 講義室',
    pinLabel: '632 講義室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '6',
    buildingDisplayName: '6号館',
    floor: 3,
    roomCode: '060333',
    searchTerms: [
      '060333',
      '60333',
      '０６０３３３',
      '060333号室',
      '060333号',
      '633',
      '６３３',
      '633講義室',
      '633 講義室',
      '六号館633',
      '6号館633',
    ],
    pinX: 0.78,
    pinY: 0.13,
    description: '3階・633 講義室',
    pinLabel: '633 講義室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '6',
    buildingDisplayName: '6号館',
    floor: 3,
    roomCode: '060334',
    searchTerms: [
      '060334',
      '60334',
      '０６０３３４',
      '060334号室',
      '060334号',
      '634',
      '６３４',
      '634講義室',
      '634 講義室',
      '六号館634',
      '6号館634',
    ],
    pinX: 0.78,
    pinY: 0.77,
    description: '3階・634 講義室',
    pinLabel: '634 講義室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '6',
    buildingDisplayName: '6号館',
    floor: 3,
    roomCode: '060335',
    searchTerms: [
      '060335',
      '60335',
      '０６０３３５',
      '060335号室',
      '060335号',
      '635',
      '６３５',
      '635講義室',
      '635 講義室',
      '六号館635',
      '6号館635',
    ],
    pinX: 0.57,
    pinY: 0.77,
    description: '3階・635 講義室',
    pinLabel: '635 講義室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '6',
    buildingDisplayName: '6号館',
    floor: 3,
    roomCode: '060336',
    searchTerms: [
      '060336',
      '60336',
      '０６０３３６',
      '060336号室',
      '060336号',
      '636',
      '６３６',
      '636講義室',
      '636 講義室',
      '六号館636',
      '6号館636',
    ],
    pinX: 0.32,
    pinY: 0.77,
    description: '3階・636 講義室',
    pinLabel: '636 講義室',
  ),
];

List<CampusClassroomLocation> searchPilotTsudanuma6F3(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) => pilotLocationMatchesQuery(r, q);
  return pilotTsudanumaBuilding6Floor3.where(matches).toList();
}
