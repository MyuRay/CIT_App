import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

/// 新習志野2号館1階は Firebase Storage ではなくアプリ内アセットのフロア図を使う。
bool usesNarashino2F1AppSchematic(CampusClassroomLocation room) {
  return room.campus == 'narashino' &&
      room.buildingId == '2' &&
      room.floor == 1;
}

/// 新習志野2号館1階（示意図上の正規化座標 0〜1）。
const List<CampusClassroomLocation> pilotNarashinoBuilding2Floor1 = [
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '2',
    buildingDisplayName: '2号館',
    floor: 1,
    roomCode: '教育センター事務局',
    searchTerms: [
      '教育センター事務所',
      '教育センター事務局',
      '教育センター',
      '事務局',
      '事務所',
    ],
    pinX: 0.5,
    pinY: 0.75,
    description: '2号館1階 教育センター事務局エリア（フロア図の緑色ブロック中央付近）',
  ),
];

/// [pilotNarashinoBuilding2Floor1] をクエリで絞り込み（大文字小文字無視）。
List<CampusClassroomLocation> searchPilotNarashino2f1(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];

  bool matches(CampusClassroomLocation r) => pilotLocationMatchesQuery(r, q);

  return pilotNarashinoBuilding2Floor1.where(matches).toList();
}
