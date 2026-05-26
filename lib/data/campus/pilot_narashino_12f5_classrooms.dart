import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesNarashino12F5AppSchematic(CampusClassroomLocation room) {
  return room.campus == 'narashino' &&
      room.buildingId == '12' &&
      room.floor == 5;
}

/// 新習志野12号館5階（同梱フロア図、正規化座標 0〜1・左上原点）。
/// ピン対象は上側の製図室エリアのみ。
///
/// 正式名称は「各科共同製図室」。共用・共有は誤記として検索だけ拾う。
const List<CampusClassroomLocation> pilotNarashinoBuilding12Floor5 = [
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '12',
    buildingDisplayName: '12号館',
    floor: 5,
    roomCode: '各科共同製図室',
    searchTerms: [
      '各科共同製図室',
      '各科 共同 製図室',
      '12号館5階各科共同製図室',
      '12号館５階各科共同製図室',
      '12号館 5階 各科共同製図室',
      '各科共用製図室',
      '各科共有製図室',
      '製図室',
      'せいずしつ',
      '共同製図室',
    ],
    pinX: 0.50,
    pinY: 0.25,
    description: '12号館5階・各科共同製図室（北側・アーチ側・目安）',
  ),
];

List<CampusClassroomLocation> searchPilotNarashino12f5(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) =>
      pilotLocationMatchesQuery(r, q);
  return pilotNarashinoBuilding12Floor5.where(matches).toList();
}
