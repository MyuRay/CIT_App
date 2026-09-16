import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/providers/admin_dashboard_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/admin/admin_destination.dart';
import '../../widgets/admin/admin_access_gate.dart';
import '../../widgets/admin/admin_list_components.dart';
import 'admin_destination_page.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with WidgetsBindingObserver {
  final _search = TextEditingController();
  AdminCategory? _category;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    if (_refreshing ||
        ref.read(currentUserAdminProvider).asData?.value?.isAdmin != true)
      return;
    _refreshing = true;
    try {
      await Future.wait(
        AdminQueue.values.map((queue) async {
          ref.invalidate(adminQueueCountProvider(queue));
          try {
            await ref.read(adminQueueCountProvider(queue).future);
          } catch (_) {
            /* Each tile offers retry. */
          }
        }),
      );
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _open(
    AdminDestination destination, {
    bool pendingOnly = false,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => AdminDestinationPage(
              destination: destination,
              pendingOnly: pendingOnly,
            ),
      ),
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) =>
      AdminAccessGate(title: '管理センター', builder: _content);

  Widget _content(BuildContext context) {
    final uid = ref.watch(currentUserAdminProvider).requireValue!.userId;
    final favorites = ref.watch(adminFavoriteToolsProvider(uid));
    final visible =
        AdminDestination.values
            .where(
              (tool) =>
                  (_category == null || tool.category == _category) &&
                  tool.matches(_search.text),
            )
            .toList();
    final searching = _search.text.trim().isNotEmpty || _category != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理センター'),
        actions: [
          IconButton(
            tooltip: '対応待ち件数を更新',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '対応待ち',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide =
                      constraints.maxWidth >= 340 &&
                      MediaQuery.textScalerOf(context).scale(14) <= 18;
                  final width =
                      wide
                          ? (constraints.maxWidth - 20) / 3
                          : constraints.maxWidth;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final queue in AdminQueue.values)
                        SizedBox(width: width, child: _queueTile(queue)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 6),
              Text(
                '件数は取得時点の情報です。下に引いて更新できます。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              if (!searching && favorites.isNotEmpty) ...[
                Text(
                  'よく使う機能',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final tool in AdminDestination.values.where(
                      (tool) => favorites.contains(tool.name),
                    ))
                      ActionChip(
                        avatar: Icon(tool.icon, size: 18),
                        label: Text(tool.title),
                        onPressed: () => _open(tool),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              AdminSearchField(
                controller: _search,
                hint: '機能を検索（スポンサー・時刻表など）',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('すべて'),
                        selected: _category == null,
                        onSelected: (_) => setState(() => _category = null),
                      ),
                    ),
                    for (final category in AdminCategory.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category.label),
                          selected: _category == category,
                          onSelected:
                              (_) => setState(() => _category = category),
                        ),
                      ),
                  ],
                ),
              ),
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      const Text('一致する機能がありません'),
                      TextButton(
                        onPressed:
                            () => setState(() {
                              _search.clear();
                              _category = null;
                            }),
                        child: const Text('検索条件をクリア'),
                      ),
                    ],
                  ),
                ),
              for (final category in AdminCategory.values)
                if (visible.any((tool) => tool.category == category)) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 22, bottom: 10),
                    child: Text(
                      category.label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  for (final tool in visible.where(
                    (tool) => tool.category == category,
                  ))
                    _toolTile(tool, favorites.contains(tool.name), uid),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _queueTile(AdminQueue queue) {
    final count = ref.watch(adminQueueCountProvider(queue));
    final color =
        queue == AdminQueue.approvals
            ? Colors.amber.shade800
            : queue == AdminQueue.contacts
            ? Colors.blue
            : Colors.deepOrange;
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.tintedSurface(context, color),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _open(queue.destination, pendingOnly: true),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                queue.destination.icon,
                color: AppColors.accent(context, color),
                size: 20,
              ),
              const SizedBox(height: 8),
              Text(queue.label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              count.when(
                skipLoadingOnRefresh: false,
                data:
                    (value) => Text(
                      '$value件',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                loading: () => const Text('確認中…'),
                error:
                    (_, __) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('取得できません'),
                        TextButton(
                          onPressed:
                              () => ref.invalidate(
                                adminQueueCountProvider(queue),
                              ),
                          child: const Text('再試行'),
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

  Widget _toolTile(AdminDestination tool, bool favorite, String uid) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
            leading: Icon(
              tool.icon,
              color:
                  tool == AdminDestination.ads
                      ? AppColors.accent(context, Colors.amber.shade800)
                      : Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              tool.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(tool.description),
            onTap: () => _open(tool),
          ),
        ),
        IconButton(
          tooltip:
              favorite ? '${tool.title}をよく使う機能から外す' : '${tool.title}をよく使う機能に追加',
          icon: Icon(
            favorite ? Icons.star_rounded : Icons.star_outline_rounded,
          ),
          color:
              favorite
                  ? AppColors.accent(context, Colors.amber.shade800)
                  : null,
          onPressed: () async {
            try {
              await ref
                  .read(adminFavoriteToolsProvider(uid).notifier)
                  .toggle(tool);
            } catch (_) {
              if (mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('保存できませんでした。再試行してください。')),
                );
            }
          },
        ),
      ],
    ),
  );
}
