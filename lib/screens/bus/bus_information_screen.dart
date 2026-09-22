import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/bus_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../models/bus/bus_model.dart';
import '../../services/widget/home_widgets_service.dart';
import '../../widgets/firebase_bus_timetable_widget.dart';

class BusInformationScreen extends ConsumerWidget {
  const BusInformationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busInfoAsync = ref.watch(busInformationStreamProvider);
    final preferredCampus = ref.watch(preferredBusCampusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('学バス情報'),
        leading: BackButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: busInfoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(context, e),
        data: (busInfo) {
          if (busInfo == null) return _buildEmpty(context);
          HomeWidgetsService.updateBusRealtime(
            busInfo,
            preferredCampus: preferredCampus,
          );
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(busInformationProvider);
              ref.invalidate(busInformationStreamProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(context, busInfo),
                const SizedBox(height: 16),
                _buildStatus(context, busInfo),
                const SizedBox(height: 16),
                _buildTimetable(context),
                const SizedBox(height: 16),
                _buildRoutes(context, busInfo),
                const SizedBox(height: 16),
                _buildPeriods(context, busInfo),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, BusInformation info) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_bus,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    info.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (info.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(info.description),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatus(BuildContext context, BusInformation info) {
    final isOperating = info.isCurrentlyOperating;
    final current = info.currentOperationPeriod;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOperating ? Icons.play_circle : Icons.pause_circle,
                  color: isOperating ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  isOperating ? '現在運行中' : '現在運行休止中',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (current != null) ...[
              const SizedBox(height: 8),
              Text(
                '運行期間: ${_formatDate(current.startDate)} 〜 ${_formatDate(current.endDate)}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimetable(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                '学バス時刻表',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            FirebaseBusTimetableWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutes(BuildContext context, BusInformation info) {
    final routes = info.operatingRoutes;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                 Icon(Icons.route, color: AppColors.accent(context, Colors.blue)),
                const SizedBox(width: 8),
                Text(
                  '路線（${routes.length}）',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (routes.isEmpty)
              Text(
                '現在表示できる路線はありません',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              )
            else
              ...routes.map((r) => _buildRouteTile(context, r)),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteTile(BuildContext context, BusRoute route) {
    final next = route.getNextBusTime();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.directions_bus),
      title: Text(route.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (route.description.isNotEmpty) Text(route.description),
          Text(
            '便数: ${route.activeTimeEntries.length}${next != null ? '｜次発: ${next.timeString}' : ''}',
          ),
        ],
      ),
    );
  }

  Widget _buildPeriods(BuildContext context, BusInformation info) {
    final periods = info.activeOperationPeriods;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                 Icon(Icons.date_range, color: AppColors.accent(context, Colors.green)),
                const SizedBox(width: 8),
                Text(
                  '運行期間（${periods.length}）',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (periods.isEmpty)
              Text(
                '現在有効な運行期間はありません',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              )
            else
              ...periods.map(
                (p) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_available),
                  title: Text(p.name),
                  subtitle: Text(
                    '${_formatDate(p.startDate)} 〜 ${_formatDate(p.endDate)}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:  [
          Icon(Icons.directions_bus_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
          SizedBox(height: 8),
          Text('学バス情報が設定されていません'),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, Object e) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           Icon(Icons.error_outline, size: 64, color: AppColors.accent(context, Colors.red)),
          const SizedBox(height: 8),
          Text('読み込みに失敗しました: $e'),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.year}年${d.month}月${d.day}日';
}
