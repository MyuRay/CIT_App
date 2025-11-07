import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/in_app_ad_provider.dart';
import '../../models/ads/in_app_ad_model.dart';
import '../../models/bulletin/bulletin_model.dart';
import '../../services/ads/in_app_ad_service.dart';

class InAppAdManagementScreen extends ConsumerStatefulWidget {
  const InAppAdManagementScreen({super.key});

  @override
  ConsumerState<InAppAdManagementScreen> createState() =>
      _InAppAdManagementScreenState();
}

class _InAppAdManagementScreenState
    extends ConsumerState<InAppAdManagementScreen> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final adsAsync = ref.watch(inAppAdsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('広告管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '広告を追加',
            onPressed: () => _openAdDialog(),
          ),
        ],
      ),
      body: adsAsync.when(
        data: (ads) {
          if (ads.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.dynamic_feed,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    const Text('登録されている広告はありません'),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => _openAdDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('広告を作成'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ads.length,
            itemBuilder: (context, index) {
              final ad = ads[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ad.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Switch(
                            value: ad.isActive,
                            onChanged: (_) => _toggleActive(ad),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _InfoChip(
                            label: '配置',
                            value: _placementLabel(ad.placement),
                          ),
                          _InfoChip(
                            label: '動作',
                            value:
                                ad.actionType == AdActionType.external
                                    ? '外部リンク'
                                    : '掲示板',
                          ),
                          _InfoChip(label: '重み', value: ad.weight.toString()),
                          if (ad.startAt != null)
                            _InfoChip(label: '開始', value: _fmt(ad.startAt!)),
                          if (ad.endAt != null)
                            _InfoChip(label: '終了', value: _fmt(ad.endAt!)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ad.body,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _openAdDialog(ad: ad),
                            icon: const Icon(Icons.edit),
                            label: const Text('編集'),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _confirmDelete(ad),
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text('削除'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('広告情報の取得に失敗しました: $err'),
              ),
            ),
      ),
    );
  }

  Future<void> _toggleActive(InAppAd ad) async {
    final updated = ad.copyWith(isActive: !ad.isActive);
    await InAppAdService.updateAd(ad.id, updated);
  }

  Future<void> _confirmDelete(InAppAd ad) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('広告を削除'),
                content: Text('「${ad.title}」を削除しますか？この操作は元に戻せません。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('キャンセル'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('削除する'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await InAppAdService.deleteAd(ad.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('広告「${ad.title}」を削除しました')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('削除に失敗しました: $e')));
      }
    }
  }

  Future<String?> _pickBulletinPost() async {
    return showDialog<String>(
      context: context,
      builder: (context) => const _BulletinPostPickerDialog(),
    );
  }

  Future<void> _openAdDialog({InAppAd? ad}) async {
    final titleCtrl = TextEditingController(text: ad?.title ?? '');
    final bodyCtrl = TextEditingController(text: ad?.body ?? '');
    final imageCtrl = TextEditingController(text: ad?.imageUrl ?? '');
    final ctaCtrl = TextEditingController(text: ad?.ctaText ?? '');
    final actionPayloadCtrl = TextEditingController(
      text: ad?.actionPayload ?? '',
    );

    AdPlacement placement = ad?.placement ?? AdPlacement.homeTop;
    AdActionType actionType = ad?.actionType ?? AdActionType.bulletin;
    bool isActive = ad?.isActive ?? true;
    DateTime? startAt = ad?.startAt;
    DateTime? endAt = ad?.endAt;
    int weight = ad?.weight ?? 1;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(ad == null ? '広告を追加' : '広告を編集'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'タイトル',
                        hintText: '例: 新学期応援キャンペーン',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bodyCtrl,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: '本文',
                        hintText: '広告本文を入力してください',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AdPlacement>(
                      value: placement,
                      decoration: const InputDecoration(labelText: '表示場所'),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => placement = value);
                        }
                      },
                      items:
                          AdPlacement.values
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(_placementLabel(p)),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AdActionType>(
                      value: actionType,
                      decoration: const InputDecoration(labelText: '動作'),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => actionType = value);
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: AdActionType.bulletin,
                          child: Text('掲示板投稿に遷移'),
                        ),
                        DropdownMenuItem(
                          value: AdActionType.external,
                          child: Text('外部リンクを開く'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: actionPayloadCtrl,
                            decoration: InputDecoration(
                              labelText:
                                  actionType == AdActionType.external
                                      ? 'リンクURL'
                                      : '掲示板投稿ID',
                              hintText:
                                  actionType == AdActionType.external
                                      ? 'https://example.com'
                                      : 'bulletin_posts ドキュメントID',
                            ),
                          ),
                        ),
                        if (actionType == AdActionType.bulletin)
                          IconButton(
                            tooltip: '掲示板から選択',
                            onPressed: () async {
                              final selectedId = await _pickBulletinPost();
                              if (selectedId != null && selectedId.isNotEmpty) {
                                actionPayloadCtrl.text = selectedId;
                              }
                            },
                            icon: const Icon(Icons.list_alt),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: imageCtrl,
                      decoration: const InputDecoration(
                        labelText: '画像URL (任意)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ctaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ボタンラベル (任意)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final result = await _pickDateTime(startAt);
                              if (result != null) {
                                setState(() => startAt = result);
                              }
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: Text(
                              startAt == null ? '開始日時' : _fmt(startAt!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final result = await _pickDateTime(endAt);
                              if (result != null) {
                                setState(() => endAt = result);
                              }
                            },
                            icon: const Icon(Icons.stop),
                            label: Text(endAt == null ? '終了日時' : _fmt(endAt!)),
                          ),
                        ),
                        IconButton(
                          tooltip: '日時をクリア',
                          onPressed:
                              () => setState(() {
                                startAt = null;
                                endAt = null;
                              }),
                          icon: const Icon(Icons.clear),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: weight.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '重み (1-10推奨)',
                            ),
                            onChanged: (value) {
                              final parsed = int.tryParse(value);
                              if (parsed != null && parsed > 0) {
                                setState(() => weight = parsed);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('配信状態'),
                            Switch(
                              value: isActive,
                              onChanged:
                                  (value) => setState(() => isActive = value),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      _isSaving
                          ? null
                          : () {
                            Navigator.of(context).pop();
                          },
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed:
                      _isSaving
                          ? null
                          : () async {
                            final title = titleCtrl.text.trim();
                            final body = bodyCtrl.text.trim();
                            final payload = actionPayloadCtrl.text.trim();

                            if (title.isEmpty ||
                                body.isEmpty ||
                                payload.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('タイトル・本文・動作パラメータは必須です'),
                                ),
                              );
                              return;
                            }

                            setState(() => _isSaving = true);
                            final newAd = InAppAd(
                              id: ad?.id ?? '',
                              title: title,
                              body: body,
                              placement: placement,
                              actionType: actionType,
                              actionPayload: payload,
                              isActive: isActive,
                              imageUrl:
                                  imageCtrl.text.trim().isEmpty
                                      ? null
                                      : imageCtrl.text.trim(),
                              ctaText:
                                  ctaCtrl.text.trim().isEmpty
                                      ? null
                                      : ctaCtrl.text.trim(),
                              startAt: startAt,
                              endAt: endAt,
                              weight: weight,
                            );

                            try {
                              if (ad == null) {
                                await InAppAdService.createAd(newAd);
                              } else {
                                await InAppAdService.updateAd(ad.id, newAd);
                              }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ad == null ? '広告を追加しました' : '広告を更新しました',
                                    ),
                                  ),
                                );
                              }
                              if (mounted) {
                                Navigator.of(context).pop();
                              }
                            } catch (e) {
                              setState(() => _isSaving = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('保存に失敗しました: $e')),
                                );
                              }
                            }
                          },
                  child: Text(ad == null ? '追加' : '更新'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? now),
    );
    if (time == null) return DateTime(date.year, date.month, date.day);
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _placementLabel(AdPlacement placement) {
    switch (placement) {
      case AdPlacement.homeTop:
        return 'ホーム最上部';
      case AdPlacement.cafeteria:
        return '学食レビュー';
      case AdPlacement.scheduleBottom:
        return '時間割下部';
      case AdPlacement.profileTop:
        return 'マイページ上部';
    }
  }

  String _fmt(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.85),
    );
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
              .orderBy('createdAt', descending: true)
              .limit(50)
              .get();
      final list =
          snapshot.docs
              .map(
                (doc) => BulletinPost.fromJson({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }),
              )
              .toList();
      setState(() {
        _posts = list;
        _loading = false;
      });
    } catch (e) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
