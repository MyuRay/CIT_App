import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

/// **ピン位置の微調整:** 各 `CampusClassroomLocation` の `pinX` / `pinY`（0〜1、図の左上が原点・右下が 1）。
/// 検索タブ → 候補 →「教室の詳細」で確認。小数は **ピリオド**（例: `0.52`）。保存後 Hot Restart 推奨。
///
/// 津田沼4号館B1は Firebase ではなくアプリ同梱のフロア図を使う。
bool usesTsudanuma4B1AppFloorMap(CampusClassroomLocation room) {
  return room.campus == 'tsudanuma' &&
      room.buildingId == '4' &&
      room.floor == -1;
}

/// お試しデータ：津田沼4号館B1（図面の各区画のおおよその中心、正規化座標 **0〜1**）。
/// getterにして、Hot Reload後も毎回最新の pin 設定を読み直す。
List<CampusClassroomLocation> get pilotTsudanumaBuilding4FloorB1 => [
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: -1,
    roomCode: '04B101',
    searchTerms: [
      '04b101',
      '04B101',
      '04b101号室',
      '04B101号室',
      '工作センター作業場',
      '作業場',
      '工作センター',
    ],
    pinX: 0.53,
    pinY: 0.73,
    description: 'B1 下段・工作センター作業場（広間のおおよその中心）',
    pinLabel: '工作センター作業場',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: -1,
    roomCode: '04B102',
    searchTerms: [
      '04b102',
      '04B102',
      '04b102号室',
      '04B102号室',
      '工作センター実習室(1)',
      '工作センター実習室（1）',
      '実習室1',
      '実習室(1)',
    ],
    pinX: 0.18,
    pinY: 0.68,
    description: 'B1 左突き出し・工作センター実習室(1)',
    pinLabel: '工作センター実習室(1)',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: -1,
    roomCode: '04B103',
    searchTerms: [
      '04b103',
      '04B103',
      '04b103号室',
      '04B103号室',
      '工作センター実習室(2)',
      '工作センター実習室（2）',
      '実習室2',
      '実習室(2)',
    ],
    pinX: 0.18,
    pinY: 0.60,
    description: 'B1 左突き出し・工作センター実習室(2)',
    pinLabel: '工作センター実習室(2)',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: -1,
    roomCode: '04B104',
    searchTerms: [
      '04b104',
      '04B104',
      '04b104号室',
      '04B104号室',
      '材料解析室',
      '材料解析室事務室',
      '事務室',
      '工作センター材料解析室',
    ],
    pinX: 0.35,
    pinY: 0.45,
    description: 'B1 左列・工作センター材料解析室 事務室',
    pinLabel: '工作センター材料解析室 事務室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: -1,
    roomCode: '04B105',
    searchTerms: [
      '04b105',
      '04B105',
      '04b105号室',
      '04B105号室',
      '測定室',
      '工作センター測定室',
    ],
    pinX: 0.42,
    pinY: 0.40,
    description: 'B1 左列・工作センター測定室',
    pinLabel: '工作センター測定室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: -1,
    roomCode: '04B106',
    searchTerms: [
      '04b106',
      '04B106',
      '04b106号室',
      '04B106号室',
      '第2材料解析室',
      '第２材料解析室',
    ],
    pinX: 0.35,
    pinY: 0.30,
    description: 'B1 左上列・第2材料解析室',
    pinLabel: '第2材料解析室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: -1,
    roomCode: '04B107',
    searchTerms: [
      '04b107',
      '04B107',
      '04b107号室',
      '04B107号室',
      '第1材料解析室',
      '第１材料解析室',
    ],
    pinX: 0.35,
    pinY: 0.175,
    description: 'B1 最上段左・第1材料解析室',
    pinLabel: '第1材料解析室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: -1,
    roomCode: '04B108',
    searchTerms: [
      '04b108',
      '04B108',
      '04b108号室',
      '04B108号室',
      '乾燥室',
    ],
    pinX: 0.70,
    pinY: 0.09,
    description: 'B1 右上・乾燥室',
    pinLabel: '乾燥室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: -1,
    roomCode: '04B109',
    searchTerms: [
      '04b109',
      '04B109',
      '04b109号室',
      '04B109号室',
      '塗装室',
    ],
    pinX: 0.65,
    pinY: 0.18,
    description: 'B1 右列・塗装室',
    pinLabel: '塗装室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: -1,
    roomCode: '04B110',
    searchTerms: [
      '04b110',
      '04B110',
      '04b110号室',
      '04B110号室',
      '水砥室',
    ],
    pinX: 0.75,
    pinY: 0.18,
    description: 'B1 右列・水砥室',
    pinLabel: '水砥室',
  ),
];

List<CampusClassroomLocation> searchPilotTsudanuma4B1(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) =>
      pilotLocationMatchesQuery(r, q);
  return pilotTsudanumaBuilding4FloorB1.where(matches).toList();
}
