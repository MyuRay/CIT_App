import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesTsudanuma4F1AppFloorMap(CampusClassroomLocation room) {
  return room.campus == 'tsudanuma' &&
      room.buildingId == '4' &&
      room.floor == 1;
}

/// 津田沼4号館1階（アプリ同梱フロア図、正規化座標 0〜1・左上原点）。
/// getter にして Hot Reload 後も毎回最新の pin を読み直す。
List<CampusClassroomLocation> get pilotTsudanumaBuilding4Floor1 => [
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 1,
    roomCode: '040101',
    searchTerms: [
      '040101',
      '40101',
      '０４０１０１',
      '040101号室',
      '040101号',
      'ラウンジ',
    ],
    pinX: 0.5,
    pinY: 0.75,
    description: '1階・ラウンジ',
    pinLabel: 'ラウンジ',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 1,
    roomCode: '040102',
    searchTerms: [
      '040102',
      '40102',
      '０４０１０２',
      '040102号室',
      '040102号',
      '談話室(女性専用)',
      '談話室（女性専用）',
      '談話室 女性専用',
      '女性専用',
    ],
    pinX: 0.32,
    pinY: 0.36,
    description: '1階・談話室（女性専用）',
    pinLabel: '談話室（女性専用）',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 1,
    roomCode: '040103',
    searchTerms: [
      '040103',
      '40103',
      '０４０１０３',
      '040103号室',
      '040103号',
      '談話室(1)',
      '談話室（1）',
      '談話室1',
      '談話室 1',
    ],
    pinX: 0.32,
    pinY: 0.25,
    description: '1階・談話室(1)',
    pinLabel: '談話室(1)',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 1,
    roomCode: '040104',
    searchTerms: [
      '040104',
      '40104',
      '０４０１０４',
      '040104号室',
      '040104号',
      '中央監視室',
      '監視室',
    ],
    pinX: 0.32,
    pinY: 0.12,
    description: '1階・中央監視室',
    pinLabel: '中央監視室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 1,
    roomCode: '040105',
    searchTerms: [
      '040105',
      '40105',
      '０４０１０５',
      '040105号室',
      '040105号',
      '未来ロボット技術研究センター',
      'ロボット技術研究センター',
      '未来ロボット',
    ],
    pinX: 0.70,
    pinY: 0.16,
    description: '1階・未来ロボット技術研究センター',
    pinLabel: '未来ロボット技術研究センター',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 1,
    roomCode: '040124',
    searchTerms: [
      '040124',
      '40124',
      '０４０１２４',
      '040124号室',
      '040124号',
      '談話室(2)',
      '談話室（2）',
      '談話室2',
      '談話室 2',
    ],
    pinX: 0.32,
    pinY: 0.51,
    description: '1階・談話室(2)',
    pinLabel: '談話室(2)',
  ),
];

List<CampusClassroomLocation> searchPilotTsudanuma4F1(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) => pilotLocationMatchesQuery(r, q);
  return pilotTsudanumaBuilding4Floor1.where(matches).toList();
}
