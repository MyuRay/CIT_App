import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesTsudanuma4F4AppFloorMap(CampusClassroomLocation room) {
  return room.campus == 'tsudanuma' &&
      room.buildingId == '4' &&
      room.floor == 4;
}

/// 津田沼4号館4階（アプリ同梱フロア図、正規化座標 0〜1・左上原点）。
/// 倉庫・物品庫・トイレ・名称のない区画（040407 等）は検索に含めない。
/// 施設名は図面表記どおり（省略しない）。431・432 は 3 階と同じ部屋コード表記のため `floor` で区別する。
List<CampusClassroomLocation> get pilotTsudanumaBuilding4Floor4 => [
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 4,
    roomCode: '040301',
    searchTerms: [
      '040301',
      '40301',
      '０４０３０１',
      '040301号室',
      '040301号',
      '431教室',
      '431',
      '431講義室',
    ],
    pinX: 0.47,
    pinY: 0.83,
    description: '4階・431教室',
    pinLabel: '431教室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 4,
    roomCode: '040314',
    searchTerms: [
      '040314',
      '40314',
      '０４０３１４',
      '040314号室',
      '040314号',
      '432講義室',
      '432',
      '講義室432',
    ],
    pinX: 0.47,
    pinY: 0.15,
    description: '4階・432講義室',
    pinLabel: '432講義室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 4,
    roomCode: '040401',
    searchTerms: [
      '040401',
      '40401',
      '０４０４０１',
      '040401号室',
      '040401号',
      '惑星探査研究センター アストロバイオ ラボ 2',
      'アストロバイオ ラボ 2',
      '惑星探査研究センター',
    ],
    pinX: 0.22,
    pinY: 0.72,
    description: '4階・惑星探査研究センター アストロバイオ ラボ 2',
    pinLabel: '惑星探査研究センター アストロバイオ ラボ 2',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 4,
    roomCode: '040402',
    searchTerms: [
      '040402',
      '40402',
      '０４０４０２',
      '040402号室',
      '040402号',
      '惑星探査研究センター アストロバイオ ラボ 1',
      'アストロバイオ ラボ 1',
      '惑星探査研究センター',
    ],
    pinX: 0.22,
    pinY: 0.65,
    description: '4階・惑星探査研究センター アストロバイオ ラボ 1',
    pinLabel: '惑星探査研究センター アストロバイオ ラボ 1',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 4,
    roomCode: '040403',
    searchTerms: [
      '040403',
      '40403',
      '０４０４０３',
      '040403号室',
      '040403号',
      '惑星探査研究センター 4号館分室',
      '4号館分室',
      '惑星探査研究センター',
    ],
    pinX: 0.22,
    pinY: 0.58,
    description: '4階・惑星探査研究センター 4号館分室',
    pinLabel: '惑星探査研究センター 4号館分室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 4,
    roomCode: '040404',
    searchTerms: [
      '040404',
      '40404',
      '０４０４０４',
      '040404号室',
      '040404号',
      'ラボ(442)',
      'ラボ（442）',
      '442',
    ],
    pinX: 0.22,
    pinY: 0.51,
    description: '4階・ラボ(442)',
    pinLabel: 'ラボ(442)',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 4,
    roomCode: '040405',
    searchTerms: [
      '040405',
      '40405',
      '０４０４０５',
      '040405号室',
      '040405号',
      'オフィス(443)',
      'オフィス（443）',
      '443',
    ],
    pinX: 0.22,
    pinY: 0.44,
    description: '4階・オフィス(443)',
    pinLabel: 'オフィス(443)',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 4,
    roomCode: '040406',
    searchTerms: [
      '040406',
      '40406',
      '０４０４０６',
      '040406号室',
      '040406号',
      'ラボ(443)',
      'ラボ（443）',
      '443',
    ],
    pinX: 0.22,
    pinY: 0.37,
    description: '4階・ラボ(443)',
    pinLabel: 'ラボ(443)',
  ),
];

List<CampusClassroomLocation> searchPilotTsudanuma4F4(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) => pilotLocationMatchesQuery(r, q);
  return pilotTsudanumaBuilding4Floor4.where(matches).toList();
}
