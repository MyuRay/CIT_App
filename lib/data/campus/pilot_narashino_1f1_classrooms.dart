import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

/// 新習志野1号館1階は Firebase Storage ではなくアプリ内アセットのフロア図を使う。
bool usesNarashino1F1AppSchematic(CampusClassroomLocation room) {
  return room.campus == 'narashino' &&
      room.buildingId == '1' &&
      room.floor == 1;
}

/// 新習志野1号館1階（フロア図上の正規化座標 0〜1・目安）。
const List<CampusClassroomLocation> pilotNarashinoBuilding1Floor1 = [
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '1',
    buildingDisplayName: '1号館',
    floor: 1,
    roomCode: '1101講義室',
    searchTerms: [
      '1101',
      '01101',
      '1101講義室',
      '１１０１',
      '講義室1101',
      '1101 講義室',
    ],
    pinX: 0.52,
    pinY: 0.32,
    description: '1階 上側の1101講義室エリア（図上の目安）',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '1',
    buildingDisplayName: '1号館',
    floor: 1,
    roomCode: '1102講義室',
    searchTerms: [
      '1102',
      '01102',
      '1102講義室',
      '１１０２',
      '講義室1102',
      '1102 講義室',
    ],
    pinX: 0.72,
    pinY: 0.68,
    description: '1階 右下の1102講義室エリア（図上の目安）',
  ),
];

List<CampusClassroomLocation> searchPilotNarashino1f1(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];

  bool matches(CampusClassroomLocation r) => pilotLocationMatchesQuery(r, q);

  return pilotNarashinoBuilding1Floor1.where(matches).toList();
}
