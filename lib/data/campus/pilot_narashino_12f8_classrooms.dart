import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesNarashino12F8AppSchematic(CampusClassroomLocation room) {
  return room.campus == 'narashino' &&
      room.buildingId == '12' &&
      room.floor == 8;
}

/// 新習志野12号館8階（同梱フロア図、正規化座標 0〜1・左上原点）。
/// 緑のラウンジ系区画のみ。トイレ・階段等はリストにしない。
///
/// メインラウンジと展望ラウンジは両方とも「ラウンジ」を含むため、[roomCode] で区別。
const List<CampusClassroomLocation> pilotNarashinoBuilding12Floor8 = [
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '12',
    buildingDisplayName: '12号館',
    floor: 8,
    roomCode: 'ラウンジ',
    searchTerms: [
      'ラウンジ',
      '12号館8階ラウンジ',
      '12号館８階ラウンジ',
      '12号館 8階 ラウンジ',
      '学生ラウンジ',
      'メインラウンジ',
    ],
    pinX: 0.51,
    pinY: 0.20,
    description: '12号館8階・メインのラウンジ（上部・アーチ側・目安）',
    pinLabel: 'ラウンジ',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '12',
    buildingDisplayName: '12号館',
    floor: 8,
    roomCode: '展望ラウンジ',
    searchTerms: [
      '展望ラウンジ',
      '展望 ラウンジ',
      '12号館8階展望ラウンジ',
      '12号館８階展望ラウンジ',
      'てんぼうらうんじ',
      '眺望ラウンジ',
    ],
    pinX: 0.58,
    pinY: 0.65,
    description: '12号館8階・展望ラウンジ（中央下寄りエリア・目安）',
  ),
];

List<CampusClassroomLocation> searchPilotNarashino12f8(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) =>
      pilotLocationMatchesQuery(r, q);
  return pilotNarashinoBuilding12Floor8.where(matches).toList();
}
