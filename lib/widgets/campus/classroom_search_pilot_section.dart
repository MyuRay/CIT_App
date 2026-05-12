import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data/campus/classroom_map_pilot_search.dart';
import '../../models/campus/campus_classroom_location.dart';
import 'floor_map_with_pin_viewer.dart';

/// 教室マップの「教室・学内施設を探す」検索欄。
/// 検索候補は [classroom_map_pilot_search] が束ねる各 campus の pilot データに随時追加していく想定。
///
/// [allowedCampusIds] に含まれるキャンパス（例: `tsudanuma`, `narashino`）の候補だけを表示する。
class ClassroomSearchPilotSection extends ConsumerStatefulWidget {
  const ClassroomSearchPilotSection({
    super.key,
    required this.allowedCampusIds,
    this.initialSearchQuery,
  });

  /// 検索結果に含める `CampusClassroomLocation.campus` の値。
  final Set<String> allowedCampusIds;

  /// 表示直後から検索欄に流し込むテキスト（深リンク・時間割の教室欄からの遷移用）。
  final String? initialSearchQuery;

  @override
  ConsumerState<ClassroomSearchPilotSection> createState() =>
      _ClassroomSearchPilotSectionState();
}

class _ClassroomSearchPilotSectionState
    extends ConsumerState<ClassroomSearchPilotSection> {
  final TextEditingController _controller = TextEditingController();
  List<CampusClassroomLocation> _results = const [];

  @override
  void reassemble() {
    super.reassemble();
    // Hot reload後に pinX/pinY 更新を確実に反映する。
    _applyResults();
  }

  @override
  void initState() {
    super.initState();
    final q = widget.initialSearchQuery?.trim();
    if (q != null && q.isNotEmpty) {
      _controller.text = q;
    }
    _controller.addListener(_onQueryChanged);
    _results = _computeResults();
  }

  List<CampusClassroomLocation> _computeResults() {
    final raw = searchClassroomMapPilotLocations(_controller.text);
    return raw.where((r) => widget.allowedCampusIds.contains(r.campus)).toList();
  }

  @override
  void didUpdateWidget(ClassroomSearchPilotSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameCampusSet(oldWidget.allowedCampusIds, widget.allowedCampusIds)) {
      _applyResults();
    }
  }

  bool _sameCampusSet(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    for (final e in a) {
      if (!b.contains(e)) return false;
    }
    return true;
  }

  void _onQueryChanged() => _applyResults();

  void _applyResults() {
    setState(() {
      _results = _computeResults();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxResultListHeight = (MediaQuery.sizeOf(context).height * 0.42)
        .clamp(200.0, 440.0);
    final searchFieldTypography = Theme.of(context).textTheme.bodySmall
        ?.copyWith(fontSize: 11, height: 1.2);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.search,
                  size: 22,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '教室・学内施設を探す',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (_searchCampusFilterSummary(
              widget.allowedCampusIds,
            ).isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _searchCampusFilterSummary(widget.allowedCampusIds),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              style: searchFieldTypography,
              decoration: InputDecoration(
                hintText: 'ここに教室番号または施設名称を入力',
                hintStyle: searchFieldTypography?.copyWith(
                  color:
                      Theme.of(context).hintColor.withValues(alpha: 0.75),
                ),
                prefixIcon:
                    const Icon(Icons.class_outlined, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
              ),
              textInputAction: TextInputAction.search,
            ),
            const SizedBox(height: 12),
            if (_controller.text.trim().isEmpty)
              Text(
                'キーワードを入力すると候補が表示されます。',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else if (_results.isEmpty)
              Text(
                '該当する候補がありません。',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.orange.shade800),
              )
            else
              Semantics(
                label: '検索候補一覧',
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxResultListHeight),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final room = _results[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        isThreeLine: room.pinMapLabel.length > 24,
                        title: Text(
                          room.pinMapLabel,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 6,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${room.roomCode} · ${_campusDisplayName(room.campus)} · '
                          '${room.buildingDisplayName} ${room.floorCaption}',
                        ),
                        trailing: FilledButton.tonal(
                          onPressed:
                              () =>
                                  showFloorMapWithPinDialog(context, ref, room),
                          child: const Text('教室の詳細'),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _campusDisplayName(String campusId) {
  switch (campusId) {
    case 'tsudanuma':
      return '津田沼キャンパス';
    case 'narashino':
      return '新習志野キャンパス';
    default:
      return campusId;
  }
}

/// 両方選んでいるときは空（表示省略）。片方だけのとき検索対象の注記。
String _searchCampusFilterSummary(Set<String> ids) {
  const all = {'tsudanuma', 'narashino'};
  if (ids.length >= all.length && all.every(ids.contains)) {
    return '';
  }
  final parts = <String>[];
  if (ids.contains('tsudanuma')) parts.add('津田沼');
  if (ids.contains('narashino')) parts.add('新習志野');
  if (parts.isEmpty) return '検索対象のキャンパスが未選択です。';
  return '検索対象: ${parts.join('、')}のみ';
}
