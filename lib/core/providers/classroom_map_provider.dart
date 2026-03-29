import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/classroom_map/classroom_map_model.dart';
import '../../services/classroom_map/classroom_map_service.dart';

/// キャンパスマップデータ（校舎マーカー含む）
/// autoDispose: 画面を離れると状態を破棄し、再入場時に再読込する（古い AsyncError の取り残し防止）。
final campusMapDataProvider =
    FutureProvider.autoDispose<CampusMapData>((ref) => ClassroomMapService.getCampusMapData());

/// 校舎別教室一覧
final buildingRoomsProvider =
    FutureProvider.autoDispose<List<BuildingRooms>>((ref) => ClassroomMapService.getBuildingRooms());
