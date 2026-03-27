import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/classroom_map/classroom_map_model.dart';
import '../../services/classroom_map/classroom_map_service.dart';

/// キャンパスマップデータ（校舎マーカー含む）
final campusMapDataProvider =
    FutureProvider<CampusMapData>((ref) => ClassroomMapService.getCampusMapData());

/// 校舎別教室一覧
final buildingRoomsProvider =
    FutureProvider<List<BuildingRooms>>((ref) => ClassroomMapService.getBuildingRooms());
