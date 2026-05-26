import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesNarashino5F1AppSchematic(CampusClassroomLocation room) {
  return room.campus == 'narashino' &&
      room.buildingId == '5' &&
      room.floor == 1;
}

/// 新習志野5号館1階（同梱フロア図、正規化座標 0〜1・左上原点）。
/// **図面に施設名称が載っていない**ため、`roomCode` のみを検索・ピン表示に載せている。
/// 座標は室のおおよその中心。
const List<CampusClassroomLocation> pilotNarashinoBuilding5Floor1 = [
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '5',
    buildingDisplayName: '5号館',
    floor: 1,
    roomCode: '5101',
    searchTerms: [
      '5101',
      '05101',
      '５１０１',
      '5101号室',
      '5101号',
      '5101講義室',
      '講義室5101',
      '5101 講義室',
    ],
    pinX: 0.98,
    pinY: 0.50,
    description: '5号館1階・5101（室番のみ）',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '5',
    buildingDisplayName: '5号館',
    floor: 1,
    roomCode: '5102',
    searchTerms: [
      '5102',
      '05102',
      '５１０２',
      '5102号室',
      '5102号',
      '5102講義室',
      '講義室5102',
      '5102 講義室',
    ],
    pinX: 0.83,
    pinY: 0.28,
    description: '5号館1階・5102（室番のみ）',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '5',
    buildingDisplayName: '5号館',
    floor: 1,
    roomCode: '5103',
    searchTerms: [
      '5103',
      '05103',
      '５１０３',
      '5103号室',
      '5103号',
      '5103講義室',
      '講義室5103',
      '5103 講義室',
    ],
    pinX: 0.83,
    pinY: 0.75,
    description: '5号館1階・5103（室番のみ）',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '5',
    buildingDisplayName: '5号館',
    floor: 1,
    roomCode: '5104',
    searchTerms: [
      '5104',
      '05104',
      '５１０４',
      '5104号室',
      '5104号',
      '5104講義室',
      '講義室5104',
      '5104 講義室',
    ],
    pinX: 0.64,
    pinY: 0.84,
    description: '5号館1階・5104（室番のみ）',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '5',
    buildingDisplayName: '5号館',
    floor: 1,
    roomCode: '5105',
    searchTerms: [
      '5105',
      '05105',
      '５１０５',
      '5105号室',
      '5105号',
      '5105講義室',
      '講義室5105',
      '5105 講義室',
    ],
    pinX: 0.54,
    pinY: 0.84,
    description: '5号館1階・5105（室番のみ）',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '5',
    buildingDisplayName: '5号館',
    floor: 1,
    roomCode: '5106',
    searchTerms: [
      '5106',
      '05106',
      '５１０６',
      '5106号室',
      '5106号',
      '5106講義室',
      '講義室5106',
      '5106 講義室',
    ],
    pinX: 0.34,
    pinY: 0.84,
    description: '5号館1階・5106（室番のみ）',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '5',
    buildingDisplayName: '5号館',
    floor: 1,
    roomCode: '5107',
    searchTerms: [
      '5107',
      '05107',
      '５１０７',
      '5107号室',
      '5107号',
      '5107講義室',
      '講義室5107',
      '5107 講義室',
    ],
    pinX: 0.23,
    pinY: 0.84,
    description: '5号館1階・5107（室番のみ）',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '5',
    buildingDisplayName: '5号館',
    floor: 1,
    roomCode: '5108',
    searchTerms: [
      '5108',
      '05108',
      '５１０８',
      '5108号室',
      '5108号',
      '5108講義室',
      '講義室5108',
      '5108 講義室',
    ],
    pinX: 0.05,
    pinY: 0.75,
    description: '5号館1階・5108（室番のみ）',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '5',
    buildingDisplayName: '5号館',
    floor: 1,
    roomCode: '5109',
    searchTerms: [
      '5109',
      '05109',
      '５１０９',
      '5109号室',
      '5109号',
      '5109講義室',
      '講義室5109',
      '5109 講義室',
    ],
    pinX: 0.05,
    pinY: 0.28,
    description: '5号館1階・5109（室番のみ）',
  ),
];

List<CampusClassroomLocation> searchPilotNarashino5f1(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) =>
      pilotLocationMatchesQuery(r, q);
  return pilotNarashinoBuilding5Floor1.where(matches).toList();
}
