import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesTsudanuma4F2AppFloorMap(CampusClassroomLocation room) {
  return room.campus == 'tsudanuma' &&
      room.buildingId == '4' &&
      room.floor == 2;
}

const List<String> _kAiSoftSearchTerms = [
  '人工知能',
  'ソフトウェア',
  '人工知能・ソフトウェア技術研究センター',
];

/// 津田沼4号館2階（アプリ同梱フロア図、正規化座標 0〜1・左上原点）。
/// getter にして Hot Reload 後も毎回最新の pin を読み直す。
List<CampusClassroomLocation> get pilotTsudanumaBuilding4Floor2 => [
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 2,
    roomCode: '040290',
    searchTerms: [
      '040290',
      'ひまわり',
      'ひまわり保育園',
      '千葉工大ひまわり保育園',
      '保育園',
    ],
    pinX: 0.40,
    pinY: 0.11,
    description: '2階・千葉工大ひまわり保育園（図面上に教室番号なし）',
    pinLabel: '千葉工大ひまわり保育園',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 2,
    roomCode: '040203',
    searchTerms: [
      '040203',
      '40203',
      '０４０２０３',
      '040203号室',
      '040203号',
      'ラボ(1)',
      'ラボ（1）',
      'ラボ1',
      ..._kAiSoftSearchTerms,
    ],
    pinX: 0.26,
    pinY: 0.68,
    description: '2階・人工知能・ソフトウェア技術研究センター ラボ(1)',
    pinLabel: '人工知能・ソフトウェア技術研究センター ラボ(1)',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 2,
    roomCode: '040202',
    searchTerms: [
      '040202',
      '40202',
      '０４０２０２',
      '040202号室',
      '040202号',
      '所長室',
      ..._kAiSoftSearchTerms,
    ],
    pinX: 0.26,
    pinY: 0.75,
    description: '2階・人工知能・ソフトウェア技術研究センター 所長室',
    pinLabel: '人工知能・ソフトウェア技術研究センター 所長室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 2,
    roomCode: '040201',
    searchTerms: [
      '040201',
      '40201',
      '０４０２０１',
      '040201号室',
      '040201号',
      'ラボ(4)',
      'ラボ（4）',
      'ラボ4',
      ..._kAiSoftSearchTerms,
    ],
    pinX: 0.26,
    pinY: 0.82,
    description: '2階・人工知能・ソフトウェア技術研究センター ラボ(4)',
    pinLabel: '人工知能・ソフトウェア技術研究センター ラボ(4)',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 2,
    roomCode: '040212',
    searchTerms: [
      '040212',
      '40212',
      '０４０２１２',
      '040212号室',
      '040212号',
      'ラボ(2)',
      'ラボ（2）',
      'ラボ2',
      ..._kAiSoftSearchTerms,
    ],
    pinX: 0.74,
    pinY: 0.68,
    description: '2階・人工知能・ソフトウェア技術研究センター ラボ(2)',
    pinLabel: '人工知能・ソフトウェア技術研究センター ラボ(2)',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 2,
    roomCode: '040213',
    searchTerms: [
      '040213',
      '40213',
      '０４０２１３',
      '040213号室',
      '040213号',
      'ラボ(3)',
      'ラボ（3）',
      'ラボ3',
      ..._kAiSoftSearchTerms,
    ],
    pinX: 0.74,
    pinY: 0.75,
    description: '2階・人工知能・ソフトウェア技術研究センター ラボ(3)',
    pinLabel: '人工知能・ソフトウェア技術研究センター ラボ(3)',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 2,
    roomCode: '040214',
    searchTerms: [
      '040214',
      '40214',
      '０４０２１４',
      '040214号室',
      '040214号',
      '共有スペース',
      '共有',
      ..._kAiSoftSearchTerms,
    ],
    pinX: 0.74,
    pinY: 0.82,
    description: '2階・人工知能・ソフトウェア技術研究センター 共有スペース',
    pinLabel: '人工知能・ソフトウェア技術研究センター 共有スペース',
  ),
];

List<CampusClassroomLocation> searchPilotTsudanuma4F2(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) => pilotLocationMatchesQuery(r, q);
  return pilotTsudanumaBuilding4Floor2.where(matches).toList();
}
