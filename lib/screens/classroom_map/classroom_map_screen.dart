import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/classroom_map_provider.dart';
import '../../widgets/campus/classroom_search_pilot_section.dart';
// 後続PRで教室一覧タブを復帰する際に有効化
// import 'classroom_map_list_tab.dart';
import 'classroom_map_map_tab.dart';

/// 教室マップ画面の AppBar 高さ（`AppBar.toolbarHeight`）。
/// 必要に応じてこの数値を変更してください（省略時の目安は [kToolbarHeight]）。
const double kClassroomMapAppBarToolbarHeight = kToolbarHeight;

/// 教室マップ
class ClassroomMapScreen extends ConsumerStatefulWidget {
  const ClassroomMapScreen({super.key, this.initialCampusId, this.initialSearchQuery});

  final String? initialCampusId;

  /// 「教室または学内施設を探す」の初期キーワード（例: 時間割の教室欄からの遷移時）。
  final String? initialSearchQuery;

  @override
  ConsumerState<ClassroomMapScreen> createState() => _ClassroomMapScreenState();
}

class _ClassroomMapScreenState extends ConsumerState<ClassroomMapScreen> {
  String _selectedCampusId = 'tsudanuma';

  /// 検索バー（コンパクト時は入力欄のみ）の高さ。キャンパス切替の縦位置に反映。
  double _searchSectionHeight = 52;

  /// 検索候補に含める pilot キャンパス（固定：津田沼・新習志野の両方）。
  static const Set<String> _pilotSearchCampusIds = {'tsudanuma', 'narashino'};

  @override
  void initState() {
    super.initState();
    if (widget.initialCampusId != null) {
      _selectedCampusId = widget.initialCampusId!;
    }
  }

  static const double _kSearchBandTopInset = 0;
  static const double _kSearchBandToCampusSwitcherGap = 10;

  void _onCompactSearchBarSized(double height) {
    if ((height - _searchSectionHeight).abs() <= 0.5) return;
    setState(() => _searchSectionHeight = height);
  }

  @override
  Widget build(BuildContext context) {
    final mapDataAsync = ref.watch(campusMapDataProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: kClassroomMapAppBarToolbarHeight,
        title: const Text('教室マップ'),
        // 検索対象キャンパス切り替えはオフ（常に両キャンパスを検索）
      ),
      body: mapDataAsync.when(
        data: (mapData) {
          final campusSwitcherTop = math.max(
            16.0,
            _kSearchBandTopInset +
                _searchSectionHeight +
                _kSearchBandToCampusSwitcherGap,
          );
          return Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              ClassroomMapMapTab(
                mapData: mapData,
                selectedCampusId: _selectedCampusId,
                onCampusChanged: (id) => setState(() => _selectedCampusId = id),
                campusSwitcherTopPadding: campusSwitcherTop,
              ),
              Positioned(
                top: _kSearchBandTopInset,
                left: 0,
                right: 0,
                child: ClassroomSearchPilotSection(
                  compactToolbarOnly: true,
                  allowedCampusIds: _pilotSearchCampusIds,
                  initialSearchQuery: widget.initialSearchQuery,
                  onCompactSearchBarLayoutHeight: _onCompactSearchBarSized,
                ),
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
