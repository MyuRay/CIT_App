import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';
import 'pilot_narashino_1f1_classrooms.dart';
import 'pilot_narashino_2f1_classrooms.dart';
import 'pilot_narashino_3f1_classrooms.dart';
import 'pilot_narashino_3f2_classrooms.dart';
import 'pilot_narashino_3f3_classrooms.dart';
import 'pilot_narashino_5f1_classrooms.dart';
import 'pilot_narashino_5f2_classrooms.dart';
import 'pilot_narashino_5f3_classrooms.dart';
import 'pilot_narashino_7f1_classrooms.dart';
import 'pilot_narashino_7f2_classrooms.dart';
import 'pilot_narashino_8f1_classrooms.dart';
import 'pilot_narashino_8f2_classrooms.dart';
import 'pilot_narashino_12f1_classrooms.dart';
import 'pilot_narashino_12f2_classrooms.dart';
import 'pilot_narashino_12f3_classrooms.dart';
import 'pilot_narashino_12f4_classrooms.dart';
import 'pilot_narashino_12f5_classrooms.dart';
import 'pilot_narashino_12f6_classrooms.dart';
import 'pilot_narashino_12f7_classrooms.dart';
import 'pilot_narashino_12f8_classrooms.dart';
import 'pilot_tsudanuma_4_b1_classrooms.dart';
import 'pilot_tsudanuma_4_b2_classrooms.dart';
import 'pilot_tsudanuma_4_1f_classrooms.dart';
import 'pilot_tsudanuma_4_2f_classrooms.dart';
import 'pilot_tsudanuma_4_3f_classrooms.dart';
import 'pilot_tsudanuma_4_4f_classrooms.dart';
import 'pilot_tsudanuma_4_5f_classrooms.dart';
import 'pilot_tsudanuma_4_6f_classrooms.dart';
import 'pilot_tsudanuma_4_7f_classrooms.dart';
import 'pilot_tsudanuma_4_8f_classrooms.dart';
import 'pilot_tsudanuma_4_9f_classrooms.dart';
import 'pilot_tsudanuma_6_1f_classrooms.dart';
import 'pilot_tsudanuma_6_2f_classrooms.dart';
import 'pilot_tsudanuma_6_3f_classrooms.dart';
import 'pilot_tsudanuma_6_4f_classrooms.dart';
import 'pilot_tsudanuma_6_5f_classrooms.dart';
import 'pilot_tsudanuma_7f1_classrooms.dart';
import 'pilot_tsudanuma_7f2_classrooms.dart';
import 'pilot_tsudanuma_7f3_classrooms.dart';
import 'pilot_tsudanuma_7f4_classrooms.dart';
import 'pilot_tsudanuma_7f5_classrooms.dart';
import 'pilot_tsudanuma_7f6_classrooms.dart';
import 'pilot_tsudanuma_7f7_classrooms.dart';
import 'pilot_tsudanuma_7f8_classrooms.dart';
import 'pilot_tsudanuma_7f9_classrooms.dart';

/// 検索候補に古い `CampusClassroomLocation` が残っていても、
/// **いまの**パイロット定義の `pinX` / `pinY` を使う。
CampusClassroomLocation resolveLatestPilotLocation(CampusClassroomLocation room) {
  final List<CampusClassroomLocation>? list = _pilotSourceListFor(room);
  if (list == null || list.isEmpty) return room;

  final labelKey = room.pinLabel ?? '';
  final withCodeAndLabel =
      list
          .where(
            (r) => r.roomCode == room.roomCode && (r.pinLabel ?? '') == labelKey,
          )
          .toList();
  if (withCodeAndLabel.length == 1) return withCodeAndLabel.single;

  final withCode = list.where((r) => r.roomCode == room.roomCode).toList();
  if (withCode.length == 1) return withCode.single;

  return room;
}

List<CampusClassroomLocation>? _pilotSourceListFor(CampusClassroomLocation room) {
  if (room.campus == 'tsudanuma' && room.buildingId == '4') {
    if (room.floor == 9) return pilotTsudanumaBuilding4Floor9;
    if (room.floor == 7) return pilotTsudanumaBuilding4Floor7;
    if (room.floor == 6) return pilotTsudanumaBuilding4Floor6;
    if (room.floor == 5) return pilotTsudanumaBuilding4Floor5;
    if (room.floor == 4) return pilotTsudanumaBuilding4Floor4;
    if (room.floor == 3) return pilotTsudanumaBuilding4Floor3;
    if (room.floor == 2) return pilotTsudanumaBuilding4Floor2;
    if (room.floor == 1) return pilotTsudanumaBuilding4Floor1;
    if (room.floor == -1) return pilotTsudanumaBuilding4FloorB1;
    if (room.floor == -2) return pilotTsudanumaBuilding4FloorB2;
    return null;
  }
  if (room.campus == 'tsudanuma' && room.buildingId == '6') {
    if (room.floor == 1) return pilotTsudanumaBuilding6Floor1;
    if (room.floor == 2) return pilotTsudanumaBuilding6Floor2;
    if (room.floor == 3) return pilotTsudanumaBuilding6Floor3;
    if (room.floor == 4) return pilotTsudanumaBuilding6Floor4;
    if (room.floor == 5) return pilotTsudanumaBuilding6Floor5;
    return null;
  }
  if (room.campus == 'tsudanuma' && room.buildingId == '7') {
    if (room.floor == 9) return pilotTsudanumaBuilding7Floor9;
    if (room.floor == 8) return pilotTsudanumaBuilding7Floor8;
    if (room.floor == 7) return pilotTsudanumaBuilding7Floor7;
    if (room.floor == 6) return pilotTsudanumaBuilding7Floor6;
    if (room.floor == 5) return pilotTsudanumaBuilding7Floor5;
    if (room.floor == 4) return pilotTsudanumaBuilding7Floor4;
    if (room.floor == 3) return pilotTsudanumaBuilding7Floor3;
    if (room.floor == 2) return pilotTsudanumaBuilding7Floor2;
    if (room.floor == 1) return pilotTsudanumaBuilding7Floor1;
    return null;
  }
  if (room.campus == 'narashino' && room.buildingId == '1' && room.floor == 1) {
    return pilotNarashinoBuilding1Floor1;
  }
  if (room.campus == 'narashino' && room.buildingId == '2' && room.floor == 1) {
    return pilotNarashinoBuilding2Floor1;
  }
  if (room.campus == 'narashino' && room.buildingId == '3') {
    if (room.floor == 3) return pilotNarashinoBuilding3Floor3;
    if (room.floor == 2) return pilotNarashinoBuilding3Floor2;
    if (room.floor == 1) return pilotNarashinoBuilding3Floor1;
  }
  if (room.campus == 'narashino' && room.buildingId == '5') {
    if (room.floor == 3) return pilotNarashinoBuilding5Floor3;
    if (room.floor == 2) return pilotNarashinoBuilding5Floor2;
    if (room.floor == 1) return pilotNarashinoBuilding5Floor1;
  }
  if (room.campus == 'narashino' && room.buildingId == '8') {
    if (room.floor == 2) return pilotNarashinoBuilding8Floor2;
    if (room.floor == 1) return pilotNarashinoBuilding8Floor1;
  }
  if (room.campus == 'narashino' && room.buildingId == '7') {
    if (room.floor == 2) return pilotNarashinoBuilding7Floor2;
    if (room.floor == 1) return pilotNarashinoBuilding7Floor1;
  }
  if (room.campus == 'narashino' && room.buildingId == '12') {
    if (room.floor == 8) return pilotNarashinoBuilding12Floor8;
    if (room.floor == 7) return pilotNarashinoBuilding12Floor7;
    if (room.floor == 6) return pilotNarashinoBuilding12Floor6;
    if (room.floor == 5) return pilotNarashinoBuilding12Floor5;
    if (room.floor == 4) return pilotNarashinoBuilding12Floor4;
    if (room.floor == 3) return pilotNarashinoBuilding12Floor3;
    if (room.floor == 2) return pilotNarashinoBuilding12Floor2;
    if (room.floor == 1) return pilotNarashinoBuilding12Floor1;
  }
  return null;
}

/// 教室マップ検索の統合（津田沼4号館・新習志野各号館のパイロット階など）。
///
/// 候補は [classroomMapPilotMatchRank] で並べ、クエリで**始まる**名称・番号を優先する。
List<CampusClassroomLocation> searchClassroomMapPilotLocations(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final merged = <CampusClassroomLocation>[
    ...searchPilotTsudanuma4F1(query),
    ...searchPilotTsudanuma4F2(query),
    ...searchPilotTsudanuma4F3(query),
    ...searchPilotTsudanuma4F4(query),
    ...searchPilotTsudanuma4F5(query),
    ...searchPilotTsudanuma4F6(query),
    ...searchPilotTsudanuma4F7(query),
    ...searchPilotTsudanuma4F8(query),
    ...searchPilotTsudanuma4F9(query),
    ...searchPilotTsudanuma4B1(query),
    ...searchPilotTsudanuma4B2(query),
    ...searchPilotTsudanuma6F1(query),
    ...searchPilotTsudanuma6F2(query),
    ...searchPilotTsudanuma6F3(query),
    ...searchPilotTsudanuma6F4(query),
    ...searchPilotTsudanuma6F5(query),
    ...searchPilotTsudanuma7f1(query),
    ...searchPilotTsudanuma7f2(query),
    ...searchPilotTsudanuma7f3(query),
    ...searchPilotTsudanuma7f4(query),
    ...searchPilotTsudanuma7f5(query),
    ...searchPilotTsudanuma7f6(query),
    ...searchPilotTsudanuma7f7(query),
    ...searchPilotTsudanuma7f8(query),
    ...searchPilotTsudanuma7f9(query),
    ...searchPilotNarashino1f1(query),
    ...searchPilotNarashino2f1(query),
    ...searchPilotNarashino3f1(query),
    ...searchPilotNarashino3f2(query),
    ...searchPilotNarashino3f3(query),
    ...searchPilotNarashino5f1(query),
    ...searchPilotNarashino5f2(query),
    ...searchPilotNarashino5f3(query),
    ...searchPilotNarashino7f1(query),
    ...searchPilotNarashino7f2(query),
    ...searchPilotNarashino8f1(query),
    ...searchPilotNarashino8f2(query),
    ...searchPilotNarashino12f1(query),
    ...searchPilotNarashino12f2(query),
    ...searchPilotNarashino12f3(query),
    ...searchPilotNarashino12f4(query),
    ...searchPilotNarashino12f5(query),
    ...searchPilotNarashino12f6(query),
    ...searchPilotNarashino12f7(query),
    ...searchPilotNarashino12f8(query),
  ];
  merged.sort((a, b) {
    final byRank = classroomMapPilotMatchRank(
      b,
      q,
    ).compareTo(classroomMapPilotMatchRank(a, q));
    if (byRank != 0) return byRank;
    final byCode = a.roomCode.compareTo(b.roomCode);
    if (byCode != 0) return byCode;
    // 同じ部屋コードが複数階にある場合（例: 040301 の 3 階と 4 階）の並びを固定する。
    return a.floor.compareTo(b.floor);
  });
  return merged;
}
