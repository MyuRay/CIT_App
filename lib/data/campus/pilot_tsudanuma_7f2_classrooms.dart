import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesTsudanuma7F2AppFloorMap(CampusClassroomLocation room) {
  return room.campus == 'tsudanuma' &&
      room.buildingId == '7' &&
      room.floor == 2;
}

/// 津田沼7号館2階（アプリ同梱フロア図、正規化座標 0〜1・左上原点）。
/// 西側 721／東側 722 の演習室とその他の部屋。
List<CampusClassroomLocation> get pilotTsudanumaBuilding7Floor2 => [
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 2,
    roomCode: '070202',
    searchTerms: [
      '070202',
      '70202',
      '０７０２０２',
      '070202号室',
      '070202号',
      'pc自習',
      'ＰＣ自習',
      '演習準備室',
      '準備室',
    ],
    pinX: 0.78,
    pinY: 0.17,
    description: '2階・PC自習室／演習準備室',
    pinLabel: 'PC自習室／演習準備室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 2,
    roomCode: '070203',
    searchTerms: [
      '070203',
      '70203',
      '０７０２０３',
      '070203号室',
      '070203号',
      '722',
      '７２２',
      '722演習',
      '722 演習',
      '722演習室',
      '7号館722',
    ],
    pinX: 0.78,
    pinY: 0.45,
    description: '2階・722演習室（東側）',
    pinLabel: '722 演習室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 2,
    roomCode: '070205',
    searchTerms: [
      '070205',
      '70205',
      '０７０２０５',
      '070205号室',
      '070205号',
      '721',
      '７２１',
      '721演習',
      '721 演習',
      '721演習室',
      '7号館721',
    ],
    pinX: 0.21,
    pinY: 0.45,
    description: '2階・721演習室（西側）',
    pinLabel: '721 演習室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 2,
    roomCode: '070204',
    searchTerms: [
      '070204',
      '70204',
      '０７０２０４',
      '070204号室',
      '070204号',
      'サーバ室',
      'サーバー室',
    ],
    pinX: 0.48,
    pinY: 0.84,
    description: '2階・サーバ室',
    pinLabel: 'サーバ室',
  ),
];

List<CampusClassroomLocation> searchPilotTsudanuma7f2(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) => pilotLocationMatchesQuery(r, q);
  return pilotTsudanumaBuilding7Floor2.where(matches).toList();
}
