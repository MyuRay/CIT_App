import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusAdminScreen extends ConsumerStatefulWidget {
  const BusAdminScreen({super.key});

  @override
  ConsumerState<BusAdminScreen> createState() => _BusAdminScreenState();
}

class _BusAdminScreenState extends ConsumerState<BusAdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _routeSearchCtrl = TextEditingController();
  String _routeSearch = '';
  String _routeStatusFilter = 'all'; // all, active, suspended
  // 時刻表タブ用の状態
  final TextEditingController _scheduleSearchCtrl = TextEditingController();
  String _scheduleSearch = '';
  String _scheduleDayType = 'weekday'; // weekday, saturday, sunday
  bool _scheduleHideInactive = true;

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
      stream: FirebaseFirestore.instance
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
            border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    suffixIcon: _routeSearch.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () { setState((){ _routeSearchCtrl.clear(); _routeSearch = ''; }); })
                        : null,
                  ),
                  onChanged: (v) => setState(() { _routeSearch = v.trim(); }),
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
                onChanged: (v) => setState((){ _routeStatusFilter = v ?? 'all'; }),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _showBulkAddRoutesDialog,
                icon: const Icon(Icons.playlist_add),
                label: const Text('一括追加'),
              ),
            ],
          ),
        );

        if (routes.isEmpty) {
          return Column(children: [
            header,
            Expanded(child: _buildEmptyWidget(Icons.route, '路線が登録されていません', '「＋」または「一括追加」から登録してください'))
          ]);
        }

        // フィルタリング
        if (_routeSearch.isNotEmpty) {
          final q = _routeSearch.toLowerCase();
          routes = routes.where((d){
            final m = d.data() as Map<String, dynamic>;
            final name = (m['name'] as String? ?? '').toLowerCase();
            final from = (m['fromStation'] as String? ?? '').toLowerCase();
            final to = (m['toStation'] as String? ?? '').toLowerCase();
            return name.contains(q) || from.contains(q) || to.contains(q);
          }).toList();
        }
        if (_routeStatusFilter != 'all') {
          routes = routes.where((d){
            final m = d.data() as Map<String, dynamic>;
            final status = (m['status'] as String?) ?? (m['isActive'] == true ? 'active' : 'suspended');
            return status == _routeStatusFilter;
          }).toList();
        }
        return Column(children: [
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
                          backgroundColor: _parseColor(routeData['color'] ?? '#2196F3'),
                          child: Text(
                            routeData['shortName'] ?? (routeData['name']?.substring(0, 1) ?? 'B'),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                        Text('${routeData['fromStation']} → ${routeData['toStation']}'),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStatusChip(routeData['status'] ?? 'active'),
                            const SizedBox(width: 8),
                            Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${routeData['operatingDays']?.length ?? 0}日間運行',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: (routeData['isActive'] as bool?) ?? (routeData['status'] != 'suspended'),
                          onChanged: (v) {
                            if (routeData.containsKey('isActive')) {
                              routeDoc.reference.update({'isActive': v, 'updatedAt': FieldValue.serverTimestamp()});
                            }
                            final next = v ? 'active' : 'suspended';
                            routeDoc.reference.update({'status': next, 'updatedAt': FieldValue.serverTimestamp()});
                          },
                        ),
                        PopupMenuButton<String>(
                          onSelected: (action) => _handleRouteAction(action, routeDoc),
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('編集')),
                            PopupMenuItem(value: 'duplicate', child: Text('複製')),
                          ],
                        ),
                        PopupMenuButton<String>(
                          onSelected: (action) => _handleRouteAction(action, routeDoc),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: (routeData['status'] == 'active') ? 'suspend' : 'activate',
                              child: Text(routeData['status'] == 'active' ? '運行停止' : '運行開始'),
                            ),
                            const PopupMenuItem(value: 'delete', child: Text('削除')),
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
                            _buildRouteDetailRow('運行区間', '${routeData['fromStation']} → ${routeData['toStation']}'),
                            _buildRouteDetailRow('運行日', _formatOperatingDays(routeData['operatingDays'])),
                            _buildRouteDetailRow('運行期間', _formatDateRange(routeData['startDate'], routeData['endDate'])),
                            _buildRouteDetailRow('所要時間', '約${routeData['duration'] ?? '?'}分'),
                            _buildRouteDetailRow('運賃', routeData['fare'] != null ? '￥${routeData['fare']}' : '無料'),
                            if (routeData['note'] != null && (routeData['note'] as String).isNotEmpty)
                              _buildRouteDetailRow('備考', routeData['note']),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.schedule, size: 18),
                                const SizedBox(width: 6),
                                const Text('時刻一覧', style: TextStyle(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: () => _showTimeEntryDialog(routeDoc: routeDoc),
                                  icon: const Icon(Icons.add),
                                  label: const Text('時刻追加'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
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
        ]);
      },
    );
  }

  Widget _buildScheduleManagement() {
    // ヘッダー（検索・フィルタ）
    final header = Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          // 検索
          Expanded(
            child: TextField(
              controller: _scheduleSearchCtrl,
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                hintText: '路線名・区間で検索',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: _scheduleSearch.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _scheduleSearchCtrl.clear();
                            _scheduleSearch = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _scheduleSearch = v.trim()),
            ),
          ),
          const SizedBox(width: 8),
          // ダイヤ種別
          DropdownButton<String>(
            value: _scheduleDayType,
            items: const [
              DropdownMenuItem(value: 'weekday', child: Text('平日')),
              DropdownMenuItem(value: 'saturday', child: Text('土曜')),
              DropdownMenuItem(value: 'sunday', child: Text('日曜')),
            ],
            onChanged: (v) => setState(() => _scheduleDayType = v ?? 'weekday'),
          ),
          const SizedBox(width: 8),
          // 無効時刻を隠す
          FilterChip(
            selected: _scheduleHideInactive,
            onSelected: (v) => setState(() => _scheduleHideInactive = v),
            avatar: Icon(
              _scheduleHideInactive ? Icons.visibility_off : Icons.visibility,
              size: 18,
            ),
            label: const Text('無効を非表示'),
          ),
        ],
      ),
    );

    return Column(
      children: [
        header,
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
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
                return _buildErrorWidget('時刻表データの読み込みに失敗しました: ${snapshot.error}');
              }
              var routes = snapshot.data?.docs ?? [];
              // 検索フィルタ
              if (_scheduleSearch.isNotEmpty) {
                final q = _scheduleSearch.toLowerCase();
                routes = routes.where((d) {
                  final m = d.data() as Map<String, dynamic>;
                  final name = (m['name'] as String? ?? '').toLowerCase();
                  final from = (m['fromStation'] as String? ?? '').toLowerCase();
                  final to = (m['toStation'] as String? ?? '').toLowerCase();
                  return name.contains(q) || from.contains(q) || to.contains(q);
                }).toList();
              }

              if (routes.isEmpty) {
                return _buildEmptyWidget(
                  Icons.schedule,
                  '時刻表を表示できる路線がありません',
                  '路線を追加し、路線詳細から時刻を登録してください',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: routes.length,
                itemBuilder: (context, index) {
                  final routeDoc = routes[index];
                  return _buildTimetableCard(routeDoc);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimetableCard(QueryDocumentSnapshot routeDoc) {
    final route = routeDoc.data() as Map<String, dynamic>;
    // 対象ダイヤの時刻を抽出
    final entries = (route['timeEntries'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .where((e) => (e['dayType'] ?? 'weekday') == _scheduleDayType)
        .where((e) => _scheduleHideInactive ? (e['isActive'] ?? true) == true : true)
        .toList()
      ..sort((a, b) {
        final ah = (a['hour'] as int?) ?? 0;
        final am = (a['minute'] as int?) ?? 0;
        final bh = (b['hour'] as int?) ?? 0;
        final bm = (b['minute'] as int?) ?? 0;
        return (ah * 60 + am).compareTo(bh * 60 + bm);
      });

    // 時毎にグルーピング
    final Map<int, List<Map<String, dynamic>>> byHour = {};
    for (final e in entries) {
      final h = (e['hour'] as int?) ?? 0;
      (byHour[h] ??= []).add(e);
    }
    final hours = byHour.keys.toList()..sort();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー行
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: _parseColor(route['color'] ?? '#2196F3'),
                  child: Text(
                    (
                      route['shortName'] ??
                      ((route['name'] is String && (route['name'] as String).isNotEmpty)
                          ? (route['name'] as String).substring(0, 1)
                          : 'B')
                    ).toString(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route['name'] ?? '無名路線',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${route['fromStation']} → ${route['toStation']} · ${_labelForDayType(_scheduleDayType)}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showTimeEntryDialog(
                    routeDoc: routeDoc,
                    initial: {
                      'hour': (hours.isNotEmpty ? hours.first : 8),
                      'minute': 0,
                      'dayType': _scheduleDayType,
                      'isActive': true,
                    },
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('時刻追加'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 時刻表グリッド
            if (hours.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'このダイヤの登録時刻はありません',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 560),
                  child: DataTable(
                    headingTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    columns: const [
                      DataColumn(label: Text('時')),
                      DataColumn(label: Text('分')),
                      DataColumn(label: Text('本数')),
                    ],
                    rows: hours.map((h) {
                      final list = byHour[h]!..sort((a, b) => ((a['minute'] ?? 0) as int).compareTo((b['minute'] ?? 0) as int));
                      return DataRow(
                        cells: [
                          DataCell(Text(h.toString().padLeft(2, '0'))),
                          DataCell(Wrap(
                            spacing: 6,
                            runSpacing: -6,
                            children: list.map((m) {
                              final mm = (m['minute'] as int?) ?? 0;
                              final isActive = m['isActive'] as bool? ?? true;
                              final label = mm.toString().padLeft(2, '0');
                              final idx = _findTimeEntryIndex(route, h, mm, _scheduleDayType);
                              return InputChip(
                                label: Text(label),
                                selected: isActive,
                                onPressed: idx != null
                                    ? () => _showTimeEntryDialog(routeDoc: routeDoc, index: idx, initial: m)
                                    : null,
                                onDeleted: idx != null ? () => _deleteTimeEntry(routeDoc, idx) : null,
                                deleteIcon: const Icon(Icons.close, size: 16),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          )),
                          DataCell(Text('${list.length}')),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int? _findTimeEntryIndex(Map<String, dynamic> routeData, int hour, int minute, String dayType) {
    final entries = (routeData['timeEntries'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      if ((e['hour'] ?? -1) == hour && (e['minute'] ?? -1) == minute && (e['dayType'] ?? 'weekday') == dayType) {
        return i;
      }
    }
    return null;
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
                      const Icon(Icons.info, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text('運行状況管理', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
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
                return _buildErrorWidget('運行状況データの読み込みに失敗しました: ${snapshot.error}');
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
                              Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                _formatDateTime(
                                  (statusData['createdAt'] is Timestamp)
                                      ? (statusData['createdAt'] as Timestamp).toDate()
                                      : DateTime.now(),
                                ),
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                              const Spacer(),
                              _buildStatusTypeChip(type),
                            ],
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) => _handleOperationStatusAction(action, statusDoc),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('編集')),
                          PopupMenuItem(
                            value: statusData['isActive'] == true ? 'deactivate' : 'activate',
                            child: Text(statusData['isActive'] == true ? '非表示' : '表示'),
                          ),
                          const PopupMenuItem(value: 'delete', child: Text('削除')),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshData,
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
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
      } else if (operatingDays.length == 5 && !operatingDays.contains(0) && !operatingDays.contains(6)) {
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
      if (oldIndex < 0 || oldIndex >= docs.length || newIndex < 0 || newIndex >= docs.length) return;
      final moved = docs.removeAt(oldIndex);
      docs.insert(newIndex, moved);
      final batch = FirebaseFirestore.instance.batch();
      for (int i = 0; i < docs.length; i++) {
        batch.update(docs[i].reference, {'sortOrder': i, 'updatedAt': FieldValue.serverTimestamp()});
      }
      await batch.commit();
    });
  }

  void _addBusRoute() {
    _showRouteDialog();
  }

  void _addSchedule() {}

  void _showBulkAddRoutesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('路線の一括追加'),
        content: const Text('一括追加機能は未実装です。今後の更新で対応予定です。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('閉じる')),
        ],
      ),
    );
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

  void _handleScheduleAction(String action, QueryDocumentSnapshot scheduleDoc) {
    switch (action) {
      case 'edit':
        _showScheduleDialog(scheduleDoc: scheduleDoc);
        break;
      case 'delete':
        _deleteSchedule(scheduleDoc);
        break;
    }
  }

  void _handleOperationStatusAction(String action, QueryDocumentSnapshot statusDoc) {
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
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final fromCtrl = TextEditingController(text: data['fromStation'] ?? '');
    final toCtrl = TextEditingController(text: data['toStation'] ?? '');
    bool isActive = data['isActive'] ?? true;
    DateTime? startDate = (data['startDate'] is Timestamp)
        ? (data['startDate'] as Timestamp).toDate()
        : null;
    DateTime? endDate = (data['endDate'] is Timestamp)
        ? (data['endDate'] as Timestamp).toDate()
        : null;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text(isEdit ? '路線を編集' : '路線を追加'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '路線名')),
                TextField(controller: fromCtrl, decoration: const InputDecoration(labelText: '出発')),
                TextField(controller: toCtrl, decoration: const InputDecoration(labelText: '到着')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.event)
                        , label: Text(startDate != null ? _formatDate(startDate!) : '開始日 未設定'),
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
                              if (endDate != null && endDate!.isBefore(startDate!)) {
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
                        icon: const Icon(Icons.event)
                        , label: Text(endDate != null ? _formatDate(endDate!) : '終了日 未設定'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? (startDate ?? DateTime.now()),
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
            FilledButton(
              onPressed: () async {
                final col = FirebaseFirestore.instance
                    .collection('bus_information').doc('main').collection('bus_routes');
                final payload = {
                  'name': nameCtrl.text.trim(),
                  'fromStation': fromCtrl.text.trim(),
                  'toStation': toCtrl.text.trim(),
                  'isActive': isActive,
                  'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
                  'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
                  'updatedAt': FieldValue.serverTimestamp(),
                }..removeWhere((k, v) => v == null && (k == 'startDate' || k == 'endDate'));

                if (isEdit) {
                  await routeDoc!.reference.update(payload);
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

  void _showScheduleDialog({QueryDocumentSnapshot? scheduleDoc}) {}

  void _showOperationStatusDialog({QueryDocumentSnapshot? statusDoc}) {
    final isEdit = statusDoc != null;
    final data = (statusDoc?.data() as Map<String, dynamic>?) ?? {};
    final titleCtrl = TextEditingController(text: data['title'] ?? '');
    final msgCtrl = TextEditingController(text: data['message'] ?? '');
    String type = data['type'] ?? 'info';
    bool isActive = data['isActive'] ?? true;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? '運行情報を編集' : '運行情報を追加'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'タイトル')),
              TextField(controller: msgCtrl, decoration: const InputDecoration(labelText: 'メッセージ'), maxLines: 3),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'info', child: Text('通常')),
                  DropdownMenuItem(value: 'delay', child: Text('遅延')),
                  DropdownMenuItem(value: 'suspend', child: Text('運休')),
                ],
                onChanged: (v) => type = v ?? 'info',
                decoration: const InputDecoration(labelText: '種別'),
              ),
              SwitchListTile(value: isActive, onChanged: (v) => isActive = v, title: const Text('表示する')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          FilledButton(
            onPressed: () async {
              final col = FirebaseFirestore.instance
                  .collection('bus_information').doc('main').collection('operation_status');
              final payload = {
                'title': titleCtrl.text.trim(),
                'message': msgCtrl.text.trim(),
                'type': type,
                'isActive': isActive,
                'updatedAt': FieldValue.serverTimestamp(),
              };
              if (isEdit) {
                await statusDoc!.reference.update(payload);
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
          .collection('bus_information').doc('main').collection('bus_routes');
      final current = await col.orderBy('sortOrder').get();
      final sortOrder = current.docs.length;
      await col.add({
        ...data,
        'name': '${data['name']} (コピー)',
        'sortOrder': sortOrder,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('路線を複製しました')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('複製に失敗しました: $e')),
      );
    }
  }

  Future<void> _updateRouteStatus(QueryDocumentSnapshot routeDoc, String status) async {
    try {
      await routeDoc.reference.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('路線を${status == 'active' ? '運行開始' : '運行停止'}しました')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新に失敗しました: $e')),
      );
    }
  }

  Future<void> _deleteRoute(QueryDocumentSnapshot routeDoc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('路線削除'),
        content: const Text('この路線を削除しますか？関連する時刻表も削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await routeDoc.reference.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('路線を削除しました')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _deleteSchedule(QueryDocumentSnapshot scheduleDoc) async {
    try {
      await scheduleDoc.reference.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('時刻を削除しました')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除に失敗しました: $e')),
      );
    }
  }

  Future<void> _updateOperationStatusVisibility(QueryDocumentSnapshot statusDoc, bool isActive) async {
    try {
      await statusDoc.reference.update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('運行状況を${isActive ? '表示' : '非表示'}にしました')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新に失敗しました: $e')),
      );
    }
  }

  Future<void> _deleteOperationStatus(QueryDocumentSnapshot statusDoc) async {
    try {
      await statusDoc.reference.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('運行状況を削除しました')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除に失敗しました: $e')),
      );
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

  String _suggestTodayDayType() {
    final wd = DateTime.now().weekday;
    if (wd == DateTime.saturday) return 'saturday';
    if (wd == DateTime.sunday) return 'sunday';
    return 'weekday';
  }

  Color _getDarkerShade(Color color) {
    // Create a darker shade of the color (similar to shade700)
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.4).clamp(0.0, 1.0)).toColor();
  }

  List<Widget> _buildTimeEntries(QueryDocumentSnapshot routeDoc) {
    final routeData = routeDoc.data() as Map<String, dynamic>;
    final entries = (routeData['timeEntries'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList()
      ..sort((a, b) {
        final ah = (a['hour'] as int?) ?? 0;
        final am = (a['minute'] as int?) ?? 0;
        final bh = (b['hour'] as int?) ?? 0;
        final bm = (b['minute'] as int?) ?? 0;
        return (ah * 60 + am).compareTo(bh * 60 + bm);
      });

    if (entries.isEmpty) {
      return [
        const Text('時刻が登録されていません'),
      ];
    }

    return entries.asMap().entries.map((e) {
      final idx = e.key;
      final m = e.value;
      final hh = (m['hour'] as int?) ?? 0;
      final mm = (m['minute'] as int?) ?? 0;
      final note = m['note'] as String?;
      final isActive = m['isActive'] as bool? ?? true;
      final dayType = (m['dayType'] as String?) ?? 'weekday';
      final timeStr = '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
      return ListTile(
        dense: true,
        leading: Icon(isActive ? Icons.schedule : Icons.schedule_outlined, color: isActive ? Colors.blue : Colors.grey),
        title: Text(timeStr),
        subtitle: Text([
          _labelForDayType(dayType),
          if (note != null && note.isNotEmpty) note,
        ].join(' | ')),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleTimeEntryAction(action, routeDoc, idx, m),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('編集')),
            PopupMenuItem(value: isActive ? 'deactivate' : 'activate', child: Text(isActive ? '無効化' : '有効化')),
            const PopupMenuItem(value: 'delete', child: Text('削除')),
          ],
        ),
      );
    }).toList();
  }

  void _handleTimeEntryAction(String action, QueryDocumentSnapshot routeDoc, int index, Map<String, dynamic> entry) async {
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

  Future<void> _updateTimeEntryActive(QueryDocumentSnapshot routeDoc, int index, bool isActive) async {
    try {
      final data = routeDoc.data() as Map<String, dynamic>;
      final entries = List<Map<String, dynamic>>.from((data['timeEntries'] as List?)?.whereType<Map<String, dynamic>>() ?? []);
      if (index < 0 || index >= entries.length) return;
      entries[index]['isActive'] = isActive;
      await routeDoc.reference.update({'timeEntries': entries, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('更新に失敗しました: $e')));
    }
  }

  Future<void> _deleteTimeEntry(QueryDocumentSnapshot routeDoc, int index) async {
    try {
      final data = routeDoc.data() as Map<String, dynamic>;
      final entries = List<Map<String, dynamic>>.from((data['timeEntries'] as List?)?.whereType<Map<String, dynamic>>() ?? []);
      if (index < 0 || index >= entries.length) return;
      entries.removeAt(index);
      await routeDoc.reference.update({'timeEntries': entries, 'updatedAt': FieldValue.serverTimestamp()});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('時刻を削除しました')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('削除に失敗しました: $e')));
    }
  }

  void _showTimeEntryDialog({required QueryDocumentSnapshot routeDoc, int? index, Map<String, dynamic>? initial}) {
    final isEdit = index != null && initial != null;
    final hourCtrl = TextEditingController(text: ((initial?['hour'] as int?) ?? 8).toString());
    final minuteCtrl = TextEditingController(text: ((initial?['minute'] as int?) ?? 0).toString());
    final noteCtrl = TextEditingController(text: initial?['note'] as String? ?? '');
    bool isActive = initial?['isActive'] as bool? ?? true;
    String dayType = (initial?['dayType'] as String?) ?? _suggestTodayDayType();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? '時刻を編集' : '時刻を追加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: hourCtrl,
              decoration: const InputDecoration(labelText: '時 (0-23)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: minuteCtrl,
              decoration: const InputDecoration(labelText: '分 (0-59)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: '備考 (任意)'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: dayType,
              items: const [
                DropdownMenuItem(value: 'weekday', child: Text('平日')),
                DropdownMenuItem(value: 'saturday', child: Text('土曜日')),
                DropdownMenuItem(value: 'sunday', child: Text('日曜日')),
              ],
              onChanged: (v) => dayType = v ?? 'weekday',
              decoration: const InputDecoration(labelText: 'ダイヤ種別'),
            ),
            SwitchListTile(value: isActive, onChanged: (v) => isActive = v, title: const Text('有効')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          FilledButton(
            onPressed: () async {
              final h = int.tryParse(hourCtrl.text.trim()) ?? 0;
              final m = int.tryParse(minuteCtrl.text.trim()) ?? 0;
              if (h < 0 || h > 23 || m < 0 || m > 59) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('時刻が不正です')));
                return;
              }
              final data = routeDoc.data() as Map<String, dynamic>;
              final entries = List<Map<String, dynamic>>.from((data['timeEntries'] as List?)?.whereType<Map<String, dynamic>>() ?? []);
              final newEntry = {
                'hour': h,
                'minute': m,
                'note': noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                'isActive': isActive,
                'dayType': dayType,
              };
              if (isEdit) {
                if (index! < 0 || index >= entries.length) return;
                entries[index] = newEntry;
              } else {
                entries.add(newEntry);
              }
              // sort by time
              entries.sort((a, b) => (((a['hour'] ?? 0) as int) * 60 + ((a['minute'] ?? 0) as int))
                  .compareTo(((b['hour'] ?? 0) as int) * 60 + ((b['minute'] ?? 0) as int)));
              await routeDoc.reference.update({'timeEntries': entries, 'updatedAt': FieldValue.serverTimestamp()});
              if (context.mounted) Navigator.pop(ctx);
            },
            child: Text(isEdit ? '更新' : '追加'),
          ),
        ],
      ),
    );
  }
}


