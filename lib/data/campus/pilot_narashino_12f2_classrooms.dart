import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesNarashino12F2AppSchematic(CampusClassroomLocation room) {
  return room.campus == 'narashino' &&
      room.buildingId == '12' &&
      room.floor == 2;
}

/// 新習志野12号館2階（同梱フロア図、正規化座標 0〜1・左上原点）。
/// 緑の主要区画のみ。学生談話コーナー・トイレ・階段等は検索しない。
/// 学習相談室は同一表示名が2つあるため [roomCode] で区別。
const List<CampusClassroomLocation> pilotNarashinoBuilding12Floor2 = [
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '12',
    buildingDisplayName: '12号館',
    floor: 2,
    roomCode: 'グローバルラウンジ',
    searchTerms: [
      'グローバルラウンジ',
      'グローバル ラウンジ',
      '学習自習室',
      '学習自習室 グローバルラウンジ',
      '自学',
      '12号館 グローバルラウンジ',
    ],
    pinX: 0.62,
    pinY: 0.20,
    description: '12号館2階・学習自習室（グローバルラウンジ）',
    pinLabel: '学習自習室 グローバルラウンジ',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '12',
    buildingDisplayName: '12号館',
    floor: 2,
    roomCode: '講師控室',
    searchTerms: [
      '講師控室',
      'こうしひかえしつ',
      '控室',
      '12号館 講師控室',
    ],
    pinX: 0.41,
    pinY: 0.73,
    description: '12号館2階・講師控室',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '12',
    buildingDisplayName: '12号館',
    floor: 2,
    roomCode: '学習相談室1',
    searchTerms: [
      '学習相談室1',
      '学習相談室１',
      '学習相談室',
      '相談室',
      '12号館 学習相談室',
    ],
    pinX: 0.99,
    pinY: 0.82,
    description: '12号館2階・学習相談室（手前側の区画・目安）',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '12',
    buildingDisplayName: '12号館',
    floor: 2,
    roomCode: '学習相談室2',
    searchTerms: [
      '学習相談室2',
      '学習相談室２',
      '学習相談室',
      '相談室2',
      '12号館 学習相談室2',
    ],
    pinX: 0.96,
    pinY: 0.94,
    description: '12号館2階・学習相談室（奥側の区画・目安）',
  ),
];

List<CampusClassroomLocation> searchPilotNarashino12f2(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) =>
      pilotLocationMatchesQuery(r, q);
  return pilotNarashinoBuilding12Floor2.where(matches).toList();
}
