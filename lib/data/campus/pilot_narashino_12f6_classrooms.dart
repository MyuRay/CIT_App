import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesNarashino12F6AppSchematic(CampusClassroomLocation room) {
  return room.campus == 'narashino' &&
      room.buildingId == '12' &&
      room.floor == 6;
}

/// 新習志野12号館6階（同梱フロア図、正規化座標 0〜1・左上原点）。
/// ピン対象は上側の製図室エリアのみ。会議室・トイレ等はリストにしない。
///
/// 正式名称は「各科共同製図室」。検索では誤記の「共用」「共有」も許容する。
const List<CampusClassroomLocation> pilotNarashinoBuilding12Floor6 = [
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '12',
    buildingDisplayName: '12号館',
    floor: 6,
    roomCode: '各科共同製図室',
    searchTerms: [
      '各科共同製図室',
      '各科 共同 製図室',
      '12号館6階各科共同製図室',
      '12号館６階各科共同製図室',
      '12号館 6階 各科共同製図室',
      '各科共用製図室',
      '製図室',
      'せいずしつ',
      '共同製図室',
    ],
    pinX: 0.50,
    pinY: 0.26,
    description: '12号館6階・各科共同製図室（アーチ側の広いエリア・目安）',
  ),
];

List<CampusClassroomLocation> searchPilotNarashino12f6(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) =>
      pilotLocationMatchesQuery(r, q);
  return pilotNarashinoBuilding12Floor6.where(matches).toList();
}
