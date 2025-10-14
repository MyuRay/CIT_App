import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/reports/report_model.dart';
import '../../core/providers/report_provider.dart';

class ReportManagementScreen extends ConsumerStatefulWidget {
  const ReportManagementScreen({super.key});

  @override
  ConsumerState<ReportManagementScreen> createState() =>
      _ReportManagementScreenState();
}

class _ReportManagementScreenState
    extends ConsumerState<ReportManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showReportDetailDialog(Report report) async {
    await showDialog(
      context: context,
      builder: (context) => _ReportDetailDialog(report: report),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statisticsAsync = ref.watch(reportStatisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('通報管理'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: statisticsAsync.when(
                data: (stats) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('未対応'),
                    Text(
                      '(${stats['pending'] ?? 0})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                loading: () => const Text('未対応'),
                error: (_, __) => const Text('未対応'),
              ),
            ),
            Tab(
              child: statisticsAsync.when(
                data: (stats) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('確認中'),
                    Text(
                      '(${stats['reviewing'] ?? 0})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                loading: () => const Text('確認中'),
                error: (_, __) => const Text('確認中'),
              ),
            ),
            Tab(
              child: statisticsAsync.when(
                data: (stats) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('対応済み'),
                    Text(
                      '(${stats['resolved'] ?? 0})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                loading: () => const Text('対応済み'),
                error: (_, __) => const Text('対応済み'),
              ),
            ),
            const Tab(text: '全て'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReportListView(
            status: ReportStatus.pending,
            onReportTap: _showReportDetailDialog,
          ),
          _ReportListView(
            status: ReportStatus.reviewing,
            onReportTap: _showReportDetailDialog,
          ),
          _ReportListView(
            status: ReportStatus.resolved,
            onReportTap: _showReportDetailDialog,
          ),
          _ReportListView(
            status: null,
            onReportTap: _showReportDetailDialog,
          ),
        ],
      ),
    );
  }
}

class _ReportListView extends ConsumerWidget {
  final ReportStatus? status;
  final Function(Report) onReportTap;

  const _ReportListView({
    required this.status,
    required this.onReportTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsByStatusProvider(status));

    return reportsAsync.when(
      data: (reports) {
        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '通報はありません',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: reports.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final report = reports[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(report.status),
                child: Icon(
                  _getTypeIcon(report.type),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: Text(
                '${report.type.displayName}の通報',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '理由: ${report.reason.displayName}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (report.detail != null && report.detail!.isNotEmpty)
                    Text(
                      report.detail!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '通報者: ${report.reporterName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${report.timeAgo}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Chip(
                label: Text(
                  report.status.displayName,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: _getStatusColor(report.status).withOpacity(0.2),
                labelStyle: TextStyle(color: _getStatusColor(report.status)),
              ),
              isThreeLine: true,
              onTap: () => onReportTap(report),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'データの取得に失敗しました',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.reviewing:
        return Colors.blue;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.rejected:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(ReportType type) {
    switch (type) {
      case ReportType.post:
        return Icons.article;
      case ReportType.comment:
        return Icons.comment;
      case ReportType.user:
        return Icons.person;
    }
  }
}

class _ReportDetailDialog extends ConsumerStatefulWidget {
  final Report report;

  const _ReportDetailDialog({required this.report});

  @override
  ConsumerState<_ReportDetailDialog> createState() =>
      _ReportDetailDialogState();
}

class _ReportDetailDialogState extends ConsumerState<_ReportDetailDialog> {
  final _resolutionNoteController = TextEditingController();
  ReportStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.report.status;
    _resolutionNoteController.text = widget.report.resolutionNote ?? '';
  }

  @override
  void dispose() {
    _resolutionNoteController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == null) {
      return;
    }

    try {
      await ref.read(reportStatusUpdateProvider.notifier).updateStatus(
            reportId: widget.report.id,
            status: _selectedStatus!,
            resolutionNote: _resolutionNoteController.text.isNotEmpty
                ? _resolutionNoteController.text
                : null,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ステータスを更新しました'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更新に失敗しました: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Row(
                children: [
                  const Icon(Icons.flag, color: Colors.red, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '通報詳細',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 通報情報
              _buildInfoRow('種別', widget.report.type.displayName),
              _buildInfoRow('対象ID', widget.report.targetId),
              _buildInfoRow('理由', widget.report.reason.displayName),
              if (widget.report.detail != null)
                _buildInfoRow('詳細', widget.report.detail!),
              _buildInfoRow('通報者', widget.report.reporterName),
              _buildInfoRow(
                  '通報日時', widget.report.createdAt.toString().substring(0, 19)),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              // ステータス変更
              const Text(
                'ステータス',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ReportStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: ReportStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              // 対応メモ
              TextFormField(
                controller: _resolutionNoteController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: '対応メモ',
                  border: OutlineInputBorder(),
                  hintText: '対応内容や備考を記入してください',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 24),

              // ボタン
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('キャンセル'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _updateStatus,
                    child: const Text('更新'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
