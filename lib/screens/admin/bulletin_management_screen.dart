import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/bulletin/bulletin_model.dart';
import '../../core/providers/bulletin_provider.dart';
import '../../core/providers/admin_provider.dart';
import 'bulletin_approval_screen.dart';

class BulletinManagementScreen extends ConsumerStatefulWidget {
  const BulletinManagementScreen({super.key});

  @override
  ConsumerState<BulletinManagementScreen> createState() => _BulletinManagementScreenState();
}

class _BulletinManagementScreenState extends ConsumerState<BulletinManagementScreen> {
  // 高機能化: 検索・フィルタ・ソート・一括操作
  String _searchQuery = '';
  String? _categoryFilter; // null=全カテゴリ
  String _statusFilter = 'all'; // all, active, inactive, pinned, expired, pending, approved, rejected
  String _sortKey = 'createdAt'; // createdAt, views
  bool _sortDesc = true;

  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final adminPermissions = ref.watch(currentUserAdminProvider);
    
    return adminPermissions.when(
      data: (permissions) {
        if (permissions?.isAdmin != true) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('アクセス拒否'),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    '管理者権限が必要です',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'この画面にアクセスする権限がありません',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: Text(_selectionMode ? '選択中: ${_selectedIds.length}件' : '掲示板管理'),
            backgroundColor: Colors.green.shade50,
            actions: [
              IconButton(
                icon: const Icon(Icons.pending_actions),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BulletinApprovalScreen(),
                    ),
                  );
                },
                tooltip: '申請管理',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() {});
                },
                tooltip: '更新',
              ),
              IconButton(
                icon: Icon(_selectionMode ? Icons.checklist_rtl : Icons.check_box_outlined),
                onPressed: () {
                  setState(() {
                    _selectionMode = !_selectionMode;
                    if (!_selectionMode) _selectedIds.clear();
                  });
                },
                tooltip: _selectionMode ? '選択終了' : '複数選択',
              ),
              IconButton(
                icon: const Icon(Icons.ios_share),
                onPressed: _exportCurrentView,
                tooltip: 'CSVエクスポート（クリップボード）',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(92),
              child: Column(
                children: [
                  // 検索欄
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: TextField(
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'タイトル・本文・投稿者を検索',
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    ),
                  ),
                  // フィルター行
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: Row(
                      children: [
                        _buildStatusChip('all', '全件', Icons.all_inclusive),
                        _buildStatusChip('active', '公開中', Icons.visibility),
                        _buildStatusChip('inactive', '非公開', Icons.visibility_off),
                        _buildStatusChip('pinned', 'ピン留め', Icons.push_pin),
                        _buildStatusChip('expired', '期限切れ', Icons.timer_off),
                        _buildStatusChip('pending', '承認待ち', Icons.pending_actions),
                        _buildStatusChip('approved', '承認済', Icons.verified),
                        _buildStatusChip('rejected', '却下', Icons.cancel),
                        const SizedBox(width: 8),
                        FilterChip(
                          selected: _categoryFilter == null,
                          label: const Text('全カテゴリ'),
                          avatar: const Icon(Icons.category, size: 16),
                          onSelected: (_) => setState(() => _categoryFilter = null),
                        ),
                        const SizedBox(width: 4),
                        ...BulletinCategories.all.map((c) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: FilterChip(
                                selected: _categoryFilter == c.id,
                                label: Text(c.name, overflow: TextOverflow.ellipsis),
                                onSelected: (_) => setState(() => _categoryFilter = c.id),
                              ),
                            )),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          tooltip: '並び替え',
                          icon: const Icon(Icons.sort),
                          onSelected: (value) {
                            if (value == 'createdAt' || value == 'views') {
                              setState(() => _sortKey = value);
                            } else if (value == 'dir') {
                              setState(() => _sortDesc = !_sortDesc);
                            }
                          },
                          itemBuilder: (context) => [
                            CheckedPopupMenuItem(
                              value: 'createdAt',
                              checked: _sortKey == 'createdAt',
                              child: const Text('作成日時'),
                            ),
                            CheckedPopupMenuItem(
                              value: 'views',
                              checked: _sortKey == 'views',
                              child: const Text('閲覧数'),
                            ),
                            PopupMenuItem(
                              value: 'dir',
                              child: Row(
                                children: [
                                  Icon(_sortDesc ? Icons.south : Icons.north, size: 18),
                                  const SizedBox(width: 8),
                                  Text(_sortDesc ? '降順' : '昇順'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: Stack(
            children: [
              _buildPostsManagement(),
              if (_selectionMode && _selectedIds.isNotEmpty) _buildBulkActionBar(),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('読み込み中...'),
          backgroundColor: Colors.green.shade50,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text('エラー'),
          backgroundColor: Colors.red.shade50,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('エラーが発生しました: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(currentUserAdminProvider);
                },
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostsManagement() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bulletin_posts')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('エラーが発生しました: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('再読み込み'),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final posts = <BulletinPost>[];
        for (final d in docs) {
          try {
            posts.add(BulletinPost.fromJson({'id': d.id, ...d.data() as Map<String, dynamic>}));
          } catch (_) {}
        }

        // 検索・フィルタ
        final filtered = posts.where((p) {
          final q = _searchQuery.toLowerCase();
          final matchesSearch = q.isEmpty ||
              p.title.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q) ||
              p.authorName.toLowerCase().contains(q);
          final matchesCategory = _categoryFilter == null || p.category.id == _categoryFilter;
          final now = DateTime.now();
          final isExpired = p.expiresAt != null && p.expiresAt!.isBefore(now);
          final matchesStatus = () {
            switch (_statusFilter) {
              case 'active':
                return p.isActive;
              case 'inactive':
                return !p.isActive;
              case 'pinned':
                return p.isPinned;
              case 'expired':
                return isExpired;
              case 'pending':
                return p.approvalStatus == 'pending';
              case 'approved':
                return p.approvalStatus == 'approved';
              case 'rejected':
                return p.approvalStatus == 'rejected';
              default:
                return true;
            }
          }();
          return matchesSearch && matchesCategory && matchesStatus;
        }).toList();

        // ソート
        filtered.sort((a, b) {
          int cmp;
          if (_sortKey == 'views') {
            cmp = a.viewCount.compareTo(b.viewCount);
          } else {
            cmp = a.createdAt.compareTo(b.createdAt);
          }
          return _sortDesc ? -cmp : cmp;
        });

        if (filtered.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('条件に一致する投稿がありません', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final post = filtered[index];
              final selected = _selectedIds.contains(post.id);
              return Stack(
                children: [
                  _buildPostCard(post),
                  if (_selectionMode)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Checkbox(
                        value: selected,
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selectedIds.add(post.id);
                          } else {
                            _selectedIds.remove(post.id);
                          }
                        }),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPostCard(BulletinPost post) {
    final now = DateTime.now();
    final isExpired = post.expiresAt != null && post.expiresAt!.isBefore(now);
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
                    post.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handlePostAction(value, post),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 16),
                          SizedBox(width: 8),
                          Text('詳細表示'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
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
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              post.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            // ステータスチップ
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _chip(icon: Icons.category, label: post.category.name),
                if (post.isPinned) _chip(icon: Icons.push_pin, label: 'ピン留め'),
                if (post.pinRequested) _chip(icon: Icons.push_pin_outlined, label: 'ピン申請'),
                if (!post.isActive) _chip(icon: Icons.visibility_off, label: '非公開'),
                if (isExpired) _chip(icon: Icons.timer_off, label: '期限切れ'),
                _chip(icon: Icons.remove_red_eye, label: '閲覧 ${post.viewCount}'),
                _chip(
                  icon: Icons.verified,
                  label: post.approvalStatus == 'approved'
                      ? '承認済'
                      : post.approvalStatus == 'rejected'
                          ? '却下'
                          : '承認待ち',
                ),
                if (post.isCoupon) _chip(icon: Icons.local_offer, label: 'クーポン'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  post.authorName,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatDate(post.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${post.viewCount}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // トグル操作と期限
            Row(
              children: [
                _toggle(
                  label: '公開',
                  value: post.isActive,
                  onChanged: (v) => _updatePost(post.id, {'isActive': v}),
                ),
                const SizedBox(width: 8),
                _toggle(
                  label: 'コメント',
                  value: post.allowComments,
                  onChanged: (v) => _updatePost(post.id, {'allowComments': v}),
                ),
                const SizedBox(width: 8),
                _toggle(
                  label: 'ピン',
                  value: post.isPinned,
                  onChanged: (v) => _updatePost(post.id, {'isPinned': v}),
                ),
                const Spacer(),
                Text(
                  post.expiresAt != null ? '期限: ${_formatDate(post.expiresAt!)}' : '期限: なし',
                  style: TextStyle(fontSize: 12, color: isExpired ? Colors.red : Colors.grey[700]),
                ),
                IconButton(
                  tooltip: '期限を設定',
                  icon: const Icon(Icons.edit_calendar, size: 18),
                  onPressed: () => _pickAndSetExpiry(post),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handlePostAction(String action, BulletinPost post) {
    switch (action) {
      case 'view':
        _showPostDetails(post);
        break;
      case 'delete':
        _showDeleteConfirmation(post);
        break;
    }
  }

  void _showPostDetails(BulletinPost post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(post.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('投稿者: ${post.authorName}'),
              const SizedBox(height: 8),
              Text('投稿日: ${_formatDate(post.createdAt)}'),
              const SizedBox(height: 8),
              Text('閲覧数: ${post.viewCount}'),
              const SizedBox(height: 16),
              const Text(
                '内容:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(post.description),
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

  void _showDeleteConfirmation(BulletinPost post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('投稿削除の確認'),
          ],
        ),
        content: Text('「${post.title}」を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePost(post);
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(BulletinPost post) async {
    try {
      await FirebaseFirestore.instance
          .collection('bulletin_posts')
          .doc(post.id)
          .delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('投稿を削除しました'),
            backgroundColor: Colors.green,
          ),
        );
        
        // プロバイダーを更新
        ref.invalidate(bulletinPostsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('削除に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  bool _canShowMenuForPost(BulletinPost post) {
    // カード部分では三点リーダーを表示しない
    return false;
  }

  // 補助UI
  Widget _chip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _toggle({required String label, required bool value, required ValueChanged<bool> onChanged}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Switch(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: Colors.grey.shade300,
        ),
      ],
    );
  }

  // ステータスChip（ヘッダー行用）
  FilterChip _buildStatusChip(String key, String label, IconData icon) {
    return FilterChip(
      selected: _statusFilter == key,
      label: Text(label),
      avatar: Icon(icon, size: 16),
      onSelected: (_) => setState(() => _statusFilter = key),
    );
  }

  // Firestore更新共通
  Future<void> _updatePost(String id, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('bulletin_posts').doc(id).update(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('更新しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新に失敗しました: $e')),
        );
      }
    }
  }

  // 期限設定
  Future<void> _pickAndSetExpiry(BulletinPost post) async {
    final now = DateTime.now();
    final initial = post.expiresAt ?? now.add(const Duration(days: 7));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (pickedDate != null) {
      final expiresAt = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, initial.hour, initial.minute);
      _updatePost(post.id, {'expiresAt': Timestamp.fromDate(expiresAt)});
    }
  }

  // 一括操作バー
  Widget _buildBulkActionBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        elevation: 8,
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Text('選択中: ${_selectedIds.length}件', style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  tooltip: '公開にする',
                  onPressed: () => _bulkUpdateSelected({'isActive': true}),
                  icon: const Icon(Icons.visibility),
                ),
                IconButton(
                  tooltip: '非公開にする',
                  onPressed: () => _bulkUpdateSelected({'isActive': false}),
                  icon: const Icon(Icons.visibility_off),
                ),
                IconButton(
                  tooltip: 'ピン留め',
                  onPressed: () => _bulkUpdateSelected({'isPinned': true}),
                  icon: const Icon(Icons.push_pin),
                ),
                IconButton(
                  tooltip: 'ピン解除',
                  onPressed: () => _bulkUpdateSelected({'isPinned': false}),
                  icon: const Icon(Icons.push_pin_outlined),
                ),
                IconButton(
                  tooltip: '期限+7日',
                  onPressed: () => _bulkExtendExpiry(const Duration(days: 7)),
                  icon: const Icon(Icons.event_available),
                ),
                IconButton(
                  tooltip: '削除',
                  onPressed: _bulkDeleteSelected,
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _bulkUpdateSelected(Map<String, dynamic> data) async {
    if (_selectedIds.isEmpty) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in _selectedIds) {
        batch.update(FirebaseFirestore.instance.collection('bulletin_posts').doc(id), data);
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('一括更新しました（${_selectedIds.length}件）')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('一括更新に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _bulkExtendExpiry(Duration delta) async {
    if (_selectedIds.isEmpty) return;
    try {
      final ids = _selectedIds.toList();
      for (var i = 0; i < ids.length; i += 10) {
        final end = (i + 10) > ids.length ? ids.length : (i + 10);
        final chunk = ids.sublist(i, end);
        final chunkSnap = await FirebaseFirestore.instance
            .collection('bulletin_posts')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in chunkSnap.docs) {
          DateTime base = DateTime.now();
          final exp = doc.data()['expiresAt'];
          if (exp is Timestamp) base = exp.toDate();
          batch.update(doc.reference, {'expiresAt': Timestamp.fromDate(base.add(delta))});
        }
        await batch.commit();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('期限を延長しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('期限延長に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _bulkDeleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('一括削除の確認'),
            content: Text('${_selectedIds.length}件の投稿を削除します。よろしいですか？\nこの操作は取り消せません。'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('キャンセル')),
              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('削除', style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in _selectedIds) {
        batch.delete(FirebaseFirestore.instance.collection('bulletin_posts').doc(id));
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除しました（${_selectedIds.length}件）')),
        );
      }
      setState(() {
        _selectedIds.clear();
        _selectionMode = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('一括削除に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _exportCurrentView() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('bulletin_posts')
          .orderBy('createdAt', descending: true)
          .get();
      final rows = <String>['title,category,status,isActive,isPinned,createdAt,views'];
      for (final d in snap.docs) {
        try {
          final p = BulletinPost.fromJson({'id': d.id, ...d.data()});
          rows.add([
            _csvSafe(p.title),
            _csvSafe(p.category.name),
            _csvSafe(p.approvalStatus),
            p.isActive ? '1' : '0',
            p.isPinned ? '1' : '0',
            _csvSafe(_formatDate(p.createdAt)),
            p.viewCount.toString(),
          ].join(','));
        } catch (_) {}
      }
      final csv = rows.join('\n');
      await Clipboard.setData(ClipboardData(text: csv));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSVをクリップボードにコピーしました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エクスポートに失敗しました: $e')),
        );
      }
    }
  }

  String _csvSafe(String v) {
    final s = v.replaceAll('"', '""');
    return '"$s"';
  }
}
