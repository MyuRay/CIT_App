import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesTsudanuma7F9AppFloorMap(CampusClassroomLocation room) {
  return room.campus == 'tsudanuma' &&
      room.buildingId == '7' &&
      room.floor == 9;
}

/// 津田沼7号館9階（アプリ同梱フロア図、正規化座標 0〜1・左上原点）。
///
/// **図面上で施設名と0709xxの両方がある区画のみ**検索対象。アトリウム・ラウンジ・倉庫等は載せない。
/// 施設名は図の表記を省略しない。
///
/// 8階と平面が似ているため、8階パイロットのリスト順に対応する区画へ**同じ** `pinX` /
/// `pinY` / `pinMarkerScale` を割り当てている。
List<CampusClassroomLocation> get pilotTsudanumaBuilding7Floor9 => [
  _tsudanuma7f9Entry(
    '070901',
    '情報工学科 オフィス',
    pinX: 0.81,
    pinY: 0.10,
    pinMarkerScale: 0.74,
  ),
  _tsudanuma7f9Entry(
    '070902',
    '情報工学科 ラボ',
    pinX: 0.74,
    pinY: 0.22,
    pinMarkerScale: 0.74,
  ),
  _tsudanuma7f9Entry(
    '070903',
    '情報工学科 ラボ',
    pinX: 0.86,
    pinY: 0.34,
    pinMarkerScale: 0.74,
  ),
  _tsudanuma7f9Entry(
    '070904',
    '情報工学科 オフィス',
    pinX: 0.80,
    pinY: 0.46,
    pinMarkerScale: 0.74,
  ),
  _tsudanuma7f9Entry(
    '070905',
    '情報工学科 オフィス',
    pinX: 0.80,
    pinY: 0.55,
    pinMarkerScale: 0.72,
  ),
  _tsudanuma7f9Entry(
    '070906',
    '情報工学科 ラボ',
    pinX: 0.75,
    pinY: 0.66,
    pinMarkerScale: 0.72,
  ),
  _tsudanuma7f9Entry(
    '070907',
    '情報工学科 ラボ',
    pinX: 0.86,
    pinY: 0.79,
    pinMarkerScale: 0.74,
  ),
  _tsudanuma7f9Entry(
    '070908',
    '情報工学科 オフィス',
    pinX: 0.20,
    pinY: 0.81,
    pinMarkerScale: 0.74,
  ),
  _tsudanuma7f9Entry(
    '070909',
    '情報工学科 第三実習室',
    pinX: 0.27,
    pinY: 0.73,
    pinMarkerScale: 0.70,
  ),
  _tsudanuma7f9Entry(
    '070910',
    '情報工学科 ラボ',
    pinX: 0.14,
    pinY: 0.66,
    pinMarkerScale: 0.74,
  ),
  _tsudanuma7f9Entry(
    '070911',
    '情報工学科 オフィス',
    pinX: 0.19,
    pinY: 0.54,
    pinMarkerScale: 0.74,
  ),
  _tsudanuma7f9Entry(
    '070912',
    '情報工学科 オフィス',
    pinX: 0.20,
    pinY: 0.45,
    pinMarkerScale: 0.74,
  ),
  _tsudanuma7f9Entry(
    '070913',
    '情報工学科 ラボ',
    pinX: 0.14,
    pinY: 0.33,
    pinMarkerScale: 0.74,
  ),
  _tsudanuma7f9Entry(
    '070914',
    '認知情報科学科 ラボ',
    pinX: 0.29,
    pinY: 0.16,
    pinMarkerScale: 0.74,
  ),
  _tsudanuma7f9Entry(
    '070915',
    '認知情報科学科 オフィス',
    pinX: 0.13,
    pinY: 0.13,
    pinMarkerScale: 0.74,
  ),
];

const Map<String, String> _zw9 = {
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
    (m) => _zw9[m[0]]!,
  );
}

CampusClassroomLocation _tsudanuma7f9Entry(
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
    ...extraSearchTerms,
  ];

  return CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 9,
    roomCode: roomCode,
    searchTerms: searchTerms,
    pinX: pinX,
    pinY: pinY,
    description: '9階・$roomCode $pinLabelFull',
    pinLabel: pinLabelFull,
    pinMarkerScale: pinMarkerScale,
  );
}

List<CampusClassroomLocation> searchPilotTsudanuma7f9(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) => pilotLocationMatchesQuery(r, q);
  return pilotTsudanumaBuilding7Floor9.where(matches).toList();
}
