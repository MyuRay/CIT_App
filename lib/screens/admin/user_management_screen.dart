import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_management/user_management_model.dart';
import '../../core/providers/user_management_provider.dart';
import 'user_detail_screen.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final _searchController = TextEditingController();
  UserListFilter _currentFilter = defaultUserListFilter;
  bool _showActiveOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider(_currentFilter));
    final statsAsync = ref.watch(userStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ユーザー管理'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // 統計カード
          _buildStatsCard(statsAsync),
          
          // 検索・フィルターエリア
          _buildSearchAndFilters(),
          
          // ユーザーリスト
          Expanded(
            child: usersAsync.when(
              data: (users) => _buildUserList(users),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildErrorWidget(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(AsyncValue<UserStats> statsAsync) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: statsAsync.when(
          data: (stats) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ユーザー統計',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatItem('総ユーザー数', stats.totalUsers.toString(), Colors.blue),
                  _buildStatItem('アクティブ', stats.activeUsers.toString(), Colors.green),
                  _buildStatItem('非アクティブ', stats.inactiveUsers.toString(), Colors.orange),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatItem('今日の登録', stats.todayRegistrations.toString(), Colors.purple),
                  _buildStatItem('今月の登録', stats.monthlyRegistrations.toString(), Colors.teal),
                ],
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

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // 検索バー
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ユーザーを検索（メール、名前、UID）',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _updateFilter();
                      },
                    )
                  : null,
            ),
            onChanged: (_) => _updateFilter(),
          ),
          
          const SizedBox(height: 8),
          
          // フィルター
          Row(
            children: [
              FilterChip(
                label: const Text('アクティブのみ'),
                selected: _showActiveOnly,
                onSelected: (selected) {
                  setState(() {
                    _showActiveOnly = selected;
                  });
                  _updateFilter();
                },
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _refreshData(),
                icon: const Icon(Icons.refresh),
                label: const Text('更新'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<AppUser> users) {
    if (users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('ユーザーが見つかりませんでした'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserTile(user);
      },
    );
  }

  Widget _buildUserTile(AppUser user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isActive ? Colors.green : Colors.red,
          backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
          child: user.photoURL == null
              ? Text(
                  user.displayDisplayName.isNotEmpty
                      ? user.displayDisplayName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(
          user.displayDisplayName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: user.isActive ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email,
              style: TextStyle(
                color: user.isActive ? Colors.grey[600] : Colors.grey,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  '最終ログイン: ${user.lastLoginDisplay}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.person_add,
                  size: 12,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  '登録: ${user.daysSinceCreated}日前',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 管理者バッジ
            FutureBuilder<bool>(
              future: _checkIfAdmin(user.uid),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ADMIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            
            // 状態アイコン
            Icon(
              user.isActive ? Icons.check_circle : Icons.cancel,
              color: user.isActive ? Colors.green : Colors.red,
              size: 20,
            ),
            
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: () => _openUserDetail(user),
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

  Future<bool> _checkIfAdmin(String uid) async {
    try {
      final permissions = await ref.read(userAdminPermissionsProvider(uid).future);
      return permissions?.isAdmin ?? false;
    } catch (e) {
      return false;
    }
  }

  void _updateFilter() {
    setState(() {
      _currentFilter = UserListFilter(
        isActiveFilter: _showActiveOnly ? true : null,
        searchQuery: _searchController.text.trim().isNotEmpty
            ? _searchController.text.trim()
            : null,
      );
    });
  }

  void _refreshData() {
    ref.invalidate(allUsersProvider);
    ref.invalidate(userStatsProvider);
  }

  void _openUserDetail(AppUser user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(user: user),
      ),
    );
  }
}