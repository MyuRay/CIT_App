import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/ad_analytics_provider.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/providers/in_app_ad_provider.dart';
import '../../models/ads/ad_analytics.dart';
import '../../models/ads/ad_audience.dart';
import '../../widgets/ads/in_app_ad_editor_dialog.dart';
import '../../models/ads/in_app_ad_model.dart';

class AdAnalyticsScreen extends ConsumerStatefulWidget {
  const AdAnalyticsScreen({super.key});
  @override
  ConsumerState<AdAnalyticsScreen> createState() => _AdAnalyticsScreenState();
}

class _AdAnalyticsScreenState extends ConsumerState<AdAnalyticsScreen> {
  int _days = 30;
  String? _grade, _adId;
  AdPlacement? _placement;

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(currentUserAdminProvider);
    if (admin.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (admin.valueOrNull?.isAdmin != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('広告分析')),
        body: const Center(child: Text('管理者権限が必要です')),
      );
    }
    final report = ref.watch(adAnalyticsProvider(_days));
    final ads = ref.watch(inAppAdsStreamProvider).valueOrNull ?? [];
    final titles = {for (final ad in ads) ad.id: ad.title};
    return Scaffold(
      appBar: AppBar(
        title: const Text('広告分析'),
        actions: [
          IconButton(
            tooltip: '集計を更新',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adAnalyticsProvider(_days)),
          ),
        ],
      ),
      body: SafeArea(
        child: report.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (_, __) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '集計データを読み込めませんでした。接続とFirestoreルールの反映を確認してください。',
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed:
                            () => ref.invalidate(adAnalyticsProvider(_days)),
                        child: const Text('再試行'),
                      ),
                    ],
                  ),
                ),
              ),
          data: (data) => _content(data, titles),
        ),
      ),
    );
  }

  Widget _filter<T>(
    String label,
    T? value,
    List<DropdownMenuItem<T>> items,
    ValueChanged<T?> onChanged,
  ) => SizedBox(
    width: 250,
    child: DropdownButtonFormField<T>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: items,
      onChanged: onChanged,
    ),
  );

  Widget _content(AdAnalyticsReport report, Map<String, String> titles) {
    final adIds =
        {
            ...titles.keys,
            ...report.events.map((event) => event.adId),
            if (_adId != null) _adId!,
          }.toList()
          ..sort();
    final rows = summarizeAdEvents(
      report.events,
      adId: _adId,
      placement: _placement,
      grade: _grade,
    );
    final impressions = rows.fold(0, (total, row) => total + row.impressions);
    final clicks = rows.fold(0, (total, row) => total + row.clicks);
    final ctr =
        impressions == 0
            ? '—'
            : '${(clicks * 100 / impressions).toStringAsFixed(1)}%';
    String date(DateTime value) {
      final japan = value.toUtc().add(const Duration(hours: 9));
      return '${japan.year}/${japan.month}/${japan.day}';
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final days in [7, 30, 90])
              ChoiceChip(
                label: Text('過去$days日'),
                selected: _days == days,
                onSelected: (_) => setState(() => _days = days),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text('${date(report.from)} 〜 ${date(report.to)}（日本時間）'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _filter<String>('広告', _adId, [
              const DropdownMenuItem(value: null, child: Text('すべての広告')),
              for (final id in adIds)
                DropdownMenuItem(
                  value: id,
                  child: Text(
                    titles[id] ?? '削除済み広告 ($id)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ], (value) => setState(() => _adId = value)),
            _filter<AdPlacement>('掲載場所', _placement, [
              const DropdownMenuItem(value: null, child: Text('すべての場所')),
              for (final p in AdPlacement.values)
                DropdownMenuItem(
                  value: p,
                  child: Text(
                    adPlacementLabel(p),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ], (value) => setState(() => _placement = value)),
            _filter<String>('学年', _grade, [
              const DropdownMenuItem(value: null, child: Text('すべての学年')),
              for (final grade in adGrades)
                DropdownMenuItem(
                  value: grade,
                  child: Text(adGradeLabel(grade)),
                ),
            ], (value) => setState(() => _grade = value)),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                Text('表示数  $impressions'),
                Text('クリック数  $clicks'),
                Text('クリック率  $ctr'),
              ],
            ),
          ),
        ),
        if (report.truncated)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('件数が多いため、期間内の最新5,000件のイベントのみ集計しています。期間を短くして確認してください。'),
          ),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('この条件の記録はまだありません。'),
          )
        else
          _AnalyticsTable(rows: rows, titles: titles),
        const SizedBox(height: 20),
        const Text(
          '学年はメールの入学年度から推定（4月更新）。位置は一覧内の行番号です。表示数はバナーの半分以上が画面内に入った回数で、同じ画面内では1回を記録します。クリックは操作回数です。メールアドレスは保存しません。利用状況データの送信をオフにしている利用者は集計対象外です。計測開始後のデータのみ表示します。',
        ),
      ],
    );
  }
}

class _AnalyticsTable extends StatefulWidget {
  const _AnalyticsTable({required this.rows, required this.titles});
  final List<AdAnalyticsCount> rows;
  final Map<String, String> titles;
  @override
  State<_AnalyticsTable> createState() => _AnalyticsTableState();
}

class _AnalyticsTableState extends State<_AnalyticsTable> {
  late final _source = _CountSource(widget.rows, widget.titles);
  @override
  void didUpdateWidget(covariant _AnalyticsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _source.update(widget.rows, widget.titles);
  }

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PaginatedDataTable(
    rowsPerPage: 10,
    availableRowsPerPage: const [10, 20, 50],
    showEmptyRows: false,
    columns: const [
      DataColumn(label: Text('広告')),
      DataColumn(label: Text('掲載場所')),
      DataColumn(label: Text('位置')),
      DataColumn(label: Text('学年')),
      DataColumn(label: Text('表示数'), numeric: true),
      DataColumn(label: Text('クリック数'), numeric: true),
      DataColumn(label: Text('クリック率'), numeric: true),
    ],
    source: _source,
  );
}

class _CountSource extends DataTableSource {
  _CountSource(this.rows, this.titles);
  List<AdAnalyticsCount> rows;
  Map<String, String> titles;
  void update(List<AdAnalyticsCount> value, Map<String, String> names) {
    rows = value;
    titles = names;
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    if (index >= rows.length) return null;
    final row = rows[index];
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(
          SizedBox(
            width: 170,
            child: Text(
              titles[row.adId] ?? row.adId,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(adPlacementLabel(row.placement))),
        DataCell(Text(row.slotIndex == 0 ? '固定枠' : '一覧位置 ${row.slotIndex}')),
        DataCell(Text(adGradeLabel(row.grade))),
        DataCell(Text('${row.impressions}')),
        DataCell(Text('${row.clicks}')),
        DataCell(
          Text(row.ctr == null ? '—' : '${row.ctr!.toStringAsFixed(1)}%'),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => rows.length;
  @override
  int get selectedRowCount => 0;
}
