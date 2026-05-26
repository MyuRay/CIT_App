import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesTsudanuma7F8AppFloorMap(CampusClassroomLocation room) {
  return room.campus == 'tsudanuma' &&
      room.buildingId == '7' &&
      room.floor == 8;
}

/// 津田沼7号館8階（アプリ同梱フロア図、正規化座標 0〜1・左上原点）。
///
/// **図面上で施設名と0708xxの両方がある区画のみ**検索対象。アトリウム・ラウンジ・倉庫等は載せない。
/// 施設名は図の表記を省略しない。
List<CampusClassroomLocation> get pilotTsudanumaBuilding7Floor8 => [
  _tsudanuma7f8Entry(
    '070801',
    '認知情報科学科 オフィス',
    pinX: 0.79,
    pinY: 0.10,
    pinMarkerScale: 0.74,
  ),
  _tsudanuma7f8Entry(
    '070802',
    '認知情報科学科 ラボ',
    pinX: 0.73,
    pinY: 0.22,
    pinMarkerScale: 0.74,
  ),
  _tsudanuma7f8Entry(
    '070803',
    '情報工学科 ラボ',
    pinX: 0.86,
    pinY: 0.34,
    pinMarkerScale: 0.74,
  ),
  _tsudanuma7f8Entry(
    '070804',
    '情報工学科 オフィス',
    pinX: 0.79,
    pinY: 0.46,
    pinMarkerScale: 0.74,
  ),
  _tsudanuma7f8Entry(
    '070805',
    '高度応用情報科学科 オフィス',
    pinX: 0.79,
    pinY: 0.56,
    pinMarkerScale: 0.72,
  ),
  _tsudanuma7f8Entry(
    '070806',
    '高度応用情報科学科 ラボ',
    pinX: 0.73,
    pinY: 0.67,
    pinMarkerScale: 0.72,
  ),
  _tsudanuma7f8Entry(
    '070807',
    '情報工学科 ラボ',
    pinX: 0.86,
    pinY: 0.80,
    pinMarkerScale: 0.74,
  ),
  _tsudanuma7f8Entry(
    '070808',
    '情報工学科 オフィス',
    pinX: 0.19,
    pinY: 0.82,
    pinMarkerScale: 0.74,
  ),
  _tsudanuma7f8Entry(
    '070809',
    '情報工学科 第一実習室',
    pinX: 0.26,
    pinY: 0.72,
    pinMarkerScale: 0.70,
  ),
  _tsudanuma7f8Entry(
    '070810',
    '情報工学科 ラボ',
    pinX: 0.13,
    pinY: 0.67,
    pinMarkerScale: 0.74,
  ),
  _tsudanuma7f8Entry(
    '070811',
    '情報工学科 オフィス',
    pinX: 0.19,
    pinY: 0.55,
    pinMarkerScale: 0.74,
  ),
  _tsudanuma7f8Entry(
    '070812',
    '情報工学科 オフィス',
    pinX: 0.19,
    pinY: 0.46,
    pinMarkerScale: 0.74,
  ),
  _tsudanuma7f8Entry(
    '070813',
    '情報工学科 ラボ',
    pinX: 0.13,
    pinY: 0.34,
    pinMarkerScale: 0.74,
  ),
  _tsudanuma7f8Entry(
    '070814',
    '認知情報科学科 ラボ',
    pinX: 0.28,
    pinY: 0.17,
    pinMarkerScale: 0.74,
  ),
  _tsudanuma7f8Entry(
    '070815',
    '認知情報科学科 オフィス',
    pinX: 0.13,
    pinY: 0.14,
    pinMarkerScale: 0.74,
  ),
];

const Map<String, String> _zw8 = {
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
    (m) => _zw8[m[0]]!,
  );
}

CampusClassroomLocation _tsudanuma7f8Entry(
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
    floor: 8,
    roomCode: roomCode,
    searchTerms: searchTerms,
    pinX: pinX,
    pinY: pinY,
    description: '8階・$roomCode $pinLabelFull',
    pinLabel: pinLabelFull,
    pinMarkerScale: pinMarkerScale,
  );
}

List<CampusClassroomLocation> searchPilotTsudanuma7f8(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) => pilotLocationMatchesQuery(r, q);
  return pilotTsudanumaBuilding7Floor8.where(matches).toList();
}
