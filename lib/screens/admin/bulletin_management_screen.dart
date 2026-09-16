import '../../widgets/bulletin/bulletin_image_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/providers/bulletin_provider.dart';
import '../../models/bulletin/bulletin_model.dart';
import '../../models/bulletin/bulletin_management_query.dart';
import '../../services/bulletin/bulletin_admin_service.dart';
import '../../widgets/ads/sponsor_presentation.dart';
import '../../widgets/bulletin/bulletin_settings_dialog.dart';
import '../bulletin/bulletin_post_form_screen.dart';
import 'bulletin_approval_screen.dart';

class BulletinManagementScreen extends ConsumerStatefulWidget {
  const BulletinManagementScreen({super.key});
  @override
  ConsumerState<BulletinManagementScreen> createState() =>
      _BulletinManagementScreenState();
}

class _BulletinManagementScreenState
    extends ConsumerState<BulletinManagementScreen> {
  final _search = TextEditingController();
  BulletinStatusFilter _status = BulletinStatusFilter.all;
  BulletinSort _sort = BulletinSort.newest;
  String? _category;
  bool _selecting = false;
  bool _busy = false;
  final _selected = <String>{};
  List<BulletinPost> _visible = [];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _filter(VoidCallback update) => setState(() {
    update();
    _selected.clear();
  });

  List<String> get _visibleSelection =>
      _visible
          .where((post) => _selected.contains(post.id))
          .map((post) => post.id)
          .toList();

  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _operate(
    Future<void> Function() operation,
    String success,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await operation();
      if (!mounted) return;
      setState(() => _selected.clear());
      _message(success);
      ref.invalidate(bulletinFeedProvider);
    } catch (_) {
      _message('変更できませんでした。通信状態と管理者権限を確認して再試行してください。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(adminBulletinPostsProvider);
    await ref.read(adminBulletinPostsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(currentUserAdminProvider);
    return permissions.when(
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (_, __) => Scaffold(
            appBar: AppBar(title: const Text('掲示板管理')),
            body: Center(
              child: FilledButton(
                onPressed: () => ref.invalidate(currentUserAdminProvider),
                child: const Text('管理者権限を再確認'),
              ),
            ),
          ),
      data: (admin) {
        if (admin?.isAdmin != true) {
          return Scaffold(
            appBar: AppBar(title: const Text('掲示板管理')),
            body: const Center(child: Text('管理者権限が必要です')),
          );
        }
        final postsAsync = ref.watch(adminBulletinPostsProvider);
        final posts = postsAsync.valueOrNull ?? <BulletinPost>[];
        final now = DateTime.now();
        _visible = queryManagedBulletins(
          posts,
          now: now,
          search: _search.text,
          categoryId: _category,
          status: _status,
          sort: _sort,
        );
        final selected = _visibleSelection;
        return Scaffold(
          appBar: AppBar(
            title: const Text('掲示板管理'),
            actions: [
              IconButton(
                tooltip: '投稿を作成',
                icon: const Icon(Icons.add),
                onPressed: _busy ? null : () => _edit(),
              ),
              PopupMenuButton<String>(
                enabled: !_busy,
                tooltip: '管理メニュー',
                onSelected: (value) {
                  switch (value) {
                    case 'selection':
                      setState(() {
                        _selecting = !_selecting;
                        _selected.clear();
                      });
                    case 'csv':
                      _export();
                    case 'refresh':
                      _refresh();
                  }
                },
                itemBuilder:
                    (_) => [
                      PopupMenuItem(
                        value: 'selection',
                        child: Text(_selecting ? '複数選択を終了' : '複数選択'),
                      ),
                      const PopupMenuItem(
                        value: 'csv',
                        child: Text('表示中の投稿をCSVコピー'),
                      ),
                      const PopupMenuItem(
                        value: 'refresh',
                        child: Text('再読み込み'),
                      ),
                    ],
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            bottom: false,
            child: postsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (_, __) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('投稿を読み込めませんでした'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _refresh,
                            child: const Text('再読み込み'),
                          ),
                        ],
                      ),
                    ),
                  ),
              data:
                  (_) => RefreshIndicator(
                    onRefresh: _refresh,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _overview(posts, now),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _search,
                                  onChanged: (_) => _filter(() {}),
                                  decoration: InputDecoration(
                                    hintText: 'タイトル・投稿者・スポンサーを検索',
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon:
                                        _search.text.isEmpty
                                            ? null
                                            : IconButton(
                                              tooltip: '検索をクリア',
                                              icon: const Icon(Icons.close),
                                              onPressed:
                                                  () => _filter(_search.clear),
                                            ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      for (final status
                                          in BulletinStatusFilter.values)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: ChoiceChip(
                                            label: Text(status.label),
                                            selected: _status == status,
                                            onSelected:
                                                (_) => _filter(
                                                  () => _status = status,
                                                ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final scale =
                                        MediaQuery.textScalerOf(
                                          context,
                                        ).scale(14) /
                                        14;
                                    final width =
                                        constraints.maxWidth < 340 ||
                                                scale > 1.3
                                            ? constraints.maxWidth
                                            : (constraints.maxWidth - 12) / 2;
                                    return Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        SizedBox(
                                          width: width,
                                          child: DropdownButtonFormField<
                                            String
                                          >(
                                            initialValue: _category ?? '',
                                            isExpanded: true,
                                            decoration: const InputDecoration(
                                              labelText: 'カテゴリ',
                                              border: OutlineInputBorder(),
                                            ),
                                            items: [
                                              const DropdownMenuItem(
                                                value: '',
                                                child: Text('すべてのカテゴリ'),
                                              ),
                                              for (final category
                                                  in BulletinCategories.all)
                                                DropdownMenuItem(
                                                  value: category.id,
                                                  child: Text(
                                                    category.name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                            ],
                                            onChanged:
                                                (value) => _filter(
                                                  () =>
                                                      _category =
                                                          value == ''
                                                              ? null
                                                              : value,
                                                ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: width,
                                          child: DropdownButtonFormField<
                                            BulletinSort
                                          >(
                                            initialValue: _sort,
                                            isExpanded: true,
                                            decoration: const InputDecoration(
                                              labelText: '並び順',
                                              border: OutlineInputBorder(),
                                            ),
                                            items: [
                                              for (final sort
                                                  in BulletinSort.values)
                                                DropdownMenuItem(
                                                  value: sort,
                                                  child: Text(
                                                    sort.label,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                            ],
                                            onChanged:
                                                (value) => _filter(
                                                  () =>
                                                      _sort =
                                                          value ??
                                                          BulletinSort.newest,
                                                ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  spacing: 12,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      '${_visible.length}件 / 全${posts.length}件',
                                    ),
                                    TextButton.icon(
                                      onPressed:
                                          _busy
                                              ? null
                                              : () => setState(() {
                                                _selecting = !_selecting;
                                                _selected.clear();
                                              }),
                                      icon: Icon(
                                        _selecting
                                            ? Icons.close
                                            : Icons.checklist,
                                      ),
                                      label: Text(
                                        _selecting ? '選択を終了' : '複数選択',
                                      ),
                                    ),
                                    if (_selecting)
                                      TextButton(
                                        onPressed:
                                            _busy
                                                ? null
                                                : () => setState(() {
                                                  if (selected.length ==
                                                      _visible.length) {
                                                    _selected.clear();
                                                  } else {
                                                    _selected.addAll(
                                                      _visible
                                                          .take(
                                                            BulletinAdminService
                                                                .selectionLimit,
                                                          )
                                                          .map((p) => p.id),
                                                    );
                                                  }
                                                }),
                                        child: Text(
                                          selected.length == _visible.length
                                              ? '選択を解除'
                                              : '表示中を選択（最大400件）',
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_visible.isEmpty)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                '条件に一致する投稿がありません',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList.builder(
                            itemCount: _visible.length,
                            itemBuilder:
                                (_, index) => _postCard(_visible[index], now),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: MediaQuery.paddingOf(context).bottom + 24,
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
          ),
          bottomNavigationBar: _selecting ? _bulkBar(selected) : null,
        );
      },
    );
  }

  Widget _overview(List<BulletinPost> posts, DateTime now) {
    final theme = Theme.of(context);
    final statuses = [
      BulletinStatusFilter.published,
      BulletinStatusFilter.pending,
      BulletinStatusFilter.sponsored,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
            final width =
                scale > 1.3
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 16) / 3;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in statuses)
                  SizedBox(
                    width: width,
                    child: Material(
                      color:
                          status == BulletinStatusFilter.sponsored
                              ? SponsorPalette.of(context).surface
                              : theme.colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color:
                              status == BulletinStatusFilter.sponsored
                                  ? SponsorPalette.of(context).border
                                  : theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _filter(() => _status = status),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                status.label,
                                style: theme.textTheme.labelMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${posts.where((post) => status.matches(post, now)).length}件',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        TextButton.icon(
          onPressed:
              _busy
                  ? null
                  : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BulletinApprovalScreen(),
                    ),
                  ),
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('投稿・ピン留めの申請を確認'),
        ),
      ],
    );
  }

  Widget _postCard(BulletinPost post, DateTime now) {
    final theme = Theme.of(context);
    final published = post.isPublishedAt(now);
    final expired = BulletinStatusFilter.expired.matches(post, now);
    return Card(
      key: ValueKey('managed-${post.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              post.isSponsored
                  ? SponsorPalette.of(context).border
                  : theme.colorScheme.outlineVariant,
          width: post.isSponsored ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.isSponsored) SponsorBanner(name: post.sponsorName),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selecting)
                      Checkbox(
                        value: _selected.contains(post.id),
                        onChanged:
                            _busy
                                ? null
                                : (value) => setState(() {
                                  if (value == true) {
                                    if (_visibleSelection.length <
                                        BulletinAdminService.selectionLimit) {
                                      _selected.add(post.id);
                                    } else {
                                      _message('一度に選択できるのは400件までです');
                                    }
                                  } else {
                                    _selected.remove(post.id);
                                  }
                                }),
                      ),
                    Expanded(
                      child: Text(
                        post.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      enabled: !_busy,
                      tooltip: '投稿の操作',
                      onSelected: (value) {
                        if (value == 'edit') _edit(post);
                        if (value == 'delete') _delete([post.id]);
                      },
                      itemBuilder:
                          (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('投稿内容を編集'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('投稿を削除'),
                            ),
                          ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _badge(
                      published
                          ? '公開中'
                          : !post.isActive
                          ? '非公開'
                          : expired
                          ? '期限切れ'
                          : post.approvalStatus == 'rejected'
                          ? '却下'
                          : '承認待ち',
                    ),
                    _badge(post.category.name),
                    if (post.isPinned) _badge('ピン留め'),
                    if (post.pinRequested) _badge('ピン申請あり'),
                    if (post.isCoupon) _badge('クーポン'),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  post.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Text(post.authorName, style: theme.textTheme.bodySmall),
                    Text(
                      '${post.viewCount}回閲覧',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '投稿 ${_date(post.createdAt)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  post.expiresAt == null
                      ? '掲載期限なし'
                      : '掲載終了 ${_date(post.expiresAt!, time: true)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: expired ? theme.colorScheme.error : null,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _busy ? null : () => _settings(post),
                      icon: const Icon(Icons.tune, size: 18),
                      label: const Text('掲載設定'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _preview(post),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('プレビュー'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label, style: Theme.of(context).textTheme.labelSmall),
  );

  Future<void> _settings(BulletinPost post) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => BulletinSettingsDialog(
            post: post,
            onSave:
                ({
                  required isSponsored,
                  required sponsorName,
                  required isActive,
                  required isPinned,
                  required allowComments,
                  required expiresAt,
                }) => ref
                    .read(bulletinAdminServiceProvider)
                    .saveSettings(
                      post.id,
                      isSponsored: isSponsored,
                      sponsorName: sponsorName,
                      isActive: isActive,
                      isPinned: isPinned,
                      allowComments: allowComments,
                      expiresAt: expiresAt,
                    ),
          ),
    );
    if (saved == true && mounted) {
      ref.invalidate(bulletinFeedProvider);
      _message('掲載設定を保存しました');
    }
  }

  Future<void> _edit([BulletinPost? post]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                post == null
                    ? const BulletinPostFormScreen()
                    : BulletinPostEditScreen(post: post),
      ),
    );
    if (saved == true && mounted) ref.invalidate(bulletinFeedProvider);
  }

  void _preview(BulletinPost post) {
    showDialog<void>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('表示プレビュー'),
            content: SizedBox(
              width: 480,
              height: MediaQuery.sizeOf(context).height * 0.6,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (post.isSponsored) SponsorBanner(name: post.sponsorName),
                    BulletinImageGallery(imageUrls: post.galleryImageUrls),
                    Text(
                      post.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(post.description),
                    const SizedBox(height: 12),
                    Text(post.authorName),
                  ],
                ),
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

  Widget _bulkBar(List<String> selected) => Material(
    elevation: 3,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Text(_busy ? '処理中…' : '${selected.length}件を選択中'),
            PopupMenuButton<String>(
              enabled: !_busy && selected.isNotEmpty,
              tooltip: '選択した投稿を操作',
              onSelected: (action) => _bulkAction(action, List.of(selected)),
              itemBuilder:
                  (_) => const [
                    PopupMenuItem(value: 'active', child: Text('掲載を有効にする')),
                    PopupMenuItem(value: 'inactive', child: Text('非公開にする')),
                    PopupMenuItem(value: 'pin', child: Text('ピン留めする')),
                    PopupMenuItem(value: 'unpin', child: Text('ピン留めを解除する')),
                    PopupMenuItem(value: 'extend', child: Text('掲載期限を7日延長する')),
                    PopupMenuItem(value: 'delete', child: Text('削除する')),
                  ],
              child: Chip(
                label: const Text('一括操作'),
                avatar: const Icon(Icons.expand_more),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _bulkAction(String action, List<String> ids) {
    final service = ref.read(bulletinAdminServiceProvider);
    if (action == 'delete') {
      _delete(ids);
      return;
    }
    if (action == 'extend') {
      _operate(
        () => service.extendExpiry(ids, DateTime.now()),
        '掲載期限を7日延長しました',
      );
      return;
    }
    final patch = switch (action) {
      'active' => {'isActive': true},
      'inactive' => {'isActive': false},
      'pin' => {'isPinned': true},
      'unpin' => {'isPinned': false},
      _ => <String, dynamic>{},
    };
    if (patch.isNotEmpty)
      _operate(() => service.bulkUpdate(ids, patch), '${ids.length}件を更新しました');
  }

  Future<void> _delete(List<String> ids) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('投稿を削除'),
            content: Text('${ids.length}件の投稿を削除します。この操作は取り消せません。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('削除'),
              ),
            ],
          ),
    );
    if (confirmed == true && mounted) {
      await _operate(
        () => ref.read(bulletinAdminServiceProvider).deletePosts(ids),
        '${ids.length}件を削除しました',
      );
    }
  }

  Future<void> _export() async {
    final posts = List<BulletinPost>.of(_visible);
    try {
      await Clipboard.setData(
        ClipboardData(text: bulletinManagementCsv(posts)),
      );
      _message('表示中の${posts.length}件をCSVにコピーしました');
    } catch (_) {
      _message('CSVをコピーできませんでした');
    }
  }

  String _date(DateTime date, {bool time = false}) {
    final local = date.toLocal();
    final day = '${local.year}/${local.month}/${local.day}';
    return time
        ? '$day ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}'
        : day;
  }
}
