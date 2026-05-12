import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesTsudanuma7F7AppFloorMap(CampusClassroomLocation room) {
  return room.campus == 'tsudanuma' &&
      room.buildingId == '7' &&
      room.floor == 7;
}

/// 津田沼7号館7階（アプリ同梱フロア図、正規化座標 0〜1・左上原点）。
///
/// **図面上で施設名と0707xxの両方がある区画のみ**検索対象。アトリウム・ラウンジ・倉庫等は載せない。
/// 施設名は図の表記を省略しない。
List<CampusClassroomLocation> get pilotTsudanumaBuilding7Floor7 => [
  _tsudanuma7f7Entry(
    '070701',
    '情報ネットワーク学科 第12研究室',
    pinX: 0.78,
    pinY: 0.14,
    pinMarkerScale: 0.66,
  ),
  _tsudanuma7f7Entry(
    '070702',
    '情報ネットワーク学科 準備室',
    pinX: 0.72,
    pinY: 0.33,
    pinMarkerScale: 0.62,
  ),
  _tsudanuma7f7Entry(
    '070703',
    '情報ネットワーク学科 第2ゼミ室',
    pinX: 0.85,
    pinY: 0.33,
    pinMarkerScale: 0.62,
  ),
  _tsudanuma7f7Entry(
    '070704',
    '情報ネットワーク学科 ネットワーク・メディア実験室',
    pinX: 0.76,
    pinY: 0.60,
    pinMarkerScale: 0.54,
  ),
  _tsudanuma7f7Entry(
    '070705',
    '情報ネットワーク学科 CG演習室',
    pinX: 0.78,
    pinY: 0.80,
    pinMarkerScale: 0.64,
  ),
  _tsudanuma7f7Entry(
    '070706',
    '情報工学科 第一実験室',
    pinX: 0.18,
    pinY: 0.69,
    pinMarkerScale: 0.70,
  ),
  _tsudanuma7f7Entry(
    '070707',
    '情報工学科 実験準備室',
    pinX: 0.18,
    pinY: 0.47,
    pinMarkerScale: 0.62,
  ),
  _tsudanuma7f7Entry(
    '070708',
    '情報工学科 準備室',
    pinX: 0.26,
    pinY: 0.34,
    pinMarkerScale: 0.64,
  ),
  _tsudanuma7f7Entry(
    '070709',
    '情報科学専攻 情報工学ゼミ室',
    pinX: 0.13,
    pinY: 0.34,
    pinMarkerScale: 0.58,
  ),
  _tsudanuma7f7Entry(
    '070710',
    '情報工学科 第一実習室',
    pinX: 0.21,
    pinY: 0.13,
    pinMarkerScale: 0.62,
  ),
];

const Map<String, String> _zw7 = {
  '0': '０',
  '1': '１',
  '2': '２',
  '3': '３',
  '4': '４',
  '5': '５',
  '6': '６',
  '7': '７',
  '8': '８',
  '9': '９',
};

String _zenRoomCode(String roomCode) {
  return roomCode.replaceAllMapped(
    RegExp(r'\d'),
    (m) => _zw7[m[0]]!,
  );
}

CampusClassroomLocation _tsudanuma7f7Entry(
  String roomCode,
  String pinLabelFull, {
  required double pinX,
  required double pinY,
  List<String> extraSearchTerms = const [],
  double pinMarkerScale = 1.0,
}) {
  final digitShort = roomCode.substring(1);
  final zenRoom = _zenRoomCode(roomCode);
  final searchTerms = <String>[
    roomCode,
    digitShort,
    zenRoom,
    '$roomCode号室',
    '$roomCode号',
    pinLabelFull,
  ]
    ..addAll(extraSearchTerms);

  return CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 7,
    roomCode: roomCode,
    searchTerms: searchTerms,
    pinX: pinX,
    pinY: pinY,
    description: '7階・$roomCode $pinLabelFull',
    pinLabel: pinLabelFull,
    pinMarkerScale: pinMarkerScale,
  );
}

List<CampusClassroomLocation> searchPilotTsudanuma7f7(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) => pilotLocationMatchesQuery(r, q);
  return pilotTsudanumaBuilding7Floor7.where(matches).toList();
}
