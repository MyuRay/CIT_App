import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesNarashino3F1AppSchematic(CampusClassroomLocation room) {
  return room.campus == 'narashino' &&
      room.buildingId == '3' &&
      room.floor == 1;
}

/// 新習志野3号館1階（アプリ同梱フロア図、正規化座標 0〜1・左上原点）。
/// 図に **教室番号と施設名の両方** がある区画のみ。
/// ※エネルギーセンターなど番号のみ／名称のみの区画は含めない。
const List<CampusClassroomLocation> pilotNarashinoBuilding3Floor1 = [
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '3',
    buildingDisplayName: '3号館',
    floor: 1,
    roomCode: '3101',
    searchTerms: [
      '3101',
      '03101',
      '３１０１',
      '3101号室',
      '3101号',
      '教育センター共同研究室3',
      '教育センター共同研究室 3',
      '教育センター共同研究室',
      '共同研究室',
    ],
    pinX: 0.02,
    pinY: 0.05,
    description: '3号館1階・教育センター共同研究室3',
    pinLabel: '教育センター共同研究室3',
    pinMarkerScale: 0.5,
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '3',
    buildingDisplayName: '3号館',
    floor: 1,
    roomCode: '3102',
    searchTerms: [
      '3102',
      '03102',
      '３１０２',
      '3102号室',
      '3102号',
      '化学第1実験研究室',
      '化学第１実験研究室',
      '化学研究室',
      '実験研究室',
    ],
    pinX: 0.08,
    pinY: 0.08,
    description: '3号館1階・化学第1実験研究室',
    pinLabel: '化学第1実験研究室',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '3',
    buildingDisplayName: '3号館',
    floor: 1,
    roomCode: '3103',
    searchTerms: [
      '3103',
      '03103',
      '３１０３',
      '3103号室',
      '3103号',
      '化学第1実験室',
      '化学第１実験室',
    ],
    pinX: 0.24,
    pinY: 0.08,
    description: '3号館1階・化学第1実験室',
    pinLabel: '化学第1実験室',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '3',
    buildingDisplayName: '3号館',
    floor: 1,
    roomCode: '3104',
    searchTerms: [
      '3104',
      '03104',
      '３１０４',
      '3104号室',
      '3104号',
      '化学第2実験室',
      '化学第２実験室',
    ],
    pinX: 0.37,
    pinY: 0.08,
    description: '3号館1階・化学第2実験室',
    pinLabel: '化学第2実験室',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '3',
    buildingDisplayName: '3号館',
    floor: 1,
    roomCode: '3105',
    searchTerms: [
      '3105',
      '03105',
      '３１０５',
      '3105号室',
      '3105号',
      '化学第3実験室',
      '化学第３実験室',
    ],
    pinX: 0.50,
    pinY: 0.08,
    description: '3号館1階・化学第3実験室',
    pinLabel: '化学第3実験室',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '3',
    buildingDisplayName: '3号館',
    floor: 1,
    roomCode: '3106',
    searchTerms: [
      '3106',
      '03106',
      '３１０６',
      '3106号室',
      '3106号',
      '化学第4実験室',
      '化学第４実験室',
    ],
    pinX: 0.63,
    pinY: 0.08,
    description: '3号館1階・化学第4実験室',
    pinLabel: '化学第4実験室',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '3',
    buildingDisplayName: '3号館',
    floor: 1,
    roomCode: '3107',
    searchTerms: [
      '3107',
      '03107',
      '３１０７',
      '3107号室',
      '3107号',
      '化学第5実験室',
      '化学第５実験室',
    ],
    pinX: 0.76,
    pinY: 0.08,
    description: '3号館1階・化学第5実験室',
    pinLabel: '化学第5実験室',
  ),
  CampusClassroomLocation(
    campus: 'narashino',
    buildingId: '3',
    buildingDisplayName: '3号館',
    floor: 1,
    roomCode: '3108',
    searchTerms: [
      '3108',
      '03108',
      '３１０８',
      '3108号室',
      '3108号',
      '物理第1準備室',
      '物理第１準備室',
      '準備室',
    ],
    pinX: 0.93,
    pinY: 0.02,
    description: '3号館1階・物理第1準備室',
    pinLabel: '物理第1準備室',
    pinMarkerScale: 0.7,
  ),
];

List<CampusClassroomLocation> searchPilotNarashino3f1(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];

  bool matches(CampusClassroomLocation r) => pilotLocationMatchesQuery(r, q);

  return pilotNarashinoBuilding3Floor1.where(matches).toList();
}
