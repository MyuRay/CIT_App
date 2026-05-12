import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesTsudanuma7F5AppFloorMap(CampusClassroomLocation room) {
  return room.campus == 'tsudanuma' &&
      room.buildingId == '7' &&
      room.floor == 5;
}

/// 津田沼7号館5階（アプリ同梱フロア図、正規化座標 0〜1・左上原点）。
///
/// **図面上で施設名と0705xxの両方がある区画のみ**検索対象。アトリウム・ラウンジ・倉庫等は載せない。
/// 施設名は図の表記を省略しない。
///
/// **070612** は6階の正式教室コードになるため、`070612` を5階 `070512` の検索別名にはしない。
List<CampusClassroomLocation> get pilotTsudanumaBuilding7Floor5 => [
  _tsudanuma7f5Entry(
    '070501',
    '情報ネットワーク学科 ネットワーク設計実習室',
    pinX: 0.81,
    pinY: 0.11,
    pinMarkerScale: 0.68,
  ),
  _tsudanuma7f5Entry(
    '070502',
    '情報ネットワーク学科 ネットワーク企画運営・管理室',
    pinX: 0.81,
    pinY: 0.25,
    pinMarkerScale: 0.68,
  ),
  _tsudanuma7f5Entry(
    '070503',
    '認知情報科学科 ラボ',
    pinX: 0.75,
    pinY: 0.43,
  ),
  _tsudanuma7f5Entry(
    '070504',
    '認知情報科学科 オフィス',
    pinX: 0.87,
    pinY: 0.34,
    pinMarkerScale: 0.70,
  ),
  _tsudanuma7f5Entry(
    '070505',
    '認知情報科学科 ラボ',
    pinX: 0.87,
    pinY: 0.43,
    pinMarkerScale: 0.70,
  ),
  _tsudanuma7f5Entry(
    '070506',
    '認知情報科学科 ラボ',
    pinX: 0.87,
    pinY: 0.52,
    pinMarkerScale: 0.70,
  ),
  _tsudanuma7f5Entry(
    '070507',
    '情報工学科 ラボ',
    pinX: 0.75,
    pinY: 0.70,
  ),
  _tsudanuma7f5Entry(
    '070508',
    '情報工学科 オフィス',
    pinX: 0.87,
    pinY: 0.61,
    pinMarkerScale: 0.70,
  ),
  _tsudanuma7f5Entry(
    '070509',
    '情報工学科 ラボ',
    pinX: 0.87,
    pinY: 0.70,
    pinMarkerScale: 0.70,
  ),
  _tsudanuma7f5Entry(
    '070510',
    '情報工学科 ラボ',
    pinX: 0.87,
    pinY: 0.79,
    pinMarkerScale: 0.70,
  ),
  _tsudanuma7f5Entry(
    '070511',
    '高度応用情報科学科 ラボ',
    pinX: 0.30,
    pinY: 0.70,
    pinMarkerScale: 0.78,
  ),
  _tsudanuma7f5Entry(
    '070512',
    '高度応用情報科学科 オフィス',
    pinX: 0.15,
    pinY: 0.79,
    pinMarkerScale: 0.78,
  ),
  _tsudanuma7f5Entry(
    '070513',
    '高度応用情報科学科 ラボ',
    pinX: 0.15,
    pinY: 0.70,
    pinMarkerScale: 0.78,
  ),
  _tsudanuma7f5Entry(
    '070514',
    '高度応用情報科学科 ラボ',
    pinX: 0.15,
    pinY: 0.61,
    pinMarkerScale: 0.78,
  ),
  _tsudanuma7f5Entry(
    '070515',
    '高度応用情報科学科 ラボ',
    pinX: 0.30,
    pinY: 0.44,
    pinMarkerScale: 0.78,
  ),
  _tsudanuma7f5Entry(
    '070516',
    '高度応用情報科学科 ラボ',
    pinX: 0.15,
    pinY: 0.53,
    pinMarkerScale: 0.78,
  ),
  _tsudanuma7f5Entry(
    '070517',
    '高度応用情報科学科 ラボ',
    pinX: 0.15,
    pinY: 0.44,
    pinMarkerScale: 0.78,
  ),
  _tsudanuma7f5Entry(
    '070518',
    '高度応用情報科学科 オフィス',
    pinX: 0.15,
    pinY: 0.34,
    pinMarkerScale: 0.78,
  ),
  _tsudanuma7f5Entry(
    '070519',
    '認知情報科学科 ラボ',
    pinX: 0.31,
    pinY: 0.14,
  ),
  _tsudanuma7f5Entry(
    '070520',
    '認知情報科学科 オフィス',
    pinX: 0.15,
    pinY: 0.24,
    pinMarkerScale: 0.78,
  ),
  _tsudanuma7f5Entry(
    '070521',
    '認知情報科学科 ラボ',
    pinX: 0.15,
    pinY: 0.17,
    pinMarkerScale: 0.78,
  ),
  _tsudanuma7f5Entry(
    '070522',
    '認知情報科学科 ラボ',
    pinX: 0.15,
    pinY: 0.08,
    pinMarkerScale: 0.78,
  ),
];

const Map<String, String> _zw = {
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
    (m) => _zw[m[0]]!,
  );
}

CampusClassroomLocation _tsudanuma7f5Entry(
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
    floor: 5,
    roomCode: roomCode,
    searchTerms: searchTerms,
    pinX: pinX,
    pinY: pinY,
    description: '5階・$roomCode $pinLabelFull',
    pinLabel: pinLabelFull,
    pinMarkerScale: pinMarkerScale,
  );
}

List<CampusClassroomLocation> searchPilotTsudanuma7f5(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) => pilotLocationMatchesQuery(r, q);
  return pilotTsudanumaBuilding7Floor5.where(matches).toList();
}
