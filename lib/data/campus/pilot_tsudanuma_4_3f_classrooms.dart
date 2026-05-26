import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesTsudanuma4F3AppFloorMap(CampusClassroomLocation room) {
  return room.campus == 'tsudanuma' &&
      room.buildingId == '4' &&
      room.floor == 3;
}

const List<String> _kAiSoftSearchTerms = [
  '人工知能',
  'ソフトウェア',
  '人工知能・ソフトウェア技術研究センター',
];

const List<String> _kHenkakuSearchTerms = [
  '変革センター',
  '変革',
];

/// 津田沼4号館3階（アプリ同梱フロア図、正規化座標 0〜1・左上原点）。
/// 倉庫・物品庫・トイレ・名称のない区画（040316）は検索に含めない。
List<CampusClassroomLocation> get pilotTsudanumaBuilding4Floor3 => [
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 3,
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
    pinX: 0.64,
    pinY: 0.88,
    description: '3階・431教室',
    pinLabel: '431教室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 3,
    roomCode: '040305',
    searchTerms: [
      '040305',
      '40305',
      '０４０３０５',
      '040305号室',
      '040305号',
      'ラボ(5)',
      'ラボ（5）',
      'ラボ5',
      ..._kAiSoftSearchTerms,
    ],
    pinX: 0.24,
    pinY: 0.73,
    description: '3階・人工知能・ソフトウェア技術研究センター ラボ(5)',
    pinLabel: '人工知能・ソフトウェア技術研究センター ラボ(5)',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 3,
    roomCode: '040306',
    searchTerms: [
      '040306',
      '40306',
      '０４０３０６',
      '040306号室',
      '040306号',
      '変革センター オフィス',
      '変革センター',
      ..._kHenkakuSearchTerms,
    ],
    pinX: 0.24,
    pinY: 0.65,
    description: '3階・変革センター オフィス',
    pinLabel: '変革センター オフィス',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 3,
    roomCode: '040307',
    searchTerms: [
      '040307',
      '40307',
      '０４０３０７',
      '040307号室',
      '040307号',
      '生命科学科',
      '生命科学科 ラボ',
    ],
    pinX: 0.24,
    pinY: 0.60,
    description: '3階・生命科学科 ラボ',
    pinLabel: '生命科学科 ラボ',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 3,
    roomCode: '040308',
    searchTerms: [
      '040308',
      '40308',
      '０４０３０８',
      '040308号室',
      '040308号',
      '生命科学科 オフィス',
      '生命科学科',
    ],
    pinX: 0.24,
    pinY: 0.50,
    description: '3階・生命科学科 オフィス',
    pinLabel: '生命科学科 オフィス',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 3,
    roomCode: '040309',
    searchTerms: [
      '040309',
      '40309',
      '０４０３０９',
      '040309号室',
      '040309号',
      '施設部',
    ],
    pinX: 0.24,
    pinY: 0.45,
    description: '3階・施設部',
    pinLabel: '施設部',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 3,
    roomCode: '040310',
    searchTerms: [
      '040310',
      '40310',
      '０４０３１０',
      '040310号室',
      '040310号',
      'ラボ(6)',
      'ラボ（6）',
      'ラボ6',
      ..._kAiSoftSearchTerms,
    ],
    pinX: 0.24,
    pinY: 0.37,
    description: '3階・人工知能・ソフトウェア技術研究センター ラボ(6)',
    pinLabel: '人工知能・ソフトウェア技術研究センター ラボ(6)',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 3,
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
    pinX: 0.65,
    pinY: 0.18,
    description: '3階・432講義室',
    pinLabel: '432講義室',
  ),
  CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 3,
    roomCode: '040315',
    searchTerms: [
      '040315',
      '40315',
      '０４０３１５',
      '040315号室',
      '040315号',
      '変革センター ラボ',
      ..._kHenkakuSearchTerms,
    ],
    pinX: 0.72,
    pinY: 0.60,
    description: '3階・変革センター ラボ',
    pinLabel: '変革センター ラボ',
  ),
];

List<CampusClassroomLocation> searchPilotTsudanuma4F3(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) => pilotLocationMatchesQuery(r, q);
  return pilotTsudanumaBuilding4Floor3.where(matches).toList();
}
