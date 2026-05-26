import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesTsudanuma7F3AppFloorMap(CampusClassroomLocation room) {
  return room.campus == 'tsudanuma' &&
      room.buildingId == '7' &&
      room.floor == 3;
}

/// 津田沼7号館3階（アプリ同梱フロア図、正規化座標 0〜1・左上原点）。
///
/// 検索には、**公式フロア図上で「用途名」と教室番号（0703xx）の両方が付いている施設のみ**載せる。
/// アトリウム上部・ラウンジなど番号のみ／名称のみのものは載せない。
/// ピン文言の用途名は図面上の表記を省略しない。
List<CampusClassroomLocation> get pilotTsudanumaBuilding7Floor3 => [
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 3,
    roomCode: '070301',
    searchTerms: [
      '070301',
      '70301',
      '０７０３０１',
      '070301号室',
      '070301号',
      '731',
      '７３１',
      '731講義室',
      '731 講義室',
      '講義室731',
      '7号館731',
    ],
    pinX: 0.78,
    pinY: 0.25,
    description: '3階・070301 731講義室',
    pinLabel: '731講義室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 3,
    roomCode: '070302',
    searchTerms: [
      '070302',
      '70302',
      '０７０３０２',
      '070302号室',
      '070302号',
      '732',
      '７３２',
      '732講義室',
      '732 講義室',
      '講義室732',
      '7号館732',
    ],
    pinX: 0.78,
    pinY: 0.60,
    description: '3階・070302 732講義室',
    pinLabel: '732講義室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 3,
    roomCode: '070303',
    searchTerms: [
      '070303',
      '70303',
      '０７０３０３',
      '070303号室',
      '070303号',
      '情報工学科サーバ室',
      '情報工学科サーバー室',
    ],
    pinX: 0.82,
    pinY: 0.82,
    description: '3階・070303 情報工学科サーバ室',
    pinLabel: '情報工学科サーバ室',
    pinMarkerScale: 0.88,
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 3,
    roomCode: '070304',
    searchTerms: [
      '070304',
      '70304',
      '０７０３０４',
      '070304号室',
      '070304号',
      '733',
      '７３３',
      '733演習室',
      '733 演習室',
      '演習室733',
      '7号館733',
    ],
    pinX: 0.22,
    pinY: 0.48,
    description: '3階・070304 733演習室',
    pinLabel: '733演習室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 3,
    roomCode: '070305',
    searchTerms: [
      '070305',
      '70305',
      '０７０３０５',
      '070305号室',
      '070305号',
      '7号館070305',
    ],
    pinX: 0.22,
    pinY: 0.11,
    description: '3階・070305 サーバ室',
    pinLabel: 'サーバ室',
  ),
];

List<CampusClassroomLocation> searchPilotTsudanuma7f3(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) => pilotLocationMatchesQuery(r, q);
  return pilotTsudanumaBuilding7Floor3.where(matches).toList();
}
