import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/bus/bus_model.dart';
import '../../core/providers/bus_provider.dart';

class BusManagementScreen extends ConsumerStatefulWidget {
  const BusManagementScreen({super.key});

  @override
  ConsumerState<BusManagementScreen> createState() => _BusManagementScreenState();
}

class _BusManagementScreenState extends ConsumerState<BusManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busInfo = ref.watch(busInformationStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('学バス情報管理'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey.shade700),
            onPressed: () {
              ref.invalidate(busInformationProvider);
              ref.invalidate(busInformationStreamProvider);
            },
            tooltip: '更新',
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.grey.shade700),
            onPressed: () => _showCreateInitialDataDialog(),
            tooltip: 'データ管理',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue.shade600,
          unselectedLabelColor: Colors.grey.shade500,
          indicatorColor: Colors.blue.shade600,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: '基本情報'),
            Tab(icon: Icon(Icons.route), text: '路線・時刻'),
            Tab(icon: Icon(Icons.date_range), text: '運行期間'),
          ],
        ),
      ),
      body: busInfo.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('データを読み込んでいます...'),
            ],
          ),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text('エラーが発生しました', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(busInformationProvider);
                  ref.invalidate(busInformationStreamProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('再読み込み'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        data: (data) {
          if (data == null) {
            return _buildEmptyState();
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBasicInfoTab(data),
              _buildRoutesTab(data),
              _buildPeriodsTab(data),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bus_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('学バス情報が設定されていません', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('初期データを作成してください'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _createInitialData(),
            icon: const Icon(Icons.add),
            label: const Text('初期データを作成'),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab(BusInformation busInfo) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイトルセクション
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.directions_bus,
                          color: Colors.blue.shade600,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              busInfo.title,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '最終更新: ${_formatDateTime(busInfo.lastUpdated)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (busInfo.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      busInfo.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditBusInfoDialog(busInfo),
                      icon: const Icon(Icons.edit),
                      label: const Text('基本情報を編集'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 統計情報
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '路線数',
                  '${busInfo.routes.length}',
                  '有効: ${busInfo.activeRoutes.length}',
                  Icons.route,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '運行期間',
                  '${busInfo.operationPeriods.length}',
                  '有効: ${busInfo.activeOperationPeriods.length}',
                  Icons.date_range,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 運行状況
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        busInfo.isCurrentlyOperating ? Icons.play_circle : Icons.pause_circle,
                        color: busInfo.isCurrentlyOperating ? Colors.green.shade600 : Colors.orange.shade600,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '運行状況',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: busInfo.isCurrentlyOperating ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: busInfo.isCurrentlyOperating ? Colors.green.shade200 : Colors.orange.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          busInfo.isCurrentlyOperating ? Icons.check_circle : Icons.warning,
                          size: 18,
                          color: busInfo.isCurrentlyOperating ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          busInfo.isCurrentlyOperating ? '現在運行中です' : '現在運行停止中です',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: busInfo.isCurrentlyOperating ? Colors.green.shade700 : Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (busInfo.currentOperationPeriod != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '運行期間: ${busInfo.currentOperationPeriod!.name}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 更新情報
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.update,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '更新情報',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '最終更新:',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateTime(busInfo.lastUpdated),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '更新者:',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        busInfo.updatedBy.isEmpty ? '不明' : busInfo.updatedBy,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, MaterialColor color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color.shade600,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildRoutesTab(BusInformation busInfo) {
    return Column(
      children: [
        // ヘッダー部分
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.route, color: Colors.blue.shade600, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '路線・時刻表',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      '全${busInfo.routes.length}路線 (有効: ${busInfo.activeRoutes.length})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _addBusRoute(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('新規追加'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showBulkAddDialog(),
                    icon: const Icon(Icons.playlist_add, size: 18),
                    label: const Text('一括追加'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // コンテンツ部分
        Expanded(
          child: busInfo.routes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.route_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '路線が登録されていません',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '「新規追加」ボタンから路線を追加してください',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => _addBusRoute(),
                        icon: const Icon(Icons.add),
                        label: const Text('最初の路線を追加'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  color: Colors.grey.shade50,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: busInfo.routes.length,
                    itemBuilder: (context, index) {
                      final route = busInfo.routes[index];
                      return _buildRouteCard(route, index, busInfo.routes);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRouteCard(BusRoute route, int index, List<BusRoute> allRoutes) {
    return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: route.isActive ? Colors.blue.shade100 : Colors.grey.shade200,
            width: 1,
          ),
        ),
      child: InkWell(
        onTap: () => _editBusRoute(route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 路線名とステータス
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: route.isActive ? Colors.blue.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      color: route.isActive ? Colors.blue.shade600 : Colors.grey.shade500,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: route.isActive ? Colors.grey.shade800 : Colors.grey.shade500,
                          ),
                        ),
                        if (route.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            route.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: route.isActive ? Colors.green.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: route.isActive ? Colors.green.shade200 : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      route.isActive ? '運行中' : '停止中',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: route.isActive ? Colors.green.shade700 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: route.isActive,
                    onChanged: (v) => _toggleRouteActive(route, v),
                  ),
                  const SizedBox(width: 4),
                  if (index > 0)
                    IconButton(
                      tooltip: '上へ',
                      icon: const Icon(Icons.arrow_upward, size: 18),
                      onPressed: () => _moveRoute(allRoutes, index, index - 1),
                    ),
                  if (index < allRoutes.length - 1)
                    IconButton(
                      tooltip: '下へ',
                      icon: const Icon(Icons.arrow_downward, size: 18),
                      onPressed: () => _moveRoute(allRoutes, index, index + 1),
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleRouteAction(value, route),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 16, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('複製'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('削除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 時刻表情報
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 18,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '時刻表',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${route.timeEntries.length}便 (有効: ${route.activeTimeEntries.length}便)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (route.activeTimeEntries.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '次: ${route.getNextBusTime()?.timeString ?? 'なし'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodsTab(BusInformation busInfo) {
    return Column(
      children: [
        // ヘッダー部分
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.date_range, color: Colors.green.shade600, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '運行期間',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      '全${busInfo.operationPeriods.length}期間 (有効: ${busInfo.activeOperationPeriods.length})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _addOperationPeriod(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('新規追加'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // コンテンツ部分
        Expanded(
          child: busInfo.operationPeriods.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.date_range_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '運行期間が登録されていません',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '「新規追加」ボタンから運行期間を追加してください',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => _addOperationPeriod(),
                        icon: const Icon(Icons.add),
                        label: const Text('最初の期間を追加'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  color: Colors.grey.shade50,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: busInfo.operationPeriods.length,
                    itemBuilder: (context, index) {
                      final period = busInfo.operationPeriods[index];
                      return _buildPeriodCard(period);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPeriodCard(BusOperationPeriod period) {
    final bool isCurrentlyActive = period.isCurrentlyActive();
    
    return Container(
      constraints: const BoxConstraints(maxHeight: 140), // 高さ制限を追加
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isCurrentlyActive ? Colors.green.shade100 : 
                   period.isActive ? Colors.blue.shade100 : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => _editOperationPeriod(period),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // 期間名とステータス
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCurrentlyActive ? Colors.green.shade50 : 
                             period.isActive ? Colors.blue.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isCurrentlyActive ? Icons.play_circle : 
                      period.isActive ? Icons.schedule : Icons.pause_circle,
                      color: isCurrentlyActive ? Colors.green.shade600 : 
                             period.isActive ? Colors.blue.shade600 : Colors.grey.shade500,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          period.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: period.isActive ? Colors.grey.shade800 : Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatDate(period.startDate)} ～ ${_formatDate(period.endDate)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCurrentlyActive ? Colors.green.shade50 : 
                             period.isActive ? Colors.blue.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isCurrentlyActive ? Colors.green.shade200 : 
                               period.isActive ? Colors.blue.shade200 : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isCurrentlyActive ? '運行中' : 
                      period.isActive ? '有効' : '無効',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isCurrentlyActive ? Colors.green.shade700 : 
                               period.isActive ? Colors.blue.shade700 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handlePeriodAction(value, period),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('編集'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 16, color: Colors.green),
                            SizedBox(width: 8),
                            Text('複製'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('削除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 12),
            
            // 期間の詳細情報
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.today, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              '開始: ${_formatDate(period.startDate)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.event, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              '終了: ${_formatDate(period.endDate)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${period.endDate.difference(period.startDate).inDays + 1}日間',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  void _showCreateInitialDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('初期データ管理'),
        content: const Text(
          '学バス情報の初期データを作成しますか？\n'
          'サンプルの路線と現在の日付に対応した運行期間が設定されます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _createInitialData(forceRecreate: true);
            },
            child: const Text('再作成', style: TextStyle(color: Colors.orange)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createInitialData();
            },
            child: const Text('作成'),
          ),
        ],
      ),
    );
  }

  void _createInitialData({bool forceRecreate = false}) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await ref
          .read(busServiceProvider)
          .createInitialBusData(forceRecreate: forceRecreate);

      if (mounted) Navigator.pop(context);

      if (success) {
        ref.invalidate(busInformationProvider);
        ref.invalidate(busInformationStreamProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(forceRecreate ? 'データを再作成しました' : '初期データを作成しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('初期データの作成に失敗しました'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addBusRoute() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusRouteEditScreen(),
      ),
    );
  }

  void _editBusRoute(BusRoute route) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusRouteEditScreen(route: route),
      ),
    );
  }

  void _addOperationPeriod() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OperationPeriodEditScreen(),
      ),
    );
  }
  
  void _editOperationPeriod(BusOperationPeriod period) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OperationPeriodEditScreen(period: period),
      ),
    );
  }

  /// 一括追加ダイアログを表示
  void _showBulkAddDialog() {
    showDialog(
      context: context,
      builder: (context) => BulkAddRoutesDialog(
        onRoutesAdded: (routes) async {
          await _addMultipleRoutes(routes);
        },
      ),
    );
  }

  /// 複数路線を一括追加
  Future<void> _addMultipleRoutes(List<BusRoute> routes) async {
    try {
      setState(() => _isLoading = true);
      
      final busService = ref.read(busServiceProvider);
      for (final route in routes) {
        await busService.addBusRoute(route);
      }
      
      ref.invalidate(busInformationProvider);
      ref.invalidate(busInformationStreamProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${routes.length}件の路線を追加しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('一括追加でエラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleRouteActive(BusRoute route, bool isActive) async {
    try {
      final busService = ref.read(busServiceProvider);
      await busService.updateBusRoute(route.copyWith(isActive: isActive));
      ref.invalidate(busInformationProvider);
      ref.invalidate(busInformationStreamProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('路線「${route.name}」を${isActive ? '有効' : '無効'}にしました'),
            backgroundColor: isActive ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _moveRoute(List<BusRoute> routes, int fromIndex, int toIndex) async {
    if (toIndex < 0 || toIndex >= routes.length) return;
    try {
      setState(() => _isLoading = true);
      final busService = ref.read(busServiceProvider);
      final a = routes[fromIndex];
      final b = routes[toIndex];
      final sa = a.sortOrder;
      final sb = b.sortOrder;
      await busService.updateBusRoute(a.copyWith(sortOrder: sb));
      await busService.updateBusRoute(b.copyWith(sortOrder: sa));
      ref.invalidate(busInformationProvider);
      ref.invalidate(busInformationStreamProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('並び替えに失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePeriodActive(BusOperationPeriod period, bool isActive) async {
    try {
      final busService = ref.read(busServiceProvider);
      await busService.updateOperationPeriod(period.copyWith(isActive: isActive));
      ref.invalidate(busInformationProvider);
      ref.invalidate(busInformationStreamProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('期間「${period.name}」を${isActive ? '有効' : '無効'}にしました'),
            backgroundColor: isActive ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditBusInfoDialog(BusInformation busInfo) {
    final titleController = TextEditingController(text: busInfo.title);
    final descriptionController = TextEditingController(text: busInfo.description);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('基本情報を編集'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'タイトル',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '説明',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final user = FirebaseAuth.instance.currentUser;
              final updated = BusInformation(
                id: busInfo.id,
                title: titleController.text.isEmpty ? busInfo.title : titleController.text,
                description: descriptionController.text,
                routes: busInfo.routes,
                operationPeriods: busInfo.operationPeriods,
                lastUpdated: DateTime.now(),
                updatedBy: user?.displayName ?? user?.email ?? '管理者',
              );
              final ok = await ref.read(busServiceProvider).saveBusInformation(updated);
              if (ok) {
                ref.invalidate(busInformationProvider);
                ref.invalidate(busInformationStreamProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('基本情報を更新しました'), backgroundColor: Colors.green),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('基本情報の更新に失敗しました'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 路線アクション処理
  void _handleRouteAction(String action, BusRoute route) {
    switch (action) {
      case 'duplicate':
        _duplicateRoute(route);
        break;
      case 'delete':
        _showDeleteRouteDialog(route);
        break;
    }
  }

  /// 路線を複製
  void _duplicateRoute(BusRoute route) {
    final duplicatedRoute = route.copyWith(
      id: _generateId(),
      name: '${route.name} (コピー)',
      sortOrder: route.sortOrder + 1,
      timeEntries: route.timeEntries.map((entry) => 
        entry.copyWith(id: _generateId())
      ).toList(),
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusRouteEditScreen(route: duplicatedRoute),
      ),
    );
  }

  /// 路線削除確認ダイアログ
  void _showDeleteRouteDialog(BusRoute route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('路線削除確認'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('この路線を削除しますか？この操作は元に戻せません。'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (route.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(route.description),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '時刻表: ${route.timeEntries.length}件の時刻',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteRoute(route);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  /// 路線削除実行
  Future<void> _deleteRoute(BusRoute route) async {
    try {
      final busService = ref.read(busServiceProvider);
      await busService.deleteBusRoute(route.id);
      
      ref.invalidate(busInformationProvider);
      ref.invalidate(busInformationStreamProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('路線「${route.name}」を削除しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('削除でエラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// 運行期間アクション処理
  void _handlePeriodAction(String action, BusOperationPeriod period) {
    switch (action) {
      case 'edit':
        _editOperationPeriod(period);
        break;
      case 'duplicate':
        _duplicatePeriod(period);
        break;
      case 'delete':
        _showDeletePeriodDialog(period);
        break;
    }
  }

  /// 運行期間を複製
  void _duplicatePeriod(BusOperationPeriod period) {
    final duplicatedPeriod = period.copyWith(
      id: _generateId(),
      name: '${period.name} (コピー)',
      startDate: period.startDate.add(const Duration(days: 1)),
      endDate: period.endDate.add(const Duration(days: 1)),
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OperationPeriodEditScreen(period: duplicatedPeriod),
      ),
    );
  }

  /// 運行期間削除確認ダイアログ
  void _showDeletePeriodDialog(BusOperationPeriod period) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('運行期間削除確認'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('この運行期間を削除しますか？この操作は元に戻せません。'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    period.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('期間: ${_formatDate(period.startDate)} ～ ${_formatDate(period.endDate)}'),
                  const SizedBox(height: 4),
                  Text(
                    '状態: ${period.isCurrentlyActive() ? "運行中" : period.isActive ? "有効" : "無効"}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePeriod(period);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  /// 運行期間削除実行
  Future<void> _deletePeriod(BusOperationPeriod period) async {
    try {
      final busService = ref.read(busServiceProvider);
      await busService.deleteOperationPeriod(period.id);
      
      ref.invalidate(busInformationProvider);
      ref.invalidate(busInformationStreamProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('運行期間「${period.name}」を削除しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('削除でエラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDebugInfo() async {
    try {
      print('🚌 デバッグ情報取得開始');
      final busService = ref.read(busServiceProvider);
      final busInfo = await busService.getBusInformation();
      
      final streamProviderState = ref.read(busInformationStreamProvider);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('デバッグ情報'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('直接取得データ存在: ${busInfo != null}'),
                  if (busInfo != null) ...[
                    Text('タイトル: ${busInfo.title}'),
                    Text('説明: ${busInfo.description}'),
                    Text('路線数: ${busInfo.routes.length}'),
                    Text('運行期間数: ${busInfo.operationPeriods.length}'),
                    Text('運行中: ${busInfo.isCurrentlyOperating}'),
                    Text('更新者: ${busInfo.updatedBy}'),
                  ],
                  const SizedBox(height: 16),
                  Text('StreamProvider状態: ${streamProviderState.runtimeType}'),
                  Text('StreamProvider hasValue: ${streamProviderState.hasValue}'),
                  Text('StreamProvider error: ${streamProviderState.error}'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ デバッグ情報取得エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('デバッグ情報取得エラー: $e')),
        );
      }
    }
  }
}

// バス路線編集画面 (ダイヤ作成機能付き)
class BusRouteEditScreen extends ConsumerStatefulWidget {
  final BusRoute? route;
  
  const BusRouteEditScreen({super.key, this.route});
  
  @override
  ConsumerState<BusRouteEditScreen> createState() => _BusRouteEditScreenState();
}

class _BusRouteEditScreenState extends ConsumerState<BusRouteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late List<BusTimeEntry> _timeEntries;
  late int _sortOrder;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final route = widget.route;
    _nameController = TextEditingController(text: route?.name ?? '');
    _descriptionController = TextEditingController(text: route?.description ?? '');
    _timeEntries = route?.timeEntries.map((e) => e.copyWith(id: e.id.isEmpty ? _generateId() : e.id)).toList() ?? [];
    _sortOrder = route?.sortOrder ?? 1;
    _isActive = route?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.route != null ? 'バス路線編集' : 'バス路線追加'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveRoute,
              child: const Text(
                '保存',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 基本情報セクション
              _buildBasicInfoSection(),
              
              const SizedBox(height: 24),
              
              // 時刻表セクション
              _buildTimetableSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '基本情報',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 路線名
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '路線名',
                hintText: '例: 津田沼 → 新習志野',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_bus),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '路線名を入力してください';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // 説明
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '説明 (任意)',
                hintText: '例: 津田沼キャンパスから新習志野キャンパスへ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 16),
            
            // 表示順序と有効/無効
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _sortOrder.toString(),
                    decoration: const InputDecoration(
                      labelText: '表示順序',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sort),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '表示順序を入力してください';
                      }
                      final number = int.tryParse(value);
                      if (number == null || number < 1) {
                        return '1以上の数値を入力してください';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _sortOrder = int.tryParse(value) ?? _sortOrder;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SwitchListTile(
                    title: const Text('有効'),
                    subtitle: Text(_isActive ? '運行中' : '停止中'),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetableSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '時刻表',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _addTimeEntry,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('時刻追加'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showBulkTimeAddDialog,
                  icon: const Icon(Icons.playlist_add, size: 18),
                  label: const Text('一括追加'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_timeEntries.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '時刻が設定されていません',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '「時刻追加」ボタンから時刻を追加してください',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // 時刻一覧
              ...List.generate(_timeEntries.length, (index) {
                return _buildTimeEntryCard(index);
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeEntryCard(int index) {
    final entry = _timeEntries[index];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // 時刻表示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: entry.isActive ? Colors.blue.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: entry.isActive ? Colors.blue.shade200 : Colors.grey.shade300,
                ),
              ),
              child: Text(
                entry.timeString,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: entry.isActive ? Colors.blue.shade700 : Colors.grey.shade600,
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // メモ表示
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entry.note != null && entry.note!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        entry.note!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'メモなし',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  Text(
                    entry.isActive ? '運行中' : '停止中',
                    style: TextStyle(
                      color: entry.isActive ? Colors.green.shade600 : Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // アクションボタン
            Switch(
              value: entry.isActive,
              onChanged: (v) {
                setState(() {
                  _timeEntries[index] = entry.copyWith(isActive: v);
                });
              },
            ),
            IconButton(
              onPressed: () => _editTimeEntry(index),
              icon: const Icon(Icons.edit),
              tooltip: '編集',
            ),
            IconButton(
              onPressed: () => _deleteTimeEntry(index),
              icon: const Icon(Icons.delete),
              color: Colors.red.shade600,
              tooltip: '削除',
            ),
          ],
        ),
      ),
    );
  }

  void _addTimeEntry() {
    showDialog(
      context: context,
      builder: (context) => _TimeEntryDialog(
        onSave: (hour, minute, note, isActive) {
          setState(() {
            _timeEntries.add(BusTimeEntry(
              id: _generateId(),
              hour: hour,
              minute: minute,
              note: note.isEmpty ? null : note,
              isActive: isActive,
            ));
            _timeEntries.sort((a, b) {
              if (a.hour != b.hour) return a.hour.compareTo(b.hour);
              return a.minute.compareTo(b.minute);
            });
          });
        },
      ),
    );
  }

  void _showBulkTimeAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('時刻を一括追加'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('例: 8:30 9:00 9:30 または 0830, 0900, 0930'),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: '時刻を空白・改行・カンマ区切りで入力',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              final input = controller.text.trim();
              if (input.isEmpty) {
                Navigator.pop(context);
                return;
              }
              final tokens = input
                  .replaceAll('\n', ' ')
                  .split(RegExp(r"[ ,\t]+"))
                  .where((t) => t.isNotEmpty)
                  .toList();
              final List<BusTimeEntry> added = [];
              for (final t in tokens) {
                final s = t.replaceAll('：', ':');
                int? h;
                int? m;
                if (s.contains(':')) {
                  final parts = s.split(':');
                  h = int.tryParse(parts[0]);
                  m = int.tryParse(parts[1]);
                } else if (RegExp(r'^\d{3,4}$').hasMatch(s)) {
                  final ss = s.padLeft(4, '0');
                  h = int.tryParse(ss.substring(0, 2));
                  m = int.tryParse(ss.substring(2, 4));
                }
                if (h != null && m != null && h >= 0 && h <= 23 && m >= 0 && m <= 59) {
                  added.add(BusTimeEntry(id: _generateId(), hour: h, minute: m, isActive: true));
                }
              }
              setState(() {
                _timeEntries.addAll(added);
                // unique & sort
                final seen = <String>{};
                _timeEntries = _timeEntries.where((e) => seen.add('${e.hour}:${e.minute}')).toList()
                  ..sort((a, b) {
                    if (a.hour != b.hour) return a.hour.compareTo(b.hour);
                    return a.minute.compareTo(b.minute);
                  });
              });
              Navigator.pop(context);
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  void _editTimeEntry(int index) {
    final entry = _timeEntries[index];
    showDialog(
      context: context,
      builder: (context) => _TimeEntryDialog(
        initialHour: entry.hour,
        initialMinute: entry.minute,
        initialNote: entry.note ?? '',
        initialIsActive: entry.isActive,
        onSave: (hour, minute, note, isActive) {
          setState(() {
            _timeEntries[index] = entry.copyWith(
              hour: hour,
              minute: minute,
              note: note.isEmpty ? null : note,
              isActive: isActive,
            );
            _timeEntries.sort((a, b) {
              if (a.hour != b.hour) return a.hour.compareTo(b.hour);
              return a.minute.compareTo(b.minute);
            });
          });
        },
      ),
    );
  }

  void _deleteTimeEntry(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('時刻削除'),
        content: Text('${_timeEntries[index].timeString}の時刻を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _timeEntries.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _saveRoute() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_timeEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('少なくとも1つの時刻を設定してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final busService = ref.read(busServiceProvider);
      
      if (widget.route != null) {
        // 編集の場合
        final updatedRoute = widget.route!.copyWith(
          name: _nameController.text,
          description: _descriptionController.text,
          timeEntries: _timeEntries,
          sortOrder: _sortOrder,
          isActive: _isActive,
        );
        
        final success = await busService.updateBusRoute(updatedRoute);
        if (success) {
          if (mounted) {
            ref.invalidate(busInformationProvider);
            ref.invalidate(busInformationStreamProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('路線を更新しました'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        } else {
          throw Exception('路線の更新に失敗しました');
        }
      } else {
        // 新規作成の場合
        final newRoute = BusRoute(
          id: '',
          name: _nameController.text,
          description: _descriptionController.text,
          timeEntries: _timeEntries,
          sortOrder: _sortOrder,
          isActive: _isActive,
        );
        
        final routeId = await busService.addBusRoute(newRoute);
        if (routeId != null) {
          if (mounted) {
            ref.invalidate(busInformationProvider);
            ref.invalidate(busInformationStreamProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('新しい路線を作成しました'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        } else {
          throw Exception('路線の作成に失敗しました');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleRouteActive(BusRoute route, bool isActive) async {
    try {
      final busService = ref.read(busServiceProvider);
      await busService.updateBusRoute(route.copyWith(isActive: isActive));
      ref.invalidate(busInformationProvider);
      ref.invalidate(busInformationStreamProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('路線「${route.name}」を${isActive ? '有効' : '無効'}にしました'),
            backgroundColor: isActive ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _moveRoute(List<BusRoute> routes, int fromIndex, int toIndex) async {
    if (toIndex < 0 || toIndex >= routes.length) return;
    try {
      setState(() => _isLoading = true);
      final busService = ref.read(busServiceProvider);
      final a = routes[fromIndex];
      final b = routes[toIndex];
      final sa = a.sortOrder;
      final sb = b.sortOrder;
      await busService.updateBusRoute(a.copyWith(sortOrder: sb));
      await busService.updateBusRoute(b.copyWith(sortOrder: sa));
      ref.invalidate(busInformationProvider);
      ref.invalidate(busInformationStreamProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('並び替えに失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePeriodActive(BusOperationPeriod period, bool isActive) async {
    try {
      final busService = ref.read(busServiceProvider);
      await busService.updateOperationPeriod(period.copyWith(isActive: isActive));
      ref.invalidate(busInformationProvider);
      ref.invalidate(busInformationStreamProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('期間「${period.name}」を${isActive ? '有効' : '無効'}にしました'),
            backgroundColor: isActive ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditBusInfoDialog(BusInformation busInfo) {
    final titleController = TextEditingController(text: busInfo.title);
    final descriptionController = TextEditingController(text: busInfo.description);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('基本情報を編集'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'タイトル',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '説明',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final user = FirebaseAuth.instance.currentUser;
              final updated = BusInformation(
                id: busInfo.id,
                title: titleController.text.isEmpty ? busInfo.title : titleController.text,
                description: descriptionController.text,
                routes: busInfo.routes,
                operationPeriods: busInfo.operationPeriods,
                lastUpdated: DateTime.now(),
                updatedBy: user?.displayName ?? user?.email ?? '管理者',
              );
              final ok = await ref.read(busServiceProvider).saveBusInformation(updated);
              if (ok) {
                ref.invalidate(busInformationProvider);
                ref.invalidate(busInformationStreamProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('基本情報を更新しました'), backgroundColor: Colors.green),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('基本情報の更新に失敗しました'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

// 時刻入力ダイアログ
class _TimeEntryDialog extends StatefulWidget {
  final int? initialHour;
  final int? initialMinute;
  final String? initialNote;
  final bool? initialIsActive;
  final Function(int hour, int minute, String note, bool isActive) onSave;

  const _TimeEntryDialog({
    required this.onSave,
    this.initialHour,
    this.initialMinute,
    this.initialNote,
    this.initialIsActive,
  });

  @override
  State<_TimeEntryDialog> createState() => __TimeEntryDialogState();
}

class __TimeEntryDialogState extends State<_TimeEntryDialog> {
  late TextEditingController _hourController;
  late TextEditingController _minuteController;
  late TextEditingController _noteController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _hourController = TextEditingController(text: (widget.initialHour ?? 8).toString());
    _minuteController = TextEditingController(text: (widget.initialMinute ?? 0).toString().padLeft(2, '0'));
    _noteController = TextEditingController(text: widget.initialNote ?? '');
    _isActive = widget.initialIsActive ?? true;
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('時刻設定'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _hourController,
                    decoration: const InputDecoration(
                      labelText: '時',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(':', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _minuteController,
                    decoration: const InputDecoration(
                      labelText: '分',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'メモ (任意)',
                hintText: '例: 最終便、土日のみ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('有効'),
              subtitle: Text(_isActive ? '運行する' : '運行しない'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () {
            final hour = int.tryParse(_hourController.text);
            final minute = int.tryParse(_minuteController.text);
            
            if (hour == null || hour < 0 || hour > 23) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('時は0〜23の間で入力してください')),
              );
              return;
            }
            
            if (minute == null || minute < 0 || minute > 59) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('分は0〜59の間で入力してください')),
              );
              return;
            }
            
            widget.onSave(hour, minute, _noteController.text, _isActive);
            Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

// 一括追加ダイアログ
class BulkAddRoutesDialog extends StatefulWidget {
  final Function(List<BusRoute>) onRoutesAdded;
  
  const BulkAddRoutesDialog({super.key, required this.onRoutesAdded});
  
  @override
  State<BulkAddRoutesDialog> createState() => _BulkAddRoutesDialogState();
}

class _BulkAddRoutesDialogState extends State<BulkAddRoutesDialog> {
  final List<Map<String, String>> _presetRoutes = [
    {'name': '津田沼 → 新習志野', 'description': '津田沼キャンパスから新習志野キャンパスへ'},
    {'name': '新習志野 → 津田沼', 'description': '新習志野キャンパスから津田沼キャンパスへ'},
    {'name': '津田沼駅 → 津田沼キャンパス', 'description': 'JR津田沼駅から津田沼キャンパスへ'},
    {'name': '津田沼キャンパス → 津田沼駅', 'description': '津田沼キャンパスからJR津田沼駅へ'},
    {'name': '新習志野駅 → 新習志野キャンパス', 'description': 'JR新習志野駅から新習志野キャンパスへ'},
    {'name': '新習志野キャンパス → 新習志野駅', 'description': '新習志野キャンパスからJR新習志野駅へ'},
  ];
  
  final Set<int> _selectedRoutes = <int>{};
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('路線一括追加'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '追加したい路線を選択してください。時刻表は後で個別に設定できます。',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _presetRoutes.length,
                itemBuilder: (context, index) {
                  final route = _presetRoutes[index];
                  final isSelected = _selectedRoutes.contains(index);
                  
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedRoutes.add(index);
                        } else {
                          _selectedRoutes.remove(index);
                        }
                      });
                    },
                    title: Text(
                      route['name']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(route['description']!),
                    dense: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _selectedRoutes.isEmpty ? null : () {
            final routes = _selectedRoutes.map((index) {
              final preset = _presetRoutes[index];
              return BusRoute(
                id: DateTime.now().millisecondsSinceEpoch.toString() + index.toString(),
                name: preset['name']!,
                description: preset['description']!,
                timeEntries: [], // 空の時刻表で作成
                sortOrder: index + 1,
                isActive: true,
              );
            }).toList();
            
            Navigator.pop(context);
            widget.onRoutesAdded(routes);
          },
          child: Text('${_selectedRoutes.length}件追加'),
        ),
      ],
    );
  }
}

// 運行期間編集画面
class OperationPeriodEditScreen extends ConsumerStatefulWidget {
  final BusOperationPeriod? period;
  
  const OperationPeriodEditScreen({super.key, this.period});
  
  @override
  ConsumerState<OperationPeriodEditScreen> createState() => _OperationPeriodEditScreenState();
}

class _OperationPeriodEditScreenState extends ConsumerState<OperationPeriodEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final period = widget.period;
    _nameController = TextEditingController(text: period?.name ?? '');
    _descriptionController = TextEditingController(text: period?.description ?? '');
    _startDate = period?.startDate ?? DateTime.now();
    _endDate = period?.endDate ?? DateTime.now().add(const Duration(days: 30));
    _isActive = period?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.period != null ? '運行期間編集' : '運行期間追加'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _savePeriod,
              child: const Text(
                '保存',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 基本情報セクション
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            '基本情報',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // 期間名
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '期間名',
                          hintText: '例: 2024年度前期',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '期間名を入力してください';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 説明
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: '説明 (任意)',
                          hintText: '例: 4月から9月までの運行期間',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 2,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 有効・無効切り替え
                      SwitchListTile(
                        title: const Text('有効'),
                        subtitle: Text(_isActive ? '有効な運行期間です' : '無効な運行期間です'),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 日程設定セクション
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.date_range, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            '運行期間',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // 開始日
                      InkWell(
                        onTap: () => _selectStartDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.blue.shade600),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('開始日', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text(
                                    _formatDate(_startDate),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // 終了日
                      InkWell(
                        onTap: () => _selectEndDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.event, color: Colors.orange.shade600),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('終了日', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text(
                                    _formatDate(_endDate),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // 期間情報表示
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue.shade600, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '期間: ${_endDate.difference(_startDate).inDays + 1}日間',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // 終了日が開始日より前の場合は調整
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _savePeriod() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('終了日は開始日より後に設定してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final busService = ref.read(busServiceProvider);
      
      if (widget.period != null) {
        // 編集の場合
        final updatedPeriod = widget.period!.copyWith(
          name: _nameController.text,
          description: _descriptionController.text,
          startDate: _startDate,
          endDate: _endDate,
          isActive: _isActive,
        );
        
        final success = await busService.updateOperationPeriod(updatedPeriod);
        
        if (success) {
          ref.invalidate(busInformationProvider);
          ref.invalidate(busInformationStreamProvider);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('運行期間を更新しました'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        } else {
          throw Exception('運行期間の更新に失敗しました');
        }
      } else {
        // 新規作成の場合
        final newPeriod = BusOperationPeriod(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          description: _descriptionController.text,
          startDate: _startDate,
          endDate: _endDate,
          isActive: _isActive,
        );
        
        final result = await busService.addOperationPeriod(newPeriod);
        
        if (result != null) {
          ref.invalidate(busInformationProvider);
          ref.invalidate(busInformationStreamProvider);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('新しい運行期間を作成しました'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        } else {
          throw Exception('運行期間の作成に失敗しました');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
