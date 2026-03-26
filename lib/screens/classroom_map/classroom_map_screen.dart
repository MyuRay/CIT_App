import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/classroom_map_provider.dart';
import 'classroom_map_list_tab.dart';
import 'classroom_map_map_tab.dart';

/// 教室マップ画面
/// - タブ1: 教室一覧（校舎・階でフィルター）
/// - タブ2: Googleマップ上に校舎マーカー表示
class ClassroomMapScreen extends ConsumerStatefulWidget {
  const ClassroomMapScreen({super.key, this.initialCampusId});

  final String? initialCampusId;

  @override
  ConsumerState<ClassroomMapScreen> createState() => _ClassroomMapScreenState();
}

class _ClassroomMapScreenState extends ConsumerState<ClassroomMapScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCampusId = 'tsudanuma';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.initialCampusId != null) {
      _selectedCampusId = widget.initialCampusId!;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapDataAsync = ref.watch(campusMapDataProvider);
    final buildingRoomsAsync = ref.watch(buildingRoomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('教室マップ'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: '教室一覧'),
            Tab(icon: Icon(Icons.map), text: 'マップ'),
          ],
        ),
      ),
      body: mapDataAsync.when(
        data: (mapData) {
          return TabBarView(
            controller: _tabController,
            children: [
              ClassroomMapListTab(
                mapData: mapData,
                buildingRoomsAsync: buildingRoomsAsync,
                selectedCampusId: _selectedCampusId,
                onCampusChanged: (id) => setState(() => _selectedCampusId = id),
              ),
              ClassroomMapMapTab(
                mapData: mapData,
                selectedCampusId: _selectedCampusId,
                onCampusChanged: (id) => setState(() => _selectedCampusId = id),
              ),
            ],
          );
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
