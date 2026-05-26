import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesTsudanuma6F1AppFloorMap(CampusClassroomLocation room) {
  return room.campus == 'tsudanuma' &&
      room.buildingId == '6' &&
      room.floor == 1;
}

/// 津田沼6号館1階（アプリ同梱フロア図、正規化座標 0〜1・左上原点）。
/// 図面上の区画中心付近の目安。必要に応じて [pinX]/[pinY] を微調整してください。
/// 部屋コードは `06` + `01`（階） + 2 桁の並び（070101 系と同様）で仮置きしています。
List<CampusClassroomLocation> get pilotTsudanumaBuilding6Floor1 => [
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '6',
    buildingDisplayName: '6号館',
    floor: 1,
    roomCode: '060111',
    searchTerms: [
      '060111',
      '60111',
      '０６０１１１',
      '060111号室',
      '060111号',
      '611',
      '６１１',
      '611講義室',
      '611 講義室',
      '六号館611',
      '6号館611',
    ],
    pinX: 0.32,
    pinY: 0.16,
    description: '1階・611 講義室',
    pinLabel: '611 講義室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '6',
    buildingDisplayName: '6号館',
    floor: 1,
    roomCode: '060112',
    searchTerms: [
      '060112',
      '60112',
      '０６０１１２',
      '060112号室',
      '060112号',
      '612',
      '６１２',
      '612講義室',
      '612 講義室',
      '六号館612',
      '6号館612',
    ],
    pinX: 0.58,
    pinY: 0.16,
    description: '1階・612 講義室',
    pinLabel: '612 講義室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '6',
    buildingDisplayName: '6号館',
    floor: 1,
    roomCode: '060113',
    searchTerms: [
      '060113',
      '60113',
      '０６０１１３',
      '060113号室',
      '060113号',
      '613',
      '６１３',
      '613講義室',
      '613 講義室',
      '六号館613',
      '6号館613',
    ],
    pinX: 0.79,
    pinY: 0.16,
    description: '1階・613 講義室',
    pinLabel: '613 講義室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '6',
    buildingDisplayName: '6号館',
    floor: 1,
    roomCode: '060114',
    searchTerms: [
      '060114',
      '60114',
      '０６０１１４',
      '060114号室',
      '060114号',
      '614',
      '６１４',
      '614講義室',
      '614 講義室',
      '六号館614',
      '6号館614',
    ],
    pinX: 0.61,
    pinY: 0.77,
    description: '1階・614 講義室',
    pinLabel: '614 講義室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '6',
    buildingDisplayName: '6号館',
    floor: 1,
    roomCode: '060115',
    searchTerms: [
      '060115',
      '60115',
      '０６０１１５',
      '060115号室',
      '060115号',
      '615',
      '６１５',
      '615講義室',
      '615 講義室',
      '六号館615',
      '6号館615',
    ],
    pinX: 0.32,
    pinY: 0.77,
    description: '1階・615 講義室',
    pinLabel: '615 講義室',
  ),
];

List<CampusClassroomLocation> searchPilotTsudanuma6F1(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) => pilotLocationMatchesQuery(r, q);
  return pilotTsudanumaBuilding6Floor1.where(matches).toList();
}
