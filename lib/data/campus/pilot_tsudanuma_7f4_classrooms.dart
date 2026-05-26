import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesTsudanuma7F4AppFloorMap(CampusClassroomLocation room) {
  return room.campus == 'tsudanuma' &&
      room.buildingId == '7' &&
      room.floor == 4;
}

/// 津田沼7号館4階（アプリ同梱フロア図、正規化座標 0〜1・左上原点）。
///
/// **図面上で講義室名と0704xxの両方がある区画のみ**検索対象。
/// アトリウム上部・ラウンジなどは載せない。講義室名は図の表記を省略しない。
List<CampusClassroomLocation> get pilotTsudanumaBuilding7Floor4 => [
  _tsudanuma7f4Room(
    '070401',
    '741 講義室',
    digitShort: '70401',
    lectureNo: '741',
    pinX: 0.80,
    pinY: 0.11,
  ),
  _tsudanuma7f4Room(
    '070402',
    '742 講義室',
    digitShort: '70402',
    lectureNo: '742',
    pinX: 0.80,
    pinY: 0.24,
  ),
  _tsudanuma7f4Room(
    '070403',
    '743 講義室',
    digitShort: '70403',
    lectureNo: '743',
    pinX: 0.80,
    pinY: 0.40,
  ),
  _tsudanuma7f4Room(
    '070404',
    '744 講義室',
    digitShort: '70404',
    lectureNo: '744',
    pinX: 0.80,
    pinY: 0.57,
  ),
  _tsudanuma7f4Room(
    '070405',
    '745 講義室',
    digitShort: '70405',
    lectureNo: '745',
    pinX: 0.80,
    pinY: 0.75,
  ),
  _tsudanuma7f4Room(
    '070406',
    '746 講義室',
    digitShort: '70406',
    lectureNo: '746',
    pinX: 0.22,
    pinY: 0.75,
  ),
  _tsudanuma7f4Room(
    '070407',
    '747 講義室',
    digitShort: '70407',
    lectureNo: '747',
    pinX: 0.22,
    pinY: 0.63,
  ),
  _tsudanuma7f4Room(
    '070408',
    '748 講義室',
    digitShort: '70408',
    lectureNo: '748',
    pinX: 0.22,
    pinY: 0.49,
  ),
  _tsudanuma7f4Room(
    '070409',
    '749 講義室',
    digitShort: '70409',
    lectureNo: '749',
    pinX: 0.22,
    pinY: 0.37,
  ),
  _tsudanuma7f4Room(
    '070410',
    '7410 講義室',
    digitShort: '70410',
    lectureNo: '7410',
    pinX: 0.22,
    pinY: 0.23,
    pinMarkerScale: 0.92,
  ),
  _tsudanuma7f4Room(
    '070411',
    '7411 講義室',
    digitShort: '70411',
    lectureNo: '7411',
    pinX: 0.22,
    pinY: 0.11,
    pinMarkerScale: 0.92,
  ),
];

CampusClassroomLocation _tsudanuma7f4Room(
  String roomCode,
  String pinLabelFull, {
  required String digitShort,
  required String lectureNo,
  required double pinX,
  required double pinY,
  double pinMarkerScale = 1.0,
}) {
  final zenRoomCode = roomCode.replaceAllMapped(
    RegExp(r'\d'),
    (m) => const {
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
    }[m[0]]!,
  );

  final compactLabel = pinLabelFull.replaceAll(' ', '');

  return CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 4,
    roomCode: roomCode,
    searchTerms: [
      roomCode,
      digitShort,
      zenRoomCode,
      '$roomCode号室',
      '$roomCode号',
      pinLabelFull,
      compactLabel,
      lectureNo,
    ],
    pinX: pinX,
    pinY: pinY,
    description: '4階・$roomCode $pinLabelFull',
    pinLabel: pinLabelFull,
    pinMarkerScale: pinMarkerScale,
  );
}

List<CampusClassroomLocation> searchPilotTsudanuma7f4(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) => pilotLocationMatchesQuery(r, q);
  return pilotTsudanumaBuilding7Floor4.where(matches).toList();
}
