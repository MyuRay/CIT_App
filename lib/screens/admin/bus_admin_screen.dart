import '../../core/theme/app_colors.dart';
import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/schedule/lecture_period_service.dart';
import '../../core/providers/bus_provider.dart';
import '../../models/bus/bus_timetable_draft.dart';
import '../../services/bus/bus_timetable_admin_service.dart';
import '../../widgets/bus/bus_departure_dialog.dart';
import 'bus_timetable_editor_screen.dart';

class BusAdminScreen extends ConsumerStatefulWidget {
  const BusAdminScreen({super.key});

  @override
  ConsumerState<BusAdminScreen> createState() => _BusAdminScreenState();
}

class _BusAdminScreenState extends ConsumerState<BusAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _routeSearchCtrl = TextEditingController();
  String _routeSearch = '';
  String _routeStatusFilter = 'all'; // all, active, suspended
  // 時刻表タブ用の状態
  final TextEditingController _scheduleSearchCtrl = TextEditingController();
  String _scheduleSearch = '';
  String _scheduleDayType = 'weekday'; // weekday, saturday, sunday
  bool _scheduleHideInactive = true;
  bool _openingTimetable = false;
  DateTime? _springStartDate;
  DateTime? _springEndDate;
  DateTime? _fallStartDate;
  DateTime? _fallEndDate;
  bool _isSavingLecturePeriod = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _routeSearchCtrl.dispose();
    _scheduleSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学バス管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _openLecturePeriodEditorFromAppBar,
            tooltip: '講義期間設定',
          ),
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: _openHomeRemarkEditorFromAppBar,
            tooltip: 'ホーム備考を編集',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addBusRoute,
            tooltip: '路線追加',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: '更新',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '路線管理', icon: Icon(Icons.route)),
            Tab(text: '時刻表', icon: Icon(Icons.schedule)),
            Tab(text: '運行状況', icon: Icon(Icons.directions_bus)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRouteManagement(),
          _buildScheduleManagement(),
          _buildOperationStatus(),
        ],
      ),
    );
  }

  Widget _buildRouteManagement() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('bus_information')
              .doc('main')
              .collection('bus_routes')
              .orderBy('sortOrder')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('路線データの読み込みに失敗しました: ${snapshot.error}');
        }

        var routes = snapshot.data?.docs ?? [];

        // 検索・フィルタ・一括追加ヘッダー
        Widget header = Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _routeSearchCtrl,
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search),
                    hintText: '路線名・区間で検索',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon:
                        _routeSearch.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _routeSearchCtrl.clear();
                                  _routeSearch = '';
                                });
                              },
                            )
                            : null,
                  ),
                  onChanged:
                      (v) => setState(() {
                        _routeSearch = v.trim();
                      }),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _routeStatusFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('すべて')),
                  DropdownMenuItem(value: 'active', child: Text('運行中')),
                  DropdownMenuItem(value: 'suspended', child: Text('停止')),
                ],
                onChanged:
                    (v) => setState(() {
                      _routeStatusFilter = v ?? 'all';
                    }),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.schedule),
                label: const Text('ダイヤへ'),
              ),
            ],
          ),
        );

        if (routes.isEmpty) {
          return Column(
            children: [
              header,
              Expanded(
                child: _buildEmptyWidget(
                  Icons.route,
                  '路線が登録されていません',
                  '右上の＋から路線を登録してください',
                ),
              ),
            ],
          );
        }

        // フィルタリング
        if (_routeSearch.isNotEmpty) {
          final q = _routeSearch.toLowerCase();
          routes =
              routes.where((d) {
                final m = d.data() as Map<String, dynamic>;
                final name = (m['name'] as String? ?? '').toLowerCase();
                final from = (m['fromStation'] as String? ?? '').toLowerCase();
                final to = (m['toStation'] as String? ?? '').toLowerCase();
                return name.contains(q) || from.contains(q) || to.contains(q);
              }).toList();
        }
        if (_routeStatusFilter != 'all') {
          routes =
              routes.where((d) {
                final m = d.data() as Map<String, dynamic>;
                final status =
                    (m['status'] as String?) ??
                    (m['isActive'] == true ? 'active' : 'suspended');
                return status == _routeStatusFilter;
              }).toList();
        }
        return Column(
          children: [
            header,
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: routes.length,
                onReorder: _reorderRoutes,
                itemBuilder: (context, index) {
                  final routeDoc = routes[index];
                  final routeData = routeDoc.data() as Map<String, dynamic>;

                  return Card(
                    key: ValueKey(routeDoc.id),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Icon(Icons.drag_handle),
                            ),
                          ),
                          CircleAvatar(
                            backgroundColor: _parseColor(
                              routeData['color'] ?? '#2196F3',
                            ),
                            child: Text(
                              routeData['shortName'] ??
                                  _firstCharacterOrFallback(
                                    routeData['name'],
                                    'B',
                                  ),
                              style: TextStyle(
                                color: AppColors.onColor(_parseColor(routeData['color'] ?? '#2196F3')),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Text(
                        routeData['name'] ?? '無名路線',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${routeData['fromStation']} → ${routeData['toStation']}',
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildStatusChip(routeData['status'] ?? 'active'),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${routeData['operatingDays']?.length ?? 0}日間運行',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value:
                                (routeData['isActive'] as bool?) ??
                                (routeData['status'] != 'suspended'),
                            onChanged: (v) {
                              if (routeData.containsKey('isActive')) {
                                routeDoc.reference.update({
                                  'isActive': v,
                                  'updatedAt': FieldValue.serverTimestamp(),
                                });
                              }
                              final next = v ? 'active' : 'suspended';
                              routeDoc.reference.update({
                                'status': next,
                                'updatedAt': FieldValue.serverTimestamp(),
                              });
                            },
                          ),
                          PopupMenuButton<String>(
                            onSelected:
                                (action) =>
                                    _handleRouteAction(action, routeDoc),
                            itemBuilder:
                                (context) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('編集'),
                                  ),
                                  PopupMenuItem(
                                    value: 'duplicate',
                                    child: Text('複製'),
                                  ),
                                ],
                          ),
                          PopupMenuButton<String>(
                            onSelected:
                                (action) =>
                                    _handleRouteAction(action, routeDoc),
                            itemBuilder:
                                (context) => [
                                  PopupMenuItem(
                                    value:
                                        (routeData['status'] == 'active')
                                            ? 'suspend'
                                            : 'activate',
                                    child: Text(
                                      routeData['status'] == 'active'
                                          ? '運行停止'
                                          : '運行開始',
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('削除'),
                                  ),
                                ],
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRouteDetailRow(
                                '運行区間',
                                '${routeData['fromStation']} → ${routeData['toStation']}',
                              ),
                              _buildRouteDetailRow(
                                '運行日',
                                _formatOperatingDays(
                                  routeData['operatingDays'],
                                ),
                              ),
                              _buildRouteDetailRow(
                                '運行期間',
                                _formatDateRange(
                                  routeData['startDate'],
                                  routeData['endDate'],
                                ),
                              ),
                              _buildRouteDetailRow(
                                '所要時間',
                                '約${routeData['duration'] ?? '?'}分',
                              ),
                              _buildRouteDetailRow(
                                '運賃',
                                routeData['fare'] != null
                                    ? '￥${routeData['fare']}'
                                    : '無料',
                              ),
                              if (routeData['note'] != null &&
                                  (routeData['note'] as String).isNotEmpty)
                                _buildRouteDetailRow('備考', routeData['note']),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.schedule, size: 18),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '時刻一覧',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed:
                                        () => _showTimeEntryDialog(
                                          routeDoc: routeDoc,
                                        ),
                                    icon: const Icon(Icons.add),
                                    label: const Text('時刻追加'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                onPressed: _openingTimetable ? null : () => _openTimetableEditor(routeDoc),
                                icon: const Icon(Icons.edit_calendar_outlined),
                                label: const Text('ダイヤをまとめて編集'),
                              ),
                              ..._buildTimeEntries(routeDoc),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScheduleManagement() => StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('bus_information').doc('main')
        .collection('bus_routes').orderBy('sortOrder').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) return _buildErrorWidget('時刻表を読み込めませんでした');
      final routes = (snapshot.data?.docs ?? []).where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final query = _scheduleSearch.toLowerCase();
        return query.isEmpty || ['name', 'fromStation', 'toStation'].any(
          (key) => (data[key] as String? ?? '').toLowerCase().contains(query),
        );
      }).toList();
      return CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('路線の「ダイヤを編集」から、貼り付け・等間隔作成・コピーでまとめて登録できます。'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _scheduleSearchCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: '路線名・区間で検索',
                      border: const OutlineInputBorder(),
                      suffixIcon: _scheduleSearch.isEmpty ? null : IconButton(
                        tooltip: '検索をクリア',
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          _scheduleSearchCtrl.clear();
                          _scheduleSearch = '';
                        }),
                      ),
                    ),
                    onChanged: (value) => setState(() => _scheduleSearch = value.trim()),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final day in busDayLabels.entries)
                        ChoiceChip(
                          label: Text(day.value),
                          selected: _scheduleDayType == day.key,
                          onSelected: (_) => setState(() => _scheduleDayType = day.key),
                        ),
                      FilterChip(
                        selected: _scheduleHideInactive,
                        label: const Text('運休を隠す'),
                        onSelected: (value) => setState(() => _scheduleHideInactive = value),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (routes.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('該当する路線がありません。新規路線は「路線管理」の＋から追加できます。'),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildTimetableCard(routes[index]),
                childCount: routes.length,
              ),
            ),
          ),
        ],
      );
    },
  );

  Future<void> _openTimetableEditor(QueryDocumentSnapshot routeDoc, {String? dayType}) async {
    if (_openingTimetable) return;
    setState(() => _openingTimetable = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bus_information').doc('main').collection('bus_routes')
          .orderBy('sortOrder').get();
      final sources = snapshot.docs.map((doc) => BusTimetableRoute(
        id: doc.id,
        name: doc.data()['name'] as String? ?? '名称未設定',
        entries: copyBusDepartures(
          List<BusDepartureData>.from(doc.data()['timeEntries'] as List? ?? []),
        ),
      )).toList();
      final route = sources.firstWhere((item) => item.id == routeDoc.id);
      validateBusDepartures(route.entries);
      if (!mounted) return;
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => BusTimetableEditorScreen(
          route: route,
          sources: sources,
          initialDayType: dayType ?? _scheduleDayType,
          onSave: (updated) => _saveTimetable(route.id, route.entries, updated),
        )),
      );
      if (saved == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ダイヤを保存しました')),
        );
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error is FormatException
            ? error.message
            : 'ダイヤを読み込めませんでした。再読み込みしてお試しください。')),
      );
    } finally {
      if (mounted) setState(() => _openingTimetable = false);
    }
  }

  Future<void> _saveTimetable(
    String routeId, List<BusDepartureData> original, List<BusDepartureData> updated,
  ) async {
    await BusTimetableAdminService(FirebaseFirestore.instance).save(
      routeId: routeId,
      original: original,
      updated: updated,
      updatedBy: FirebaseAuth.instance.currentUser?.uid ?? '',
    );
    if (mounted) {
      ref.invalidate(busInformationProvider);
      ref.invalidate(busInformationStreamProvider);
    }
  }

  Future<void> _openHomeRemarkEditorFromAppBar() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('bus_information')
              .doc('main')
              .get();
      final data = doc.data() ?? <String, dynamic>{};
      final remark = (data['description'] as String?)?.trim() ?? '';
      if (!mounted) return;
      _showEditHomeRemarkDialog(remark);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('備考の読み込みに失敗しました: $e')));
    }
  }

  Future<void> _openLecturePeriodEditorFromAppBar() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month),
                      const SizedBox(width: 8),
                      Text(
                        '講義期間設定',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildLecturePeriodEditor(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimetableCard(QueryDocumentSnapshot routeDoc) {
    final route = routeDoc.data() as Map<String, dynamic>;
    final raw = List<BusDepartureData>.from(route['timeEntries'] as List? ?? []);
    final entries = raw.asMap().entries.where((item) =>
        busDepartureDay(item.value) == _scheduleDayType &&
        (!_scheduleHideInactive || item.value['isActive'] != false)).toList()
      ..sort((a, b) => busDepartureMinute(a.value).compareTo(busDepartureMinute(b.value)));
    final byHour = <int, List<MapEntry<int, BusDepartureData>>>{};
    for (final item in entries) {
      (byHour[item.value['hour'] as int] ??= []).add(item);
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(route['name'] as String? ?? '名称未設定',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${busDayLabels[_scheduleDayType]}・${entries.length}便'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                FilledButton.icon(
                  onPressed: _openingTimetable ? null : () => _openTimetableEditor(routeDoc),
                  icon: const Icon(Icons.edit_calendar_outlined),
                  label: const Text('ダイヤを編集'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showTimeEntryDialog(
                    routeDoc: routeDoc,
                    initial: {'dayType': _scheduleDayType, 'isActive': true},
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('1便追加'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty) const Text('この曜日には表示できる便がありません'),
            for (final group in byHour.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10, right: 12),
                      child: Text('${group.key}時',
                          style: Theme.of(context).textTheme.titleSmall),
                    ),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final item in group.value)
                            Tooltip(
                              message: item.value['note'] as String? ?? 'タップして編集',
                              child: ActionChip(
                                label: Text(
                                  '${(item.value['minute'] as int).toString().padLeft(2, '0')}'
                                  '${item.value['isActive'] == false ? ' 運休' : ''}',
                                ),
                                onPressed: () => _showTimeEntryDialog(
                                  routeDoc: routeDoc,
                                  index: item.key,
                                  initial: item.value,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildOperationStatus() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                       Icon(Icons.info, color: AppColors.accent(context, Colors.orange)),
                      const SizedBox(width: 8),
                      const Text(
                        '運行状況管理',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add_alert),
                        onPressed: _addOperationNotice,
                        tooltip: '運行情報追加',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('運行状況の変更、遅延情報、運休情報などを管理できます。'),
                  const SizedBox(height: 12),
                  _buildHomeRemarkEditor(),
                  const SizedBox(height: 12),
                  _buildLecturePeriodEditor(),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('bus_information')
                    .doc('main')
                    .collection('operation_status')
                    .orderBy('createdAt', descending: true)
                    .limit(50)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _buildErrorWidget(
                  '運行状況データの読み込みに失敗しました: ${snapshot.error}',
                );
              }
              final statuses = snapshot.data?.docs ?? [];
              if (statuses.isEmpty) {
                return _buildEmptyWidget(
                  Icons.directions_bus,
                  '運行状況情報がありません',
                  '運行情報を追加してください',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: statuses.length,
                itemBuilder: (context, index) {
                  final statusDoc = statuses[index];
                  final statusData = statusDoc.data() as Map<String, dynamic>;
                  final type = statusData['type'] ?? 'info';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        _getStatusIcon(type),
                        color: _getStatusColor(type),
                      ),
                      title: Text(
                        statusData['title'] ?? '運行情報',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(statusData['message'] ?? ''),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDateTime(
                                  (statusData['createdAt'] is Timestamp)
                                      ? (statusData['createdAt'] as Timestamp)
                                          .toDate()
                                      : DateTime.now(),
                                ),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              _buildStatusTypeChip(type),
                            ],
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected:
                            (action) =>
                                _handleOperationStatusAction(action, statusDoc),
                        itemBuilder:
                            (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('編集'),
                              ),
                              PopupMenuItem(
                                value:
                                    statusData['isActive'] == true
                                        ? 'deactivate'
                                        : 'activate',
                                child: Text(
                                  statusData['isActive'] == true ? '非表示' : '表示',
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('削除'),
                              ),
                            ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRouteDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildHomeRemarkEditor() {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('bus_information')
              .doc('main')
              .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final remark = (data['description'] as String?)?.trim() ?? '';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_note, size: 18),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'ホーム表示の備考',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showEditHomeRemarkDialog(remark),
                    child: const Text('編集'),
                  ),
                ],
              ),
              Text(
                remark.isEmpty ? '未設定（ホームには表示されません）' : remark,
                style: TextStyle(
                  color: remark.isEmpty ? Theme.of(context).colorScheme.onSurfaceVariant : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLecturePeriodEditor() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance
              .doc('app_settings/lecture_period')
              .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        if (data != null &&
            _springStartDate == null &&
            _springEndDate == null &&
            _fallStartDate == null &&
            _fallEndDate == null) {
          _springStartDate =
              (data['springStartDate'] as Timestamp?)?.toDate() ??
              (data['lectureStartDate'] as Timestamp?)?.toDate();
          _springEndDate =
              (data['springEndDate'] as Timestamp?)?.toDate() ??
              (data['lectureEndDate'] as Timestamp?)?.toDate();
          _fallStartDate = (data['fallStartDate'] as Timestamp?)?.toDate();
          _fallEndDate = (data['fallEndDate'] as Timestamp?)?.toDate();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.calendar_month, size: 18),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '講義期間設定（前期・後期）',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildLecturePeriodRow(
                label: '前期',
                start: _springStartDate,
                end: _springEndDate,
                onEdit: () => _showLecturePeriodDialog(isSpring: true),
              ),
              const SizedBox(height: 6),
              _buildLecturePeriodRow(
                label: '後期',
                start: _fallStartDate,
                end: _fallEndDate,
                onEdit: () => _showLecturePeriodDialog(isSpring: false),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSavingLecturePeriod ? null : _saveLecturePeriod,
                  icon:
                      _isSavingLecturePeriod
                          ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.save),
                  label: Text(_isSavingLecturePeriod ? '保存中...' : '講義期間を保存'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLecturePeriodRow({
    required String label,
    required DateTime? start,
    required DateTime? end,
    required VoidCallback onEdit,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label: ${_formatDateRange(start, end)}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ),
        TextButton(onPressed: onEdit, child: const Text('編集')),
      ],
    );
  }

  Future<void> _showLecturePeriodDialog({required bool isSpring}) async {
    DateTime? localStart = isSpring ? _springStartDate : _fallStartDate;
    DateTime? localEnd = isSpring ? _springEndDate : _fallEndDate;
    final now = DateTime.now();

    await showDialog<void>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => AlertDialog(
                  title: Text('${isSpring ? '前期' : '後期'}の講義期間を編集'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: Text(
                          '開始日: ${localStart != null ? _formatDate(localStart!) : '未設定'}',
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: localStart ?? now,
                            firstDate: DateTime(now.year - 2, 1, 1),
                            lastDate: DateTime(now.year + 3, 12, 31),
                          );
                          if (picked == null) return;
                          setDialogState(() {
                            localStart = picked;
                            if (localEnd != null &&
                                localEnd!.isBefore(localStart!)) {
                              localEnd = localStart;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.stop),
                        label: Text(
                          '終了日: ${localEnd != null ? _formatDate(localEnd!) : '未設定'}',
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: localEnd ?? (localStart ?? now),
                            firstDate: DateTime(now.year - 2, 1, 1),
                            lastDate: DateTime(now.year + 3, 12, 31),
                          );
                          if (picked == null) return;
                          setDialogState(() => localEnd = picked);
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDateRange(localStart, localEnd),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('キャンセル'),
                    ),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          if (isSpring) {
                            _springStartDate = localStart;
                            _springEndDate = localEnd;
                          } else {
                            _fallStartDate = localStart;
                            _fallEndDate = localEnd;
                          }
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('反映'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _saveLecturePeriod() async {
    final hasOnlySpringOne =
        (_springStartDate == null) != (_springEndDate == null);
    final hasOnlyFallOne = (_fallStartDate == null) != (_fallEndDate == null);
    if (hasOnlySpringOne || hasOnlyFallOne) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('各学期は開始日と終了日をセットで設定してください')));
      return;
    }
    if (_springStartDate != null &&
        _springEndDate != null &&
        _springStartDate!.isAfter(_springEndDate!)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('前期の終了日は開始日以降にしてください')));
      return;
    }
    if (_fallStartDate != null &&
        _fallEndDate != null &&
        _fallStartDate!.isAfter(_fallEndDate!)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('後期の終了日は開始日以降にしてください')));
      return;
    }

    setState(() => _isSavingLecturePeriod = true);
    try {
      await LecturePeriodService.updateLecturePeriod(
        springStartDate: _springStartDate,
        springEndDate: _springEndDate,
        fallStartDate: _fallStartDate,
        fallEndDate: _fallEndDate,
        updatedBy: FirebaseAuth.instance.currentUser?.uid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('講義期間を保存しました')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('講義期間の保存に失敗しました: $e')));
    } finally {
      if (mounted) setState(() => _isSavingLecturePeriod = false);
    }
  }

  void _showEditHomeRemarkDialog(String currentRemark) {
    final controller = TextEditingController(text: currentRemark);
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('ホーム表示の備考を編集'),
            content: TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '備考（ホーム表示）',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  await FirebaseFirestore.instance
                      .collection('bus_information')
                      .doc('main')
                      .set({
                        'description': controller.text.trim(),
                        'updatedAt': FieldValue.serverTimestamp(),
                        'updatedBy': user?.displayName ?? user?.email ?? '管理者',
                      }, SetOptions(merge: true));
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('備考を保存しました')));
                  }
                },
                child: const Text('保存'),
              ),
            ],
          ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'active':
        color = Colors.green;
        label = '運行中';
        break;
      case 'suspended':
        color = Colors.red;
        label = '運行停止';
        break;
      case 'maintenance':
        color = Colors.orange;
        label = 'メンテナンス';
        break;
      default:
        color = Colors.grey;
        label = '不明';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _getDarkerShade(color),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusTypeChip(String type) {
    Color color;
    String label;

    switch (type) {
      case 'delay':
        color = Colors.orange;
        label = '遅延';
        break;
      case 'cancellation':
        color = Colors.red;
        label = '運休';
        break;
      case 'maintenance':
        color = Colors.blue;
        label = 'メンテナンス';
        break;
      case 'info':
      default:
        color = Colors.green;
        label = 'お知らせ';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _getDarkerShade(color),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           Icon(Icons.error_outline, size: 64, color: AppColors.accent(context, Colors.red)),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _refreshData, child: const Text('再試行')),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      final hexColor = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  String _normalizeHexColor(String? input) {
    final raw = (input ?? '').trim().toUpperCase();
    if (raw.isEmpty) return '#2196F3';
    final normalized = raw.startsWith('#') ? raw : '#$raw';
    final valid = RegExp(r'^#[0-9A-F]{6}$').hasMatch(normalized);
    return valid ? normalized : '#2196F3';
  }

  Color _getStatusColor(String type) {
    switch (type) {
      case 'delay':
        return Colors.orange;
      case 'cancellation':
        return Colors.red;
      case 'maintenance':
        return Colors.blue;
      case 'info':
      default:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(String type) {
    switch (type) {
      case 'delay':
        return Icons.access_time;
      case 'cancellation':
        return Icons.cancel;
      case 'maintenance':
        return Icons.build;
      case 'info':
      default:
        return Icons.info;
    }
  }

  String _formatOperatingDays(dynamic operatingDays) {
    if (operatingDays is List) {
      if (operatingDays.length == 7) {
        return '毎日';
      } else if (operatingDays.length == 5 &&
          !operatingDays.contains(0) &&
          !operatingDays.contains(6)) {
        return '平日のみ';
      } else {
        final dayNames = ['日', '月', '火', '水', '木', '金', '土'];
        return operatingDays.map((day) => dayNames[day]).join('・');
      }
    }
    return '不明';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateRange(dynamic start, dynamic end) {
    DateTime? s;
    DateTime? e;
    if (start is Timestamp) s = start.toDate();
    if (start is DateTime) s = start;
    if (end is Timestamp) e = end.toDate();
    if (end is DateTime) e = end;

    if (s == null && e == null) return '未設定';
    if (s != null && e == null) return '${_formatDate(s)} 〜';
    if (s == null && e != null) return '〜 ${_formatDate(e)}';
    return '${_formatDate(s!)} 〜 ${_formatDate(e!)}';
  }

  Future<void> _refreshData() async {
    setState(() {});
  }

  void _reorderRoutes(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    // Fetch routes and update sortOrder
    FirebaseFirestore.instance
        .collection('bus_information')
        .doc('main')
        .collection('bus_routes')
        .orderBy('sortOrder')
        .get()
        .then((snapshot) async {
          final docs = snapshot.docs;
          if (oldIndex < 0 ||
              oldIndex >= docs.length ||
              newIndex < 0 ||
              newIndex >= docs.length)
            return;
          final moved = docs.removeAt(oldIndex);
          docs.insert(newIndex, moved);
          final batch = FirebaseFirestore.instance.batch();
          for (int i = 0; i < docs.length; i++) {
            batch.update(docs[i].reference, {
              'sortOrder': i,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          await batch.commit();
        });
  }

  void _addBusRoute() {
    _showRouteDialog();
  }

  void _addOperationNotice() {
    _showOperationStatusDialog();
  }

  void _handleRouteAction(String action, QueryDocumentSnapshot routeDoc) {
    switch (action) {
      case 'edit':
        _showRouteDialog(routeDoc: routeDoc);
        break;
      case 'duplicate':
        _duplicateRoute(routeDoc);
        break;
      case 'suspend':
        _updateRouteStatus(routeDoc, 'suspended');
        break;
      case 'activate':
        _updateRouteStatus(routeDoc, 'active');
        break;
      case 'delete':
        _deleteRoute(routeDoc);
        break;
    }
  }

  void _handleOperationStatusAction(
    String action,
    QueryDocumentSnapshot statusDoc,
  ) {
    switch (action) {
      case 'edit':
        _showOperationStatusDialog(statusDoc: statusDoc);
        break;
      case 'activate':
        _updateOperationStatusVisibility(statusDoc, true);
        break;
      case 'deactivate':
        _updateOperationStatusVisibility(statusDoc, false);
        break;
      case 'delete':
        _deleteOperationStatus(statusDoc);
        break;
    }
  }

  void _showRouteDialog({QueryDocumentSnapshot? routeDoc}) {
    final isEdit = routeDoc != null;
    final data = (routeDoc?.data() as Map<String, dynamic>?) ?? {};
    const presetColors = [
      '#2196F3',
      '#4CAF50',
      '#FF9800',
      '#9C27B0',
      '#E91E63',
      '#607D8B',
      '#F44336',
      '#009688',
    ];
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final fromCtrl = TextEditingController(text: data['fromStation'] ?? '');
    final toCtrl = TextEditingController(text: data['toStation'] ?? '');
    final colorCtrl = TextEditingController(
      text: _normalizeHexColor(data['color'] as String?),
    );
    bool isActive = data['isActive'] ?? true;
    DateTime? startDate =
        (data['startDate'] is Timestamp)
            ? (data['startDate'] as Timestamp).toDate()
            : null;
    DateTime? endDate =
        (data['endDate'] is Timestamp)
            ? (data['endDate'] as Timestamp).toDate()
            : null;
    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setStateDialog) => AlertDialog(
                  title: Text(isEdit ? '路線を編集' : '路線を追加'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: '路線名'),
                        ),
                        TextField(
                          controller: fromCtrl,
                          decoration: const InputDecoration(labelText: '出発'),
                        ),
                        TextField(
                          controller: toCtrl,
                          decoration: const InputDecoration(labelText: '到着'),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: colorCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'カード色 (HEX)',
                            hintText: '#2196F3',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(10),
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: _parseColor(
                                  _normalizeHexColor(colorCtrl.text),
                                ),
                              ),
                            ),
                            suffixIcon: IconButton(
                              tooltip: 'デフォルト色に戻す',
                              onPressed: () {
                                setStateDialog(() {
                                  colorCtrl.text = '#2196F3';
                                });
                              },
                              icon: const Icon(Icons.refresh),
                            ),
                            helperText: '#RRGGBB 形式で入力',
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => setStateDialog(() {}),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              presetColors.map((hex) {
                                final selected =
                                    _normalizeHexColor(colorCtrl.text) == hex;
                                return ChoiceChip(
                                  label: Text(
                                    hex,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  selected: selected,
                                  avatar: CircleAvatar(
                                    radius: 8,
                                    backgroundColor: _parseColor(hex),
                                  ),
                                  onSelected: (_) {
                                    setStateDialog(() {
                                      colorCtrl.text = hex;
                                    });
                                  },
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.event),
                                label: Text(
                                  startDate != null
                                      ? _formatDate(startDate!)
                                      : '開始日 未設定',
                                ),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: startDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setStateDialog(() {
                                      startDate = picked;
                                      if (endDate != null &&
                                          endDate!.isBefore(startDate!)) {
                                        endDate = startDate;
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.event),
                                label: Text(
                                  endDate != null
                                      ? _formatDate(endDate!)
                                      : '終了日 未設定',
                                ),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        endDate ??
                                        (startDate ?? DateTime.now()),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setStateDialog(() {
                                      endDate = picked;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _formatDateRange(startDate, endDate),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        SwitchListTile(
                          value: isActive,
                          onChanged: (v) => setStateDialog(() => isActive = v),
                          title: const Text('有効'),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('キャンセル'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        final col = FirebaseFirestore.instance
                            .collection('bus_information')
                            .doc('main')
                            .collection('bus_routes');
                        final payload = {
                          'name': nameCtrl.text.trim(),
                          'fromStation': fromCtrl.text.trim(),
                          'toStation': toCtrl.text.trim(),
                          'color': _normalizeHexColor(colorCtrl.text),
                          'isActive': isActive,
                          'startDate':
                              startDate != null
                                  ? Timestamp.fromDate(startDate!)
                                  : null,
                          'endDate':
                              endDate != null
                                  ? Timestamp.fromDate(endDate!)
                                  : null,
                          'updatedAt': FieldValue.serverTimestamp(),
                        }..removeWhere(
                          (k, v) =>
                              v == null && (k == 'startDate' || k == 'endDate'),
                        );

                        if (isEdit) {
                          await routeDoc.reference.update(payload);
                        } else {
                          final current = await col.orderBy('sortOrder').get();
                          final sortOrder = current.docs.length;
                          await col.add({
                            ...payload,
                            'sortOrder': sortOrder,
                            'timeEntries': [],
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                        }
                        if (context.mounted) Navigator.pop(ctx);
                      },
                      child: Text(isEdit ? '更新' : '追加'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showOperationStatusDialog({QueryDocumentSnapshot? statusDoc}) {
    final isEdit = statusDoc != null;
    final data = (statusDoc?.data() as Map<String, dynamic>?) ?? {};
    final titleCtrl = TextEditingController(text: data['title'] ?? '');
    final msgCtrl = TextEditingController(text: data['message'] ?? '');
    String type = data['type'] ?? 'info';
    bool isActive = data['isActive'] ?? true;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(isEdit ? '運行情報を編集' : '運行情報を追加'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'タイトル'),
                  ),
                  TextField(
                    controller: msgCtrl,
                    decoration: const InputDecoration(labelText: 'メッセージ'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    items: const [
                      DropdownMenuItem(value: 'info', child: Text('通常')),
                      DropdownMenuItem(value: 'delay', child: Text('遅延')),
                      DropdownMenuItem(value: 'suspend', child: Text('運休')),
                    ],
                    onChanged: (v) => type = v ?? 'info',
                    decoration: const InputDecoration(labelText: '種別'),
                  ),
                  SwitchListTile(
                    value: isActive,
                    onChanged: (v) => isActive = v,
                    title: const Text('表示する'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () async {
                  final col = FirebaseFirestore.instance
                      .collection('bus_information')
                      .doc('main')
                      .collection('operation_status');
                  final payload = {
                    'title': titleCtrl.text.trim(),
                    'message': msgCtrl.text.trim(),
                    'type': type,
                    'isActive': isActive,
                    'updatedAt': FieldValue.serverTimestamp(),
                  };
                  if (isEdit) {
                    await statusDoc.reference.update(payload);
                  } else {
                    await col.add({
                      ...payload,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                  }
                  if (context.mounted) Navigator.pop(ctx);
                },
                child: Text(isEdit ? '更新' : '追加'),
              ),
            ],
          ),
    );
  }

  Future<void> _duplicateRoute(QueryDocumentSnapshot routeDoc) async {
    try {
      final data = routeDoc.data() as Map<String, dynamic>;
      final col = FirebaseFirestore.instance
          .collection('bus_information')
          .doc('main')
          .collection('bus_routes');
      final current = await col.orderBy('sortOrder').get();
      final sortOrder = current.docs.length;
      await col.add({
        ...data,
        'name': '${data['name']} (コピー)',
        'sortOrder': sortOrder,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('路線を複製しました')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('複製に失敗しました: $e')));
    }
  }

  Future<void> _updateRouteStatus(
    QueryDocumentSnapshot routeDoc,
    String status,
  ) async {
    try {
      await routeDoc.reference.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('路線を${status == 'active' ? '運行開始' : '運行停止'}しました'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('更新に失敗しました: $e')));
    }
  }

  Future<void> _deleteRoute(QueryDocumentSnapshot routeDoc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('路線削除'),
            content: const Text('この路線を削除しますか？関連する時刻表も削除されます。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(foregroundColor: AppColors.onColor(Colors.red), backgroundColor: Colors.red),
                child: const Text('削除'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await routeDoc.reference.delete();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('路線を削除しました')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('削除に失敗しました: $e')));
      }
    }
  }

  Future<void> _updateOperationStatusVisibility(
    QueryDocumentSnapshot statusDoc,
    bool isActive,
  ) async {
    try {
      await statusDoc.reference.update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('運行状況を${isActive ? '表示' : '非表示'}にしました')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('更新に失敗しました: $e')));
    }
  }

  Future<void> _deleteOperationStatus(QueryDocumentSnapshot statusDoc) async {
    try {
      await statusDoc.reference.delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('運行状況を削除しました')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('削除に失敗しました: $e')));
    }
  }

  String _labelForDayType(String v) {
    switch (v) {
      case 'saturday':
        return '土曜ダイヤ';
      case 'sunday':
        return '日曜ダイヤ';
      case 'weekday':
      default:
        return '平日ダイヤ';
    }
  }

  Color _getDarkerShade(Color color) {
    // Create a darker shade of the color (similar to shade700)
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.4).clamp(0.0, 1.0)).toColor();
  }

  List<Widget> _buildTimeEntries(QueryDocumentSnapshot routeDoc) {
    final routeData = routeDoc.data() as Map<String, dynamic>;
    final entries =
        (routeData['timeEntries'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList()
            .asMap().entries.toList()
          ..sort((a, b) {
            final ah = (a.value['hour'] as int?) ?? 0;
            final am = (a.value['minute'] as int?) ?? 0;
            final bh = (b.value['hour'] as int?) ?? 0;
            final bm = (b.value['minute'] as int?) ?? 0;
            return (ah * 60 + am).compareTo(bh * 60 + bm);
          });

    if (entries.isEmpty) {
      return [const Text('時刻が登録されていません')];
    }

    return entries.map((e) {
      final idx = e.key;
      final m = e.value;
      final hh = (m['hour'] as int?) ?? 0;
      final mm = (m['minute'] as int?) ?? 0;
      final note = m['note'] as String?;
      final isActive = m['isActive'] as bool? ?? true;
      final dayType = (m['dayType'] as String?) ?? 'weekday';
      final timeStr =
          '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
      return ListTile(
        dense: true,
        leading: Icon(
          isActive ? Icons.schedule : Icons.schedule_outlined,
          color: isActive ? Colors.blue : Colors.grey,
        ),
        title: Text(timeStr),
        subtitle: Text(
          [
            _labelForDayType(dayType),
            if (note != null && note.isNotEmpty) note,
          ].join(' | '),
        ),
        trailing: PopupMenuButton<String>(
          onSelected:
              (action) => _handleTimeEntryAction(action, routeDoc, idx, m),
          itemBuilder:
              (context) => [
                const PopupMenuItem(value: 'edit', child: Text('編集')),
                PopupMenuItem(
                  value: isActive ? 'deactivate' : 'activate',
                  child: Text(isActive ? '無効化' : '有効化'),
                ),
                const PopupMenuItem(value: 'delete', child: Text('削除')),
              ],
        ),
      );
    }).toList();
  }

  void _handleTimeEntryAction(
    String action,
    QueryDocumentSnapshot routeDoc,
    int index,
    Map<String, dynamic> entry,
  ) async {
    switch (action) {
      case 'edit':
        _showTimeEntryDialog(routeDoc: routeDoc, index: index, initial: entry);
        break;
      case 'deactivate':
        await _updateTimeEntryActive(routeDoc, index, false);
        break;
      case 'activate':
        await _updateTimeEntryActive(routeDoc, index, true);
        break;
      case 'delete':
        await _deleteTimeEntry(routeDoc, index);
        break;
    }
  }

  Future<void> _updateTimeEntryActive(
    QueryDocumentSnapshot routeDoc, int index, bool isActive,
  ) async {
    try {
      final data = routeDoc.data() as Map<String, dynamic>;
      final original = List<BusDepartureData>.from(data['timeEntries'] as List? ?? []);
      if (index < 0 || index >= original.length) return;
      final updated = copyBusDepartures(original);
      updated[index]['isActive'] = isActive;
      await _saveTimetable(routeDoc.id, original, updated);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(busTimetableSaveError(error))),
      );
    }
  }

  Future<void> _deleteTimeEntry(QueryDocumentSnapshot routeDoc, int index) async {
    final data = routeDoc.data() as Map<String, dynamic>;
    final original = List<BusDepartureData>.from(data['timeEntries'] as List? ?? []);
    if (index < 0 || index >= original.length) return;
    final entry = original[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('この便を削除しますか？'),
        content: Text('${busDayLabels[busDepartureDay(entry)]} ${formatBusMinute(busDepartureMinute(entry))} 発'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('削除')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final updated = copyBusDepartures(original)..removeAt(index);
      await _saveTimetable(routeDoc.id, original, updated);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('時刻を削除しました')),
      );
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(busTimetableSaveError(error))),
      );
    }
  }

  void _showTimeEntryDialog({
    required QueryDocumentSnapshot routeDoc,
    int? index,
    Map<String, dynamic>? initial,
  }) {
    final data = routeDoc.data() as Map<String, dynamic>;
    final original = List<BusDepartureData>.from(data['timeEntries'] as List? ?? []);
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BusDepartureDialog(
        entry: index == null ? null : initial,
        dayType: initial?['dayType'] as String? ?? _scheduleDayType,
        onSave: (entry) async {
          if (original.asMap().entries.any((item) =>
              item.key != index &&
              busDepartureDay(item.value) == busDepartureDay(entry) &&
              busDepartureMinute(item.value) == busDepartureMinute(entry))) {
            throw const FormatException('同じ曜日・時刻の便が既にあります。');
          }
          final updated = copyBusDepartures(original);
          if (index == null) {
            updated.add(entry);
          } else {
            if (index < 0 || index >= updated.length) {
              throw const FormatException('対象の便がありません。画面を開き直してください。');
            }
            updated[index] = entry;
          }
          await _saveTimetable(routeDoc.id, original, updated);
        },
      ),
    );
  }
}


/// 文字列の先頭1文字を絵文字/合字に対応した安全な方法で取り出す。
/// 不正な lone surrogate を返さないよう characters パッケージを使用する。
String _firstCharacterOrFallback(dynamic value, String fallback) {
  if (value is String && value.characters.isNotEmpty) {
    return value.characters.first;
  }
  return fallback;
}
