import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesNarashino5F3AppSchematic(CampusClassroomLocation room) {
  return room.campus == 'narashino' &&
      room.buildingId == '5' &&
      room.floor == 3;
}

/// 新習志野5号館3階（同梱フロア図、正規化座標 0〜1・左上原点）。
/// 講義室 `5301`〜`5308` は検索タブに出す。インターネットルーム・トイレは同一リストに含めるが `searchPilotNarashino5f3` で除外する。
const List<CampusClassroomLocation> pilotNarashinoBuilding5Floor3 = [
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '5',
    buildingDisplayName: '5号館',
    floor: 3,
    roomCode: '5301',
    searchTerms: [
      '5301',
      '05301',
      '５３０１',
      '5301号室',
      '5301号',
      '5301講義室',
      '講義室5301',
      '5301 講義室',
    ],
    pinX: 0.68,
    pinY: 0.86,
    description: '5号館3階・5301（講義室）',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '5',
    buildingDisplayName: '5号館',
    floor: 3,
    roomCode: '5302',
    searchTerms: [
      '5302',
      '05302',
      '５３０２',
      '5302号室',
      '5302号',
      '5302講義室',
      '講義室5302',
      '5302 講義室',
    ],
    pinX: 0.57,
    pinY: 0.86,
    description: '5号館3階・5302（講義室）',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '5',
    buildingDisplayName: '5号館',
    floor: 3,
    roomCode: '5303',
    searchTerms: [
      '5303',
      '05303',
      '５３０３',
      '5303号室',
      '5303号',
      '5303講義室',
      '講義室5303',
      '5303 講義室',
    ],
    pinX: 0.46,
    pinY: 0.86,
    description: '5号館3階・5303（講義室）',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '5',
    buildingDisplayName: '5号館',
    floor: 3,
    roomCode: '5304',
    searchTerms: [
      '5304',
      '05304',
      '５３０４',
      '5304号室',
      '5304号',
      '5304講義室',
      '講義室5304',
      '5304 講義室',
    ],
    pinX: 0.35,
    pinY: 0.86,
    description: '5号館3階・5304（講義室）',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '5',
    buildingDisplayName: '5号館',
    floor: 3,
    roomCode: '5305',
    searchTerms: [
      '5305',
      '05305',
      '５３０５',
      '5305号室',
      '5305号',
      '5305講義室',
      '講義室5305',
      '5305 講義室',
    ],
    pinX: 0.24,
    pinY: 0.86,
    description: '5号館3階・5305（講義室）',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '5',
    buildingDisplayName: '5号館',
    floor: 3,
    roomCode: '5306',
    searchTerms: [
      '5306',
      '05306',
      '５３０６',
      '5306号室',
      '5306号',
      '5306講義室',
      '講義室5306',
      '5306 講義室',
    ],
    pinX: 0.28,
    pinY: 0.05,
    description: '5号館3階・5306（講義室）',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '5',
    buildingDisplayName: '5号館',
    floor: 3,
    roomCode: '5307',
    searchTerms: [
      '5307',
      '05307',
      '５３０７',
      '5307号室',
      '5307号',
      '5307講義室',
      '講義室5307',
      '5307 講義室',
    ],
    pinX: 0.63,
    pinY: 0.05,
    description: '5号館3階・5307（講義室）',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '5',
    buildingDisplayName: '5号館',
    floor: 3,
    roomCode: '5308',
    searchTerms: [
      '5308',
      '05308',
      '５３０８',
      '5308号室',
      '5308号',
      '5308講義室',
      '講義室5308',
      '5308 講義室',
    ],
    pinX: 0.77,
    pinY: 0.05,
    description: '5号館3階・5308（講義室）',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '5',
    buildingDisplayName: '5号館',
    floor: 3,
    roomCode: 'ネットルーム53',
    searchTerms: [
      'インターネットルーム',
      'インターネット',
      'ネットルーム',
    ],
    pinX: 0.42,
    pinY: 0.10,
    description: '5号館3階・インターネットルーム（北側中央付近）',
    pinLabel: 'インターネットルーム',
    pinMarkerScale: 0.78,
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '5',
    buildingDisplayName: '5号館',
    floor: 3,
    roomCode: '女子トイレ53',
    searchTerms: ['女子トイレ', '女性トイレ', '女トイレ', 'wc女'],
    pinX: 0.08,
    pinY: 0.86,
    description: '5号館3階・女子トイレ（南側・5305側）',
    pinLabel: '女子トイレ',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '5',
    buildingDisplayName: '5号館',
    floor: 3,
    roomCode: '男子トイレ53',
    searchTerms: ['男子トイレ', '男性トイレ', '男トイレ', 'wc男'],
    pinX: 0.92,
    pinY: 0.86,
    description: '5号館3階・男子トイレ（南側・5301側）',
    pinLabel: '男子トイレ',
  ),
];

/// 検索タブは講義室（5301〜5308）のみ。
bool _narashino5f3IncludeInMergedPilotSearch(CampusClassroomLocation r) {
  final n = int.tryParse(r.roomCode);
  return n != null && n >= 5301 && n <= 5308;
}

List<CampusClassroomLocation> searchPilotNarashino5f3(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) =>
      pilotLocationMatchesQuery(r, q);
  return pilotNarashinoBuilding5Floor3
      .where(_narashino5f3IncludeInMergedPilotSearch)
      .where(matches)
      .toList();
}
