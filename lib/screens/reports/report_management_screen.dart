import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/reports/report_model.dart';
import '../../core/providers/report_provider.dart';
import '../../widgets/admin/admin_access_gate.dart';
import '../../widgets/admin/admin_list_components.dart';

class ReportManagementScreen extends ConsumerStatefulWidget {
  const ReportManagementScreen({super.key});
  @override
  ConsumerState<ReportManagementScreen> createState() =>
      _ReportManagementScreenState();
}

class _ReportManagementScreenState
    extends ConsumerState<ReportManagementScreen> {
  final _search = TextEditingController();
  ReportStatus? _status = ReportStatus.pending;
  ReportType? _type;
  bool _oldestFirst = true;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(allReportsProvider);
    ref.invalidate(reportStatisticsProvider);
    try {
      await ref.read(allReportsProvider.future);
    } catch (_) {
      /* Inline retry. */
    }
  }

  @override
  Widget build(BuildContext context) =>
      AdminAccessGate(title: '通報管理', builder: _content);

  Widget _content(BuildContext context) {
    final reports = ref.watch(allReportsProvider);
    final q = _search.text.trim().toLowerCase();
    final visible = reports.whenData((all) {
      final list =
          all
              .where(
                (report) =>
                    (_status == null || report.status == _status) &&
                    (_type == null || report.type == _type) &&
                    [
                      report.id,
                      report.targetId,
                      report.reporterName,
                      report.reporterEmail ?? '',
                      report.targetAuthorName ?? '',
                      report.targetContent ?? '',
                      report.detail ?? '',
                      report.resolutionNote ?? '',
                    ].any((text) => text.toLowerCase().contains(q)),
              )
              .toList();
      list.sort((a, b) {
        final date =
            _oldestFirst
                ? a.createdAt.compareTo(b.createdAt)
                : b.createdAt.compareTo(a.createdAt);
        return date == 0 ? a.id.compareTo(b.id) : date;
      });
      return list;
    });
    return AdminCollectionScaffold<Report>(
      title: '通報管理',
      items: visible,
      onRefresh: _refresh,
      itemBuilder: _card,
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSearchField(
            controller: _search,
            hint: '対象・通報者・内容・IDを検索',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final status in [...ReportStatus.values, null])
                ChoiceChip(
                  label: Text(
                    reports.hasValue
                        ? '${status?.displayName ?? 'すべて'} ${reports.requireValue.where((r) => status == null || r.status == status).length}'
                        : status?.displayName ?? 'すべて',
                  ),
                  selected: _status == status,
                  onSelected: (_) => setState(() => _status = status),
                ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ReportType?>(
            key: ValueKey(_type),
            initialValue: _type,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: '通報対象',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('すべての対象')),
              for (final type in ReportType.values)
                DropdownMenuItem(value: type, child: Text(type.displayName)),
            ],
            onChanged: (value) => setState(() => _type = value),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                visible.hasValue
                    ? '${visible.requireValue.length}件を表示'
                    : '読み込み中',
              ),
              FilterChip(
                label: const Text('古い通報から確認'),
                selected: _oldestFirst,
                onSelected: (value) => setState(() => _oldestFirst = value),
              ),
              if (q.isNotEmpty || _type != null)
                TextButton(
                  onPressed:
                      () => setState(() {
                        _search.clear();
                        _type = null;
                      }),
                  child: const Text('検索条件をクリア'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, Report report) => Card(
    margin: EdgeInsets.zero,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap:
          () => showDialog<void>(
            context: context,
            builder: (_) => _ReportDetailDialog(report: report),
          ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                AdminStatusPill(
                  report.status.displayName,
                  color: _statusColor(report.status),
                ),
                AdminStatusPill(report.type.displayName, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              report.reason.displayName,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (report.targetAuthorName?.isNotEmpty == true)
              Text('対象：${report.targetAuthorLabel}'),
            if (report.targetContent?.trim().isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  report.targetContent!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (report.detail?.trim().isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  report.detail!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 10),
            Text(
              '通報者：${report.reporterName} ・ ${report.timeAgo}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              '内容を確認・対応を記録 →',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
    ),
  );
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
    if (_selectedStatus == null || _isUpdating) return;

    setState(() => _isUpdating = true);
    try {
      await ref
          .read(reportStatusUpdateProvider.notifier)
          .updateStatus(
            reportId: widget.report.id,
            status: _selectedStatus!,
            resolutionNote:
                _resolutionNoteController.text.trim().isNotEmpty
                    ? _resolutionNoteController.text.trim()
                    : null,
          );

      final result = ref.read(reportStatusUpdateProvider);
      if (result.hasError) throw result.error!;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ステータスを更新しました'),
          backgroundColor: AppColors.snackBarSurface(context, Colors.green),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更新に失敗しました: $e'),
          backgroundColor: AppColors.snackBarSurface(context, Colors.red),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _copyText(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label をコピーしました')));
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;

    return PopScope(
      canPop: !_isUpdating,
      child: Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.flag,
                      color: AppColors.accent(context, Colors.red),
                    ),
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
                      onPressed:
                          _isUpdating
                              ? null
                              : () => Navigator.of(context).pop(),
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
                      if (report.detail != null &&
                          report.detail!.trim().isNotEmpty)
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
                        initialValue: _selectedStatus,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'ステータス',
                        ),
                        items:
                            ReportStatus.values
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s.displayName),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            _isUpdating
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
                          _isUpdating
                              ? null
                              : () => Navigator.of(context).pop(),
                      child: const Text('閉じる'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isUpdating ? null : _updateStatus,
                      child:
                          _isUpdating
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('更新'),
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
