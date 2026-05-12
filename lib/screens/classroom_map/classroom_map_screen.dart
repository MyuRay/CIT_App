import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/classroom_map_provider.dart';
import '../../widgets/campus/classroom_search_pilot_section.dart';
// 後続PRで教室一覧タブを復帰する際に有効化
// import 'classroom_map_list_tab.dart';
import 'classroom_map_map_tab.dart';

/// 教室マップ画面の AppBar 高さ（`AppBar.toolbarHeight`）。
/// 必要に応じてこの数値を変更してください（省略時の目安は [kToolbarHeight]）。
const double kClassroomMapAppBarToolbarHeight = kToolbarHeight;

/// 検索カードの下・地図とのあいだの余白（`Padding` の bottom のみ。子ウィジェットは増やさない）。
const double kClassroomMapSearchSectionBottomSpacing = 24;

/// 検索フィルター（津田沼・新習志野のどちらを候補に含めるか）の保存キー。
const String _prefsKeyClassroomMapSearchCampusIds =
    'classroom_map_search_allowed_campus_ids';

/// 「教室・学内施設を探す」の検索候補キャンパス許可セットの復元／保存。
abstract final class ClassroomMapSearchCampusPrefs {
  static Future<Set<String>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_prefsKeyClassroomMapSearchCampusIds);
    if (ids == null || ids.isEmpty) return null;
    const known = {'tsudanuma', 'narashino'};
    final next =
        ids.map((s) => s.trim()).where(known.contains).toSet();
    if (next.isEmpty) return null;
    return next;
  }

  static Future<void> save(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    const known = {'tsudanuma', 'narashino'};
    final list =
        ids.map((s) => s.trim()).where(known.contains).toList()..sort();
    if (list.isEmpty) {
      await prefs.remove(_prefsKeyClassroomMapSearchCampusIds);
      return;
    }
    await prefs.setStringList(_prefsKeyClassroomMapSearchCampusIds, list);
  }
}

/// 教室マップ画面
/// - 現状: マップのみ（教室一覧は後続PR）
/// - マップ: OpenStreetMap 上に校舎マーカー表示
class ClassroomMapScreen extends ConsumerStatefulWidget {
  const ClassroomMapScreen({super.key, this.initialCampusId, this.initialSearchQuery});

  final String? initialCampusId;

  /// 「教室・学内施設を探す」の初期キーワード（例: 時間割の教室欄から遷移時）。
  final String? initialSearchQuery;

  @override
  ConsumerState<ClassroomMapScreen> createState() => _ClassroomMapScreenState();
}

class _ClassroomMapScreenState extends ConsumerState<ClassroomMapScreen> {
  String _selectedCampusId = 'tsudanuma';

  /// 教室・学内施設を探す：検索候補に含める pilot キャンパス（津田沼・新習志野）。
  final Set<String> _searchPilotCampusIds = {'tsudanuma', 'narashino'};

  @override
  void initState() {
    super.initState();
    if (widget.initialCampusId != null) {
      _selectedCampusId = widget.initialCampusId!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreSearchCampuses());
  }

  Future<void> _restoreSearchCampuses() async {
    try {
      final saved = await ClassroomMapSearchCampusPrefs.load();
      if (!mounted || saved == null) return;
      setState(() {
        _searchPilotCampusIds
          ..clear()
          ..addAll(saved);
      });
    } catch (_) {
      /* 永続化失敗時は既定（両キャンパス）のまま */
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapDataAsync = ref.watch(campusMapDataProvider);
    // 教室一覧タブ復帰時: buildingRoomsProvider を watch し ClassroomMapListTab に渡す
    // final buildingRoomsAsync = ref.watch(buildingRoomsProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: kClassroomMapAppBarToolbarHeight,
        title: const Text('教室マップ'),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _searchCampusMarkTab(
                  context: context,
                  label: '津',
                  campusId: 'tsudanuma',
                  activeColor: Colors.blue.shade700,
                  inactiveTint: Colors.blue,
                ),
                const SizedBox(width: 6),
                _searchCampusMarkTab(
                  context: context,
                  label: '新',
                  campusId: 'narashino',
                  activeColor: Colors.green.shade700,
                  inactiveTint: Colors.green,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '検索で表示するキャンパス',
            onPressed: () => _showSearchCampusFilterDialog(context),
          ),
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  kClassroomMapSearchSectionBottomSpacing,
                ),
                child: ClassroomSearchPilotSection(
                  allowedCampusIds: _searchPilotCampusIds,
                  initialSearchQuery: widget.initialSearchQuery,
                ),
              ),
              Expanded(
                child: ClassroomMapMapTab(
                  mapData: mapData,
                  selectedCampusId: _selectedCampusId,
                  onCampusChanged: (id) => setState(() => _selectedCampusId = id),
                ),
              ),
            ],
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

  /// 検索対象キャンパス（津／新）の見やすさ用マーク。歯車の左に並べる。
  Widget _searchCampusMarkTab({
    required BuildContext context,
    required String label,
    required String campusId,
    required Color activeColor,
    required MaterialColor inactiveTint,
  }) {
    final active = _searchPilotCampusIds.contains(campusId);
    final theme = Theme.of(context);
    final bg = active
        ? activeColor
        : inactiveTint.withValues(alpha: 0.2);
    final fg = active
        ? Colors.white
        : inactiveTint.withValues(alpha: 0.45);
    final borderColor = active
        ? activeColor.withValues(alpha: 0.9)
        : inactiveTint.withValues(alpha: 0.35);
    final tooltip = campusId == 'tsudanuma'
        ? (active
            ? '津田沼キャンパスは検索対象です'
            : '津田沼キャンパスは検索対象外です')
        : (active
            ? '新習志野キャンパスは検索対象です'
            : '新習志野キャンパスは検索対象外です');
    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: active ? 1.5 : 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }

  void _showSearchCampusFilterDialog(BuildContext context) {
    final draft = {..._searchPilotCampusIds};
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void setTsudanuma(bool? v) {
              setDialogState(() {
                if (v == true) {
                  draft.add('tsudanuma');
                } else {
                  draft.remove('tsudanuma');
                  if (draft.isEmpty) draft.add('narashino');
                }
              });
            }

            void setNarashino(bool? v) {
              setDialogState(() {
                if (v == true) {
                  draft.add('narashino');
                } else {
                  draft.remove('narashino');
                  if (draft.isEmpty) draft.add('tsudanuma');
                }
              });
            }

            return AlertDialog(
              title: const Text('検索で表示するキャンパス'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    value: draft.contains('tsudanuma'),
                    onChanged: setTsudanuma,
                    title: const Text('津田沼キャンパス'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    value: draft.contains('narashino'),
                    onChanged: setNarashino,
                    title: const Text('新習志野キャンパス'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'どちらか一方以上をオンにしてください。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed: () async {
                    final next = {...draft};
                    setState(() {
                      _searchPilotCampusIds
                        ..clear()
                        ..addAll(next);
                    });
                    await ClassroomMapSearchCampusPrefs.save(_searchPilotCampusIds);
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
