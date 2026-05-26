import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data/campus/classroom_map_pilot_search.dart';
import '../../models/campus/campus_classroom_location.dart';
import 'floor_map_with_pin_viewer.dart';

/// 教室マップの「教室・学内施設を探す」検索欄。
/// 検索候補は [classroom_map_pilot_search] が束ねる各 campus の pilot データに随時追加していく想定。
///
/// [allowedCampusIds] に含まれるキャンパス（例: `tsudanuma`, `narashino`）の候補だけを表示する。
///
/// [compactToolbarOnly] が true のときは見出し・キャンパス注記・空欄時の説明文を出さず、
/// ヒント付き検索欄（および入力があるときだけ候補一覧／該当なし）のみを表示する。
///
/// コンパクト時は検索バー直下を地図に開けるため、候補一覧はバーとは別レイヤーのカードとして重ねる。
/// [onCompactSearchBarLayoutHeight] に実レイアウト後の検索バー帯の高さだけ渡す（候補カードは含まない）。
class ClassroomSearchPilotSection extends ConsumerStatefulWidget {
  const ClassroomSearchPilotSection({
    super.key,
    required this.allowedCampusIds,
    this.initialSearchQuery,
    this.compactToolbarOnly = false,
    this.onCompactSearchBarLayoutHeight,
  });

  /// 検索結果に含める `CampusClassroomLocation.campus` の値。
  final Set<String> allowedCampusIds;

  /// 表示直後から検索欄に流し込むテキスト（深リンク・時間割の教室欄からの遷移用）。
  final String? initialSearchQuery;

  /// 教室マップ上部ツールバー用の省略レイアウト（入力欄のみ常時表示）。
  final bool compactToolbarOnly;

  /// コンパクト時のみ：検索バー（Material 帯）のレイアウト高さ。キャンパス切替位置などに利用。
  final ValueChanged<double>? onCompactSearchBarLayoutHeight;

  @override
  ConsumerState<ClassroomSearchPilotSection> createState() =>
      _ClassroomSearchPilotSectionState();
}

class _ClassroomSearchPilotSectionState
    extends ConsumerState<ClassroomSearchPilotSection> {
  final TextEditingController _controller = TextEditingController();
  List<CampusClassroomLocation> _results = const [];

  final GlobalKey _compactSearchBarMaterialKey = GlobalKey();

  static const double _kCompactResultsGapBelowBar = 8;

  /// 親へ報告済みの検索バー帯の高さ（再レイアウトで無駄な setState を避ける）。
  double _reportedCompactSearchBarHeight = 0;

  void _scheduleCompactSearchBarMeasure() {
    if (!widget.compactToolbarOnly) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.compactToolbarOnly) return;
      final box =
          _compactSearchBarMaterialKey.currentContext?.findRenderObject()
              as RenderBox?;
      if (box == null || !box.hasSize) return;
      final h = box.size.height;
      if ((h - _reportedCompactSearchBarHeight).abs() <= 0.5) return;
      _reportedCompactSearchBarHeight = h;
      widget.onCompactSearchBarLayoutHeight?.call(h);
    });
  }

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
    final theme = Theme.of(context);
    final searchFieldTypography =
        widget.compactToolbarOnly
            ? theme.textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w500,
              )
            : theme.textTheme.bodySmall?.copyWith(fontSize: 11, height: 1.2);
    const searchOutlineRadius = BorderRadius.all(Radius.circular(12));

    final searchField = TextField(
      controller: _controller,
      style: searchFieldTypography,
      decoration: InputDecoration(
        hintText: 'ここに教室番号・施設名を入力',
        hintStyle: searchFieldTypography?.copyWith(
          color: Theme.of(context).hintColor.withValues(alpha: 0.75),
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          widget.compactToolbarOnly ? Icons.search : Icons.class_outlined,
          size: widget.compactToolbarOnly ? 22 : 18,
        ),
        filled: widget.compactToolbarOnly,
        fillColor: widget.compactToolbarOnly
            ? theme.colorScheme.surface.withValues(alpha: 0.93)
            : null,
        border: const OutlineInputBorder(borderRadius: searchOutlineRadius),
        focusedBorder:
            widget.compactToolbarOnly
                ? OutlineInputBorder(
                    borderRadius: searchOutlineRadius,
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  )
                : null,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          vertical: widget.compactToolbarOnly ? 12 : 10,
        ),
      ),
      textInputAction: TextInputAction.search,
    );

    final Widget? compactFloatingPanel;
    final queryTrimmed = _controller.text.trim();
    if (widget.compactToolbarOnly) {
      if (queryTrimmed.isEmpty) {
        compactFloatingPanel = null;
      } else if (_results.isEmpty) {
        compactFloatingPanel = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            '該当する候補がありません。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange.shade800,
                ),
          ),
        );
      } else {
        compactFloatingPanel = Semantics(
          label: '検索候補一覧',
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxResultListHeight),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              shrinkWrap: true,
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final room = _results[index];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
                    onPressed: () =>
                        showFloorMapWithPinDialog(context, ref, room),
                    child: const Text('教室の詳細'),
                  ),
                );
              },
            ),
          ),
        );
      }
    } else {
      compactFloatingPanel = null;
    }

    final Widget trailingContent;
    if (widget.compactToolbarOnly) {
      trailingContent = const SizedBox.shrink();
    } else {
      trailingContent =
          queryTrimmed.isEmpty
              ? Text(
                  'キーワードを入力すると候補が表示されます。',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              : _results.isEmpty
                  ? Text(
                      '該当する候補がありません。',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade800,
                          ),
                    )
                  : Semantics(
                      label: '検索候補一覧',
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(maxHeight: maxResultListHeight),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _results.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final room = _results[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              isThreeLine: room.pinMapLabel.length > 24,
                              title: Text(
                                room.pinMapLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 6,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${room.roomCode} · ${_campusDisplayName(room.campus)} · '
                                '${room.buildingDisplayName} ${room.floorCaption}',
                              ),
                              trailing: FilledButton.tonal(
                                onPressed: () =>
                                    showFloorMapWithPinDialog(context, ref, room),
                                child: const Text('教室の詳細'),
                              ),
                            );
                          },
                        ),
                      ),
                    );
    }

    final innerColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.compactToolbarOnly) ...[
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
          if (_searchCampusFilterSummary(widget.allowedCampusIds).isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _searchCampusFilterSummary(widget.allowedCampusIds),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
          ],
          const SizedBox(height: 12),
        ],
        searchField,
        if (!widget.compactToolbarOnly) const SizedBox(height: 12),
        if (!widget.compactToolbarOnly) trailingContent,
      ],
    );

    if (widget.compactToolbarOnly) {
      _scheduleCompactSearchBarMeasure();
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            key: _compactSearchBarMaterialKey,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: searchField,
            ),
          ),
          if (compactFloatingPanel != null) ...[
            IgnorePointer(
              child: SizedBox(height: _kCompactResultsGapBelowBar),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surface,
                clipBehavior: Clip.antiAlias,
                child: compactFloatingPanel,
              ),
            ),
          ],
        ],
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: innerColumn,
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
