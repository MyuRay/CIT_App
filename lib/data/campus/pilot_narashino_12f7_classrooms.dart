import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesNarashino12F7AppSchematic(CampusClassroomLocation room) {
  return room.campus == 'narashino' &&
      room.buildingId == '12' &&
      room.floor == 7;
}

/// 新習志野12号館7階（同梱フロア図、正規化座標 0〜1・左上原点）。
/// 緑のスポーツ施設区画のみ。更衣室・シャワー・階段等はリストにしない。
const List<CampusClassroomLocation> pilotNarashinoBuilding12Floor7 = [
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '12',
    buildingDisplayName: '12号館',
    floor: 7,
    roomCode: 'アスレチックジム',
    searchTerms: [
      'アスレチックジム',
      'アスレチック',
      'ジム',
      'アスレ',
      '12号館7階アスレチックジム',
      '12号館７階アスレチックジム',
    ],
    pinX: 0.50,
    pinY: 0.22,
    description: '12号館7階・アスレチックジム（上側・アーチ側エリア・目安）',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '12',
    buildingDisplayName: '12号館',
    floor: 7,
    roomCode: 'フリークライミング',
    searchTerms: [
      'フリークライミング',
      'フリー クライミング',
      'クライミング',
      'ボルダリング',
      '12号館7階フリークライミング',
    ],
    pinX: 0.89,
    pinY: 0.18,
    description: '12号館7階・フリークライミング（東側細長エリア・目安）',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '12',
    buildingDisplayName: '12号館',
    floor: 7,
    roomCode: 'スカッシュコート',
    searchTerms: [
      'スカッシュコート',
      'スカッシュ',
      'squash',
      '12号館7階スカッシュ',
      'スカッシュ コート',
    ],
    pinX: 0.30,
    pinY: 0.76,
    description: '12号館7階・スカッシュコート',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '12',
    buildingDisplayName: '12号館',
    floor: 7,
    roomCode: 'ミニバスケット',
    searchTerms: [
      'ミニバスケット',
      'ミニ バスケット',
      'ミニバスケ',
      'バスケ',
      '12号館7階ミニバスケ',
    ],
    pinX: 0.55,
    pinY: 0.73,
    description: '12号館7階・ミニバスケットコート',
    pinLabel: 'ミニバスケット',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '12',
    buildingDisplayName: '12号館',
    floor: 7,
    roomCode: '卓球コート',
    searchTerms: [
      '卓球コート',
      '卓球',
      '12号館7階卓球',
      'ピンポン',
    ],
    pinX: 0.79,
    pinY: 0.83,
    description: '12号館7階・卓球コート',
  ),
];

List<CampusClassroomLocation> searchPilotNarashino12f7(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) =>
      pilotLocationMatchesQuery(r, q);
  return pilotNarashinoBuilding12Floor7.where(matches).toList();
}
