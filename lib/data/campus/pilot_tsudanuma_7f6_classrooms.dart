import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesTsudanuma7F6AppFloorMap(CampusClassroomLocation room) {
  return room.campus == 'tsudanuma' &&
      room.buildingId == '7' &&
      room.floor == 6;
}

/// 津田沼7号館6階（アプリ同梱フロア図、正規化座標 0〜1・左上原点）。
///
/// **図面上で施設名と0706xxの両方がある区画のみ**検索対象。アトリウム・ラウンジ・倉庫等は載せない。
/// 施設名は図の表記を省略しない。
List<CampusClassroomLocation> get pilotTsudanumaBuilding7Floor6 => [
  _tsudanuma7f6Entry(
    '070601',
    '高度応用情報科学科 ラボ',
    pinX: 0.72,
    pinY: 0.20,
    pinMarkerScale: 0.76,
  ),
  _tsudanuma7f6Entry(
    '070602',
    '高度応用情報科学科 オフィス',
    pinX: 0.85,
    pinY: 0.10,
    pinMarkerScale: 0.76,
  ),
  _tsudanuma7f6Entry(
    '070603',
    '高度応用情報科学科 ラボ',
    pinX: 0.85,
    pinY: 0.18,
    pinMarkerScale: 0.76,
  ),
  _tsudanuma7f6Entry(
    '070604',
    '高度応用情報科学科 ラボ',
    pinX: 0.85,
    pinY: 0.26,
    pinMarkerScale: 0.76,
  ),
  _tsudanuma7f6Entry(
    '070605',
    '認知情報科学科 ラボ',
    pinX: 0.72,
    pinY: 0.45,
    pinMarkerScale: 0.76,
  ),
  _tsudanuma7f6Entry(
    '070606',
    '認知情報科学科 オフィス',
    pinX: 0.85,
    pinY: 0.36,
    pinMarkerScale: 0.76,
  ),
  _tsudanuma7f6Entry(
    '070607',
    '認知情報科学科 ラボ',
    pinX: 0.85,
    pinY: 0.44,
    pinMarkerScale: 0.76,
  ),
  _tsudanuma7f6Entry(
    '070608',
    '認知情報科学科 ラボ',
    pinX: 0.85,
    pinY: 0.53,
    pinMarkerScale: 0.76,
  ),
  _tsudanuma7f6Entry(
    '070609',
    '認知情報科学科 ラボ',
    pinX: 0.72,
    pinY: 0.70,
    pinMarkerScale: 0.76,
  ),
  _tsudanuma7f6Entry(
    '070610',
    '認知情報科学科 オフィス',
    pinX: 0.85,
    pinY: 0.62,
    pinMarkerScale: 0.76,
  ),
  _tsudanuma7f6Entry(
    '070611',
    '認知情報科学科 ラボ',
    pinX: 0.85,
    pinY: 0.71,
    pinMarkerScale: 0.76,
  ),
  _tsudanuma7f6Entry(
    '070612',
    '認知情報科学科 ラボ',
    pinX: 0.85,
    pinY: 0.79,
    pinMarkerScale: 0.76,
  ),
  _tsudanuma7f6Entry(
    '070613',
    '高度応用情報科学科 ラボ',
    pinX: 0.20,
    pinY: 0.71,
    pinMarkerScale: 0.76,
  ),
  _tsudanuma7f6Entry(
    '070614',
    '高度応用情報科学科 オフィス',
    pinX: 0.13,
    pinY: 0.79,
    pinMarkerScale: 0.76,
  ),
  _tsudanuma7f6Entry(
    '070615',
    '高度応用情報科学科 ラボ',
    pinX: 0.20,
    pinY: 0.62,
    pinMarkerScale: 0.70,
  ),
  _tsudanuma7f6Entry(
    '070616',
    '認知情報科学科 ラボ',
    pinX: 0.28,
    pinY: 0.43,
    pinMarkerScale: 0.76,
  ),
  _tsudanuma7f6Entry(
    '070617',
    '認知情報科学科 オフィス',
    pinX: 0.14,
    pinY: 0.52,
    pinMarkerScale: 0.70,
  ),
  _tsudanuma7f6Entry(
    '070618',
    '認知情報科学科 ラボ',
    pinX: 0.14,
    pinY: 0.44,
    pinMarkerScale: 0.76,
  ),
  _tsudanuma7f6Entry(
    '070619',
    '認知情報科学科 ラボ',
    pinX: 0.14,
    pinY: 0.35,
    pinMarkerScale: 0.76,
  ),
  _tsudanuma7f6Entry(
    '070620',
    '認知情報科学科 ラボ',
    pinX: 0.29,
    pinY: 0.16,
    pinMarkerScale: 0.76,
  ),
  _tsudanuma7f6Entry(
    '070621',
    '認知情報科学科 オフィス',
    pinX: 0.14,
    pinY: 0.26,
    pinMarkerScale: 0.76,
  ),
  _tsudanuma7f6Entry(
    '070622',
    '認知情報科学科 ラボ',
    pinX: 0.14,
    pinY: 0.17,
    pinMarkerScale: 0.76,
  ),
  _tsudanuma7f6Entry(
    '070623',
    '認知情報科学科 ラボ',
    pinX: 0.14,
    pinY: 0.09,
    pinMarkerScale: 0.76,
  ),
];

const Map<String, String> _zw6 = {
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
    (m) => _zw6[m[0]]!,
  );
}

CampusClassroomLocation _tsudanuma7f6Entry(
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
    floor: 6,
    roomCode: roomCode,
    searchTerms: searchTerms,
    pinX: pinX,
    pinY: pinY,
    description: '6階・$roomCode $pinLabelFull',
    pinLabel: pinLabelFull,
    pinMarkerScale: pinMarkerScale,
  );
}

List<CampusClassroomLocation> searchPilotTsudanuma7f6(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) => pilotLocationMatchesQuery(r, q);
  return pilotTsudanumaBuilding7Floor6.where(matches).toList();
}
