import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/admin/admin_model.dart';
import '../../core/providers/contact_provider.dart';
import '../../core/providers/admin_provider.dart';
import '../../services/contact/contact_service.dart';
import 'contact_detail_screen.dart';

class ContactManagementScreen extends ConsumerStatefulWidget {
  final bool showAppBar;
  
  const ContactManagementScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  ConsumerState<ContactManagementScreen> createState() => _ContactManagementScreenState();
}

class _ContactManagementScreenState extends ConsumerState<ContactManagementScreen> {
  ContactFilter _currentFilter = defaultContactFilter;
  String? _selectedStatus;
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final adminPermissions = ref.watch(currentUserAdminProvider);
    
    return adminPermissions.when(
      data: (permissions) {
        if (permissions?.isAdmin != true) {
          return Scaffold(
            appBar: widget.showAppBar ? AppBar(
              title: const Text('アクセス拒否'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ) : null,
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'お問い合わせ閲覧権限が必要です',
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
        
        return _buildContactManagementContent();
      },
      loading: () => Scaffold(
        appBar: widget.showAppBar ? AppBar(
          title: const Text('読み込み中...'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ) : null,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: widget.showAppBar ? AppBar(
          title: const Text('エラー'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ) : null,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('エラーが発生しました: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('戻る'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactManagementContent() {
    final contactsAsync = ref.watch(allContactsProvider(_currentFilter));
    final statsAsync = ref.watch(contactStatsProvider);

    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
        title: const Text('お問い合わせ管理'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshData(),
            tooltip: '更新',
          ),
        ],
      ) : null,
      body: Column(
        children: [
          // 統計カード
          _buildStatsCard(statsAsync),
          
          // フィルターエリア
          _buildFilters(),
          
          // お問い合わせリスト
          Expanded(
            child: contactsAsync.when(
              data: (contacts) => _buildContactList(contacts),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildErrorWidget(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(AsyncValue<ContactStats> statsAsync) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: statsAsync.when(
          data: (stats) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'お問い合わせ統計',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatItem('総件数', stats.totalCount.toString(), Colors.blue),
                  _buildStatItem('未対応', stats.pendingCount.toString(), Colors.orange),
                  _buildStatItem('対応中', stats.inProgressCount.toString(), Colors.purple),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatItem('解決済み', stats.resolvedCount.toString(), Colors.green),
                  _buildStatItem('今日', stats.todayCount.toString(), Colors.teal),
                  _buildStatItem('今週', stats.weekCount.toString(), Colors.indigo),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('解決率'),
                    Text(
                      '${stats.responseRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: stats.responseRate > 80 ? Colors.green : 
                               stats.responseRate > 60 ? Colors.orange : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Text('統計の読み込みに失敗しました: $error'),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              // ステータスフィルター
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'ステータス',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  value: _selectedStatus,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('すべて')),
                    const DropdownMenuItem(value: 'pending', child: Text('未対応')),
                    const DropdownMenuItem(value: 'in_progress', child: Text('対応中')),
                    const DropdownMenuItem(value: 'resolved', child: Text('解決済み')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                      _updateFilter();
                    });
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              // カテゴリフィルター
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'カテゴリ',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  value: _selectedCategory,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('すべて')),
                    ...ContactCategories.categories.entries.map((entry) =>
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text('${ContactCategories.getIcon(entry.key)} ${entry.value}'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                      _updateFilter();
                    });
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _clearFilters(),
                icon: const Icon(Icons.clear),
                label: const Text('フィルターをクリア'),
              ),
              const Spacer(),
              Consumer(
                builder: (context, ref, child) {
                  final contactsAsync = ref.watch(allContactsProvider(_currentFilter));
                  return Text(
                    '${contactsAsync.value?.length ?? 0}件',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactList(List<ContactForm> contacts) {
    if (contacts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('お問い合わせがありません'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return _buildContactTile(contact);
      },
    );
  }

  Widget _buildContactTile(ContactForm contact) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openContactDetail(contact),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // カテゴリアイコン
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getStatusColor(contact.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: _getStatusColor(contact.status).withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    _getCategoryIcon(contact.category),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // コンテンツ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // タイトル
                    Text(
                      contact.subject.isNotEmpty ? contact.subject : 'タイトルなし',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // 送信者とカテゴリ
                    Text(
                      '${(contact.name?.isNotEmpty == true) ? contact.name : '不明'} (${contact.categoryName})',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // ステータスと日時
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(contact.status),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getStatusDisplayName(contact.status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (contact.response != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '返信済み',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Text(
                          _formatDateTime(contact.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 矢印アイコン
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('エラーが発生しました: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _refreshData(),
            child: const Text('再読み込み'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _updateFilter() {
    setState(() {
      _currentFilter = ContactFilter(
        statusFilter: _selectedStatus,
        categoryFilter: _selectedCategory,
      );
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedCategory = null;
      _currentFilter = defaultContactFilter;
    });
  }

  void _refreshData() {
    ref.invalidate(allContactsProvider);
    ref.invalidate(contactStatsProvider);
  }

  void _openContactDetail(ContactForm contact) {
    if (contact.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('お問い合わせIDが無効です'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContactDetailScreen(contact: contact),
      ),
    );
  }

  // Null安全性のためのヘルパーメソッド
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.purple;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(String? status) {
    switch (status) {
      case 'pending':
        return '未対応';
      case 'in_progress':
        return '対応中';
      case 'resolved':
        return '解決済み';
      default:
        return '不明';
    }
  }

  String _getCategoryIcon(String? category) {
    return ContactCategories.getIcon(category ?? 'other');
  }
}
