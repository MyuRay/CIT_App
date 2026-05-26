import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesTsudanuma6F5AppFloorMap(CampusClassroomLocation room) {
  return room.campus == 'tsudanuma' &&
      room.buildingId == '6' &&
      room.floor == 5;
}

/// 津田沼6号館5階（アプリ同梱フロア図、正規化座標 0〜1・左上原点）。
/// 651〜654（北側）、655〜656（南側）。ピンは区画中央の目安。
List<CampusClassroomLocation> get pilotTsudanumaBuilding6Floor5 => [
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '6',
    buildingDisplayName: '6号館',
    floor: 5,
    roomCode: '060551',
    searchTerms: [
      '060551',
      '60551',
      '０６０５５１',
      '060551号室',
      '060551号',
      '651',
      '６５１',
      '651講義室',
      '651 講義室',
      '六号館651',
      '6号館651',
    ],
    pinX: 0.11,
    pinY: 0.14,
    description: '5階・651 講義室',
    pinLabel: '651 講義室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '6',
    buildingDisplayName: '6号館',
    floor: 5,
    roomCode: '060552',
    searchTerms: [
      '060552',
      '60552',
      '０６０５５２',
      '060552号室',
      '060552号',
      '652',
      '６５２',
      '652講義室',
      '652 講義室',
      '六号館652',
      '6号館652',
    ],
    pinX: 0.29,
    pinY: 0.14,
    description: '5階・652 講義室',
    pinLabel: '652 講義室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '6',
    buildingDisplayName: '6号館',
    floor: 5,
    roomCode: '060553',
    searchTerms: [
      '060553',
      '60553',
      '０６０５５３',
      '060553号室',
      '060553号',
      '653',
      '６５３',
      '653講義室',
      '653 講義室',
      '六号館653',
      '6号館653',
    ],
    pinX: 0.53,
    pinY: 0.14,
    description: '5階・653 講義室',
    pinLabel: '653 講義室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '6',
    buildingDisplayName: '6号館',
    floor: 5,
    roomCode: '060554',
    searchTerms: [
      '060554',
      '60554',
      '０６０５５４',
      '060554号室',
      '060554号',
      '654',
      '６５４',
      '654講義室',
      '654 講義室',
      '六号館654',
      '6号館654',
    ],
    pinX: 0.75,
    pinY: 0.14,
    description: '5階・654 講義室',
    pinLabel: '654 講義室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '6',
    buildingDisplayName: '6号館',
    floor: 5,
    roomCode: '060555',
    searchTerms: [
      '060555',
      '60555',
      '０６０５５５',
      '060555号室',
      '060555号',
      '655',
      '６５５',
      '655講義室',
      '655 講義室',
      '六号館655',
      '6号館655',
    ],
    pinX: 0.67,
    pinY: 0.78,
    description: '5階・655 講義室',
    pinLabel: '655 講義室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '6',
    buildingDisplayName: '6号館',
    floor: 5,
    roomCode: '060556',
    searchTerms: [
      '060556',
      '60556',
      '０６０５５６',
      '060556号室',
      '060556号',
      '656',
      '６５６',
      '656講義室',
      '656 講義室',
      '六号館656',
      '6号館656',
    ],
    pinX: 0.37,
    pinY: 0.78,
    description: '5階・656 講義室',
    pinLabel: '656 講義室',
  ),
];

List<CampusClassroomLocation> searchPilotTsudanuma6F5(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) => pilotLocationMatchesQuery(r, q);
  return pilotTsudanumaBuilding6Floor5.where(matches).toList();
}
