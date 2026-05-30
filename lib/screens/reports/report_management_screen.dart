import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          isScrollable: true,
          tabs: [
            _tabWithCount('未対応', statisticsAsync, 'pending'),
            _tabWithCount('確認中', statisticsAsync, 'reviewing'),
            _tabWithCount('対応済み', statisticsAsync, 'resolved'),
            const Tab(text: 'すべて'),
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

  Widget _tabWithCount(
    String label,
    AsyncValue<Map<String, int>> statisticsAsync,
    String key,
  ) {
    return Tab(
      child: statisticsAsync.when(
        data: (stats) => Text('$label (${stats[key] ?? 0})'),
        loading: () => Text(label),
        error: (_, __) => Text(label),
      ),
    );
  }
}

class _ReportListView extends ConsumerWidget {
  const _ReportListView({
    required this.status,
    required this.onReportTap,
  });

  final ReportStatus? status;
  final void Function(Report) onReportTap;

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
                Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '通報はありません',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(reportsByStatusProvider(status));
          },
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final report = reports[index];
              return _ReportListTile(
                report: report,
                onTap: () => onReportTap(report),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 12),
              Text('データの取得に失敗しました', style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 8),
              Text(
                '$error',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportListTile extends StatelessWidget {
  const _ReportListTile({required this.report, required this.onTap});

  final Report report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final contentPreview = report.targetContent?.trim();
    final statusColor = _statusColor(report.status);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.15),
        child: Icon(_typeIcon(report.type), color: statusColor, size: 22),
      ),
      title: Text(
        report.type.displayName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('理由: ${report.reason.displayName}'),
          if (report.targetAuthorName != null &&
              report.targetAuthorName!.isNotEmpty)
            Text('対象: ${report.targetAuthorLabel}'),
          if (contentPreview != null && contentPreview.isNotEmpty)
            Text(
              contentPreview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          const SizedBox(height: 4),
          Text(
            '通報者: ${report.reporterName}'
            '${report.reporterEmail != null ? ' · ${report.reporterEmail}' : ''}'
            ' · ${report.timeAgo}',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: Chip(
        label: Text(report.status.displayName),
        labelStyle: TextStyle(fontSize: 11, color: statusColor),
        side: BorderSide(color: statusColor.withValues(alpha: 0.4)),
        backgroundColor: statusColor.withValues(alpha: 0.1),
      ),
    );
  }
}

class _ReportDetailDialog extends ConsumerStatefulWidget {
  const _ReportDetailDialog({required this.report});

  final Report report;

  @override
  ConsumerState<_ReportDetailDialog> createState() =>
      _ReportDetailDialogState();
}

class _ReportDetailDialogState extends ConsumerState<_ReportDetailDialog> {
  final _resolutionNoteController = TextEditingController();
  ReportStatus? _selectedStatus;
  bool _isUpdating = false;

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
    if (_selectedStatus == null) return;

    setState(() => _isUpdating = true);
    try {
      await ref.read(reportStatusUpdateProvider.notifier).updateStatus(
            reportId: widget.report.id,
            status: _selectedStatus!,
            resolutionNote: _resolutionNoteController.text.trim().isNotEmpty
                ? _resolutionNoteController.text.trim()
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
          content: Text('更新に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _copyText(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label をコピーしました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.flag, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '通報詳細',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionTitle('通報内容'),
                    _infoTile('種別', report.type.displayName),
                    _infoTile('理由', report.reason.displayName),
                    if (report.detail != null && report.detail!.trim().isNotEmpty)
                      _infoTile('通報者の補足', report.detail!),
                    _infoTile('ステータス', report.status.displayName),
                    _infoTile(
                      '通報日時',
                      report.createdAt.toString().substring(0, 19),
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle('通報者'),
                    _infoTile('表示名', report.reporterName),
                    if (report.reporterEmail != null)
                      _infoTile('メール', report.reporterEmail!, copyable: true),
                    _infoTile('ユーザーID', report.reporterId, copyable: true),
                    const SizedBox(height: 16),
                    _sectionTitle('対象コンテンツ'),
                    if (report.targetContent != null &&
                        report.targetContent!.trim().isNotEmpty)
                      _contentBox(report.targetContent!)
                    else
                      _infoTile('本文', '（記録なし）'),
                    _infoTile('対象ID', report.targetId, copyable: true),
                    if (report.targetPostId != null)
                      _infoTile('投稿ID', report.targetPostId!, copyable: true),
                    if (report.source != null)
                      _infoTile('ソース', report.source!),
                    const SizedBox(height: 16),
                    _sectionTitle('投稿者（通報対象）'),
                    if (report.targetAuthorName != null)
                      _infoTile('表示名', report.targetAuthorName!),
                    if (report.targetAuthorCwitterId != null)
                      _infoTile(
                        'Cwitter ID',
                        '@${report.targetAuthorCwitterId}',
                        copyable: true,
                      ),
                    if (report.targetAuthorEmail != null)
                      _infoTile(
                        'メール',
                        report.targetAuthorEmail!,
                        copyable: true,
                      ),
                    if (report.targetAuthorId != null)
                      _infoTile(
                        'ユーザーID',
                        report.targetAuthorId!,
                        copyable: true,
                      ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    _sectionTitle('対応'),
                    DropdownButtonFormField<ReportStatus>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'ステータス',
                      ),
                      items: ReportStatus.values
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: _isUpdating
                          ? null
                          : (v) => setState(() => _selectedStatus = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _resolutionNoteController,
                      maxLines: 4,
                      enabled: !_isUpdating,
                      decoration: const InputDecoration(
                        labelText: '対応メモ',
                        border: OutlineInputBorder(),
                        hintText: '対応内容や備考',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isUpdating ? null : () => Navigator.of(context).pop(),
                    child: const Text('閉じる'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isUpdating ? null : _updateStatus,
                    child: _isUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('更新'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }

  Widget _infoTile(String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(child: SelectableText(value)),
          if (copyable)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () => _copyText(label, value),
            ),
        ],
      ),
    );
  }

  Widget _contentBox(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SelectableText(text),
    );
  }
}

Color _statusColor(ReportStatus status) {
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

IconData _typeIcon(ReportType type) {
  switch (type) {
    case ReportType.post:
      return Icons.campaign;
    case ReportType.comment:
      return Icons.comment;
    case ReportType.user:
      return Icons.person;
    case ReportType.cwitterPost:
      return Icons.groups;
    case ReportType.cwitterReply:
      return Icons.reply;
    case ReportType.chibaChannelComment:
      return Icons.forum_outlined;
  }
}
