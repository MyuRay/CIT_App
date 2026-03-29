import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/classroom_map_provider.dart';
// 後続PRで教室一覧タブを復帰する際に有効化
// import 'classroom_map_list_tab.dart';
import 'classroom_map_map_tab.dart';

/// 教室マップ画面
/// - 現状: マップのみ（教室一覧は後続PR）
/// - マップ: OpenStreetMap 上に校舎マーカー表示
class ClassroomMapScreen extends ConsumerStatefulWidget {
  const ClassroomMapScreen({super.key, this.initialCampusId});

  final String? initialCampusId;

  @override
  ConsumerState<ClassroomMapScreen> createState() => _ClassroomMapScreenState();
}

class _ClassroomMapScreenState extends ConsumerState<ClassroomMapScreen> {
  String _selectedCampusId = 'tsudanuma';

  @override
  void initState() {
    super.initState();
    if (widget.initialCampusId != null) {
      _selectedCampusId = widget.initialCampusId!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapDataAsync = ref.watch(campusMapDataProvider);
    // 教室一覧タブ復帰時: buildingRoomsProvider を watch し ClassroomMapListTab に渡す
    // final buildingRoomsAsync = ref.watch(buildingRoomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('教室マップ'),
        actions: [
          // ピン座標取得ボタン（デバッグ用）は一時的に無効化
          // if (kDebugMode)
          //   IconButton(
          //     icon: const Icon(Icons.add_location_alt_outlined),
          //     tooltip: 'ピン座標取得（デバッグ）',
          //     onPressed: () => context.push('/debug/classroom-map-calibration'),
          //   ),
        ],
        // 後続PR: 教室一覧タブを戻す場合は TabController(length: 2) と TabBar を復元
        // bottom: TabBar(
        //   controller: _tabController,
        //   tabs: const [
        //     Tab(icon: Icon(Icons.list), text: '教室一覧'),
        //     Tab(icon: Icon(Icons.map), text: 'マップ'),
        //   ],
        // ),
      ),
      body: mapDataAsync.when(
        data: (mapData) {
          return ClassroomMapMapTab(
            mapData: mapData,
            selectedCampusId: _selectedCampusId,
            onCampusChanged: (id) => setState(() => _selectedCampusId = id),
          );
          // 後続PR: TabBarView + 以下を復元
          // TabBarView(
          //   controller: _tabController,
          //   children: [
          //     ClassroomMapListTab(
          //       mapData: mapData,
          //       buildingRoomsAsync: buildingRoomsAsync,
          //       selectedCampusId: _selectedCampusId,
          //       onCampusChanged: (id) => setState(() => _selectedCampusId = id),
          //     ),
          //     ClassroomMapMapTab(
          //       mapData: mapData,
          //       selectedCampusId: _selectedCampusId,
          //       onCampusChanged: (id) => setState(() => _selectedCampusId = id),
          //     ),
          //   ],
          // );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('データの読み込みに失敗しました', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(e.toString(), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
