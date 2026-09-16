import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/in_app_ad_provider.dart';
import '../../core/providers/admin_provider.dart';
import '../../models/ads/ad_management_query.dart';
import '../../models/ads/in_app_ad_model.dart';
import '../../models/bulletin/bulletin_model.dart';
import '../../services/ads/in_app_ad_service.dart';
import '../../widgets/ads/ad_management_card.dart';
import '../../widgets/ads/in_app_ad_creative.dart';
import '../../widgets/ads/in_app_ad_editor_dialog.dart';

class InAppAdManagementScreen extends ConsumerStatefulWidget {
  const InAppAdManagementScreen({super.key});
  @override
  ConsumerState<InAppAdManagementScreen> createState() =>
      _InAppAdManagementScreenState();
}

class _InAppAdManagementScreenState
    extends ConsumerState<InAppAdManagementScreen>
    with WidgetsBindingObserver {
  final _updatingIds = <String>{};
  final _search = TextEditingController();
  AdDeliveryStatus? _status;
  AdPlacement? _placement;
  AdManagementSort _sort = AdManagementSort.status;
  bool _sponsoredOnly = false;
  bool _filtersExpanded = false;
  bool _editorOpen = false;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  @override
  void dispose() {
    _clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _search.dispose();
    super.dispose();
  }

  void _reset() => setState(() {
    _search.clear();
    _status = null;
    _placement = null;
    _sponsoredOnly = false;
    _sort = AdManagementSort.status;
  });

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(currentUserAdminProvider);
    if (admin.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (admin.valueOrNull?.isAdmin != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('広告管理')),
        body: SafeArea(
          child: Center(
            child: Text(admin.hasError ? '管理者権限を確認できませんでした' : '管理者権限が必要です'),
          ),
        ),
      );
    }
    final ads = ref.watch(inAppAdsStreamProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('広告管理'),
        actions: [
          IconButton(
            tooltip: '再読み込み',
            onPressed: () => ref.invalidate(inAppAdsStreamProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ads.when(
          data: _content,
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (_, __) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('広告を読み込めませんでした'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => ref.invalidate(inAppAdsStreamProvider),
                        child: const Text('再試行'),
                      ),
                    ],
                  ),
                ),
              ),
        ),
      ),
    );
  }

  Widget _content(List<InAppAd> ads) {
    final now = DateTime.now();
    final results = queryManagedAds(
      ads,
      now: now,
      search: _search.text,
      status: _status,
      placement: _placement,
      sponsoredOnly: _sponsoredOnly,
      sort: _sort,
    );
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        key: const Key('ad_create'),
                        onPressed: _editorOpen ? null : () => _openAdDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('広告を作成'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _statusFilter(null, 'すべて', ads.length),
                        for (final status in AdDeliveryStatus.values)
                          _statusFilter(
                            status,
                            adStatusLabel(status),
                            ads
                                .where(
                                  (ad) => adDeliveryStatus(ad, now) == status,
                                )
                                .length,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const Key('ad_search'),
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: '広告名・スポンサー名で検索',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: colors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.outlineVariant),
                        ),
                        suffixIcon:
                            _search.text.isEmpty
                                ? null
                                : IconButton(
                                  tooltip: '検索をクリア',
                                  onPressed: () => setState(_search.clear),
                                  icon: const Icon(Icons.close),
                                ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        FilterChip(
                          key: const Key('ad_sponsors'),
                          avatar: const Icon(
                            Icons.workspace_premium_outlined,
                            size: 18,
                          ),
                          label: const Text('スポンサーのみ'),
                          selected: _sponsoredOnly,
                          onSelected:
                              (value) => setState(() => _sponsoredOnly = value),
                        ),
                        TextButton.icon(
                          key: const Key('ad_filters'),
                          onPressed:
                              () => setState(
                                () => _filtersExpanded = !_filtersExpanded,
                              ),
                          icon: Icon(
                            _filtersExpanded ? Icons.expand_less : Icons.tune,
                            size: 18,
                          ),
                          label: const Text('場所・並び順'),
                        ),
                      ],
                    ),
                    if (_filtersExpanded) ...[
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width =
                              constraints.maxWidth >= 620
                                  ? 250.0
                                  : constraints.maxWidth;
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SizedBox(
                                width: width,
                                child: DropdownButtonFormField<AdPlacement?>(
                                  key: ValueKey(
                                    'ad_placement_${_placement?.name ?? 'all'}',
                                  ),
                                  initialValue: _placement,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: '掲載場所',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('すべての場所'),
                                    ),
                                    for (final p in AdPlacement.values)
                                      DropdownMenuItem(
                                        value: p,
                                        child: Text(
                                          adPlacementLabel(p),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                  onChanged:
                                      (value) =>
                                          setState(() => _placement = value),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child:
                                    DropdownButtonFormField<AdManagementSort>(
                                      key: ValueKey('ad_sort_${_sort.name}'),
                                      initialValue: _sort,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: '並び順',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: AdManagementSort.status,
                                          child: Text('掲載状況順'),
                                        ),
                                        DropdownMenuItem(
                                          value: AdManagementSort.endingSoon,
                                          child: Text('終了日時が近い順'),
                                        ),
                                        DropdownMenuItem(
                                          value: AdManagementSort.placement,
                                          child: Text('掲載場所順'),
                                        ),
                                        DropdownMenuItem(
                                          value: AdManagementSort.title,
                                          child: Text('広告名順'),
                                        ),
                                      ],
                                      onChanged:
                                          (value) =>
                                              setState(() => _sort = value!),
                                    ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${results.length}件 / 全${ads.length}件',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                        if (_placement != null && !_filtersExpanded)
                          Text(
                            adPlacementLabel(_placement!),
                            style: TextStyle(color: colors.primary),
                          ),
                        if (_search.text.isNotEmpty ||
                            _status != null ||
                            _placement != null ||
                            _sponsoredOnly)
                          TextButton(
                            onPressed: _reset,
                            child: const Text('絞り込みを解除'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (results.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        size: 48,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(ads.isEmpty ? '登録されている広告はありません' : '条件に合う広告がありません'),
                    ],
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList.builder(
                itemCount: results.length,
                itemBuilder: (_, index) {
                  final ad = results[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: AdManagementCard(
                      key: ValueKey('ad_card_${ad.id}'),
                      ad: ad,
                      now: now,
                      busy: _updatingIds.contains(ad.id),
                      onEdit: () => _openAdDialog(ad: ad),
                      onPreview: () => _preview(ad),
                      onToggle: () => _toggleActive(ad),
                      onDuplicate:
                          () => _openAdDialog(
                            ad: ad.copyWith(
                              id: '',
                              title: '${ad.title}（コピー）',
                              isActive: false,
                            ),
                            duplicate: true,
                          ),
                      onDelete: () => _confirmDelete(ad),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusFilter(AdDeliveryStatus? status, String label, int count) =>
      ChoiceChip(
        key: ValueKey('ad_status_${status?.name ?? 'all'}'),
        label: Text('$label  $count'),
        selected: _status == status,
        onSelected: (_) => setState(() => _status = status),
      );

  Future<void> _preview(InAppAd ad) => showDialog<void>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: const Text('表示プレビュー'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(adPlacementLabel(ad.placement)),
                  const SizedBox(height: 12),
                  InAppAdCreative(ad: ad, margin: EdgeInsets.zero),
                  const SizedBox(height: 12),
                  Text(
                    ad.actionType == AdActionType.external ? 'リンク先' : '掲示板投稿',
                  ),
                  SelectableText(ad.actionPayload),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('閉じる'),
            ),
          ],
        ),
  );

  Future<void> _toggleActive(InAppAd ad) async {
    if (_updatingIds.contains(ad.id)) return;
    setState(() => _updatingIds.add(ad.id));
    try {
      await InAppAdService.setActive(ad.id, !ad.isActive);
      ref.invalidate(inAppAdProvider);
      if (mounted) {
        final next = ad.copyWith(isActive: !ad.isActive);
        final status = adDeliveryStatus(next, DateTime.now());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !next.isActive
                  ? '広告の配信を停止しました'
                  : status == AdDeliveryStatus.ended
                  ? '配信を有効にしました。掲載期間が終了しているため、日時も変更してください。'
                  : status == AdDeliveryStatus.scheduled
                  ? '配信を有効にしました。開始日時から掲載されます。'
                  : '広告の配信を有効にしました',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('配信状態を変更できませんでした')));
      }
    } finally {
      if (mounted) setState(() => _updatingIds.remove(ad.id));
    }
  }

  Future<void> _confirmDelete(InAppAd ad) async {
    if (_updatingIds.contains(ad.id)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('広告を削除'),
            content: Text('「${ad.title}」を削除しますか？この操作は元に戻せません。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('削除する'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted || _updatingIds.contains(ad.id)) return;
    setState(() => _updatingIds.add(ad.id));
    try {
      await InAppAdService.deleteAd(ad.id);
      ref.invalidate(inAppAdProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('広告を削除しました')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('削除できませんでした。再試行してください。')));
      }
    } finally {
      if (mounted) setState(() => _updatingIds.remove(ad.id));
    }
  }

  Future<String?> _pickBulletinPost() => showDialog<String>(
    context: context,
    builder: (_) => const _BulletinPostPickerDialog(),
  );

  Future<void> _openAdDialog({InAppAd? ad, bool duplicate = false}) async {
    if (_editorOpen) return;
    setState(() => _editorOpen = true);
    try {
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => InAppAdEditorDialog(
              ad: ad,
              isDuplicate: duplicate,
              pickBulletin: _pickBulletinPost,
              onSave:
                  (value) =>
                      ad == null || duplicate
                          ? InAppAdService.createAd(value)
                          : InAppAdService.updateAd(ad.id, value),
            ),
      );
      if (saved == true && mounted) {
        ref.invalidate(inAppAdProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('広告を保存しました')));
      }
    } finally {
      if (mounted) setState(() => _editorOpen = false);
    }
  }
}

class _BulletinPostPickerDialog extends ConsumerStatefulWidget {
  const _BulletinPostPickerDialog();

  @override
  ConsumerState<_BulletinPostPickerDialog> createState() =>
      _BulletinPostPickerDialogState();
}

class _BulletinPostPickerDialogState
    extends ConsumerState<_BulletinPostPickerDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _loading = true;
  List<BulletinPost> _posts = [];

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() => _loading = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('bulletin_posts')
              .where('isActive', isEqualTo: true)
              .limit(50)
              .get();
      final list =
          snapshot.docs
              .map(
                (doc) => BulletinPost.fromJson({'id': doc.id, ...doc.data()}),
              )
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!mounted) return;
      setState(() {
        _posts = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('掲示板投稿の取得に失敗しました: $e')));
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered =
        _posts
            .where(
              (post) =>
                  post.title.toLowerCase().contains(_query.toLowerCase()) ||
                  post.authorName.toLowerCase().contains(_query.toLowerCase()),
            )
            .toList();

    return AlertDialog(
      title: const Text('掲示板投稿を選択'),
      content: SizedBox(
        width: 420,
        height: 360,
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'タイトルまたは作者名で検索',
                suffixIcon:
                    _query.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _query = '';
                              _searchCtrl.clear();
                            });
                          },
                        )
                        : null,
              ),
              onChanged: (value) {
                setState(() => _query = value.trim());
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : filtered.isEmpty
                      ? const Center(child: Text('該当する投稿がありません'))
                      : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final post = filtered[index];
                          return ListTile(
                            leading: const Icon(Icons.article_outlined),
                            title: Text(
                              post.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${post.authorName} / ${post.category.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              Navigator.of(
                                context,
                              ).pop('bulletin_posts/${post.id}');
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}
