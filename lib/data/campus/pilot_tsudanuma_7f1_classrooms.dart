import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

/// 津田沼7号館1階は Firebase ではなく、アプリ同梱の公式フロア図 PNG を表示する。
bool usesTsudanuma7F1AppFloorMap(CampusClassroomLocation room) {
  return room.campus == 'tsudanuma' &&
      room.buildingId == '7' &&
      room.floor == 1;
}

/// 津田沼7号館1階（フロア図上の正規化座標 0〜1・左上原点。ピンは各区画中央付近）。
const List<CampusClassroomLocation> pilotTsudanumaBuilding7Floor1 = [
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 1,
    roomCode: '070102',
    searchTerms: [
      '070102',
      '70102',
      '０７０１０２',
      '中央管理室',
      '管理室',
      '制御',
    ],
    pinX: 0.85,
    pinY: 0.13,
    description: '中央管理室',
    pinLabel: '中央管理室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 1,
    roomCode: '070104',
    searchTerms: ['070104', '70104', '０７０１０４', 'フレキシブル', 'デザイン科学', '知能メディア'],
    pinX: 0.80,
    pinY: 0.50,
    description: 'デザイン科学科・知能メディア科 フレキシブルワークスペース',
    pinLabel: 'デザイン科学科・知能メディア科 フレキシブルワークスペース',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 1,
    roomCode: '070106',
    searchTerms: ['070106', '70106', '０７０１０６', 'スタッフ', 'スタッフルーム'],
    pinX: 0.73,
    pinY: 0.82,
    description: 'デザイン科学科・知能メディア科 スタッフルーム(1)',
    pinLabel: 'デザイン科学科・知能メディア科 スタッフルーム(1)',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 1,
    roomCode: '070107',
    searchTerms: ['070107', '70107', '０７０１０７', 'スタッフ'],
    pinX: 0.85,
    pinY: 0.82,
    description: 'デザイン科学科・知能メディア科 スタッフルーム(2)',
    pinLabel: 'デザイン科学科・知能メディア科 スタッフルーム(2)',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 1,
    roomCode: '070108',
    searchTerms: [
      '070108',
      '70108',
      '０７０１０８',
      '070109',
      '70109',
      '０７０１０９',
      '検収',
      '会計',
    ],
    pinX: 0.20,
    pinY: 0.78,
    description: '検収室（会計課）',
    pinLabel: '検収室（会計課）',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '7',
    buildingDisplayName: '7号館',
    floor: 1,
    roomCode: '070110',
    searchTerms: [
      '070110',
      '70110',
      '０７０１１０',
      '070111',
      '70111',
      '０７０１１１',
      '産学連携',
      'パナソニック',
      '千葉工業大学',
    ],
    pinX: 0.20,
    pinY: 0.53,
    description: 'パナソニック・千葉工業大学 産学連携センター',
    pinLabel: 'パナソニック・千葉工業大学 産学連携センター',
  ),
];

/// お試し範囲の教室だけをクエリで絞り込み（大文字小文字無視）。
List<CampusClassroomLocation> searchPilotTsudanuma7f1(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) => pilotLocationMatchesQuery(r, q);

  return pilotTsudanumaBuilding7Floor1.where(matches).toList();
}
