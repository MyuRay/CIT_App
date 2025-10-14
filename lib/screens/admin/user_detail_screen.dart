import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_management/user_management_model.dart';
import '../../models/admin/admin_model.dart';
import '../../core/providers/user_management_provider.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  final AppUser user;

  const UserDetailScreen({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final userDetailAsync = ref.watch(userDetailProvider(widget.user.uid));
    final adminPermissionsAsync = ref.watch(userAdminPermissionsProvider(widget.user.uid));
    final userActivitiesAsync = ref.watch(userActivitiesProvider(widget.user.uid));

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.user.displayDisplayName}の詳細'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('ユーザー設定を編集'),
                onTap: () => _showEditDialog(),
              ),
              PopupMenuItem(
                child: Text(
                  widget.user.isActive ? 'ユーザーを無効化' : 'ユーザーを有効化',
                ),
                onTap: () => _toggleUserStatus(),
              ),
              PopupMenuItem(
                child: const Text('管理者権限を編集'),
                onTap: () => _showAdminPermissionsDialog(adminPermissionsAsync.value),
              ),
            ],
          ),
        ],
      ),
      body: userDetailAsync.when(
        data: (user) => user != null 
            ? _buildUserDetail(user, adminPermissionsAsync, userActivitiesAsync)
            : const Center(child: Text('ユーザーが見つかりません')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('エラー: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(userDetailProvider(widget.user.uid)),
                child: const Text('再読み込み'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserDetail(
    AppUser user,
    AsyncValue<AdminPermissions?> adminPermissionsAsync,
    AsyncValue<List<UserActivity>> userActivitiesAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ユーザー基本情報
          _buildBasicInfoCard(user),
          
          const SizedBox(height: 16),
          
          // 管理者権限情報
          _buildAdminPermissionsCard(adminPermissionsAsync),
          
          const SizedBox(height: 16),
          
          // アクティビティ履歴
          _buildActivityHistoryCard(userActivitiesAsync),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard(AppUser user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: user.isActive ? Colors.green : Colors.red,
                  backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                  child: user.photoURL == null
                      ? Text(
                          user.displayDisplayName.isNotEmpty
                              ? user.displayDisplayName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayDisplayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: user.isActive ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          user.isActive ? 'アクティブ' : '無効',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            const Divider(),
            
            const SizedBox(height: 16),
            
            // 詳細情報
            _buildInfoRow('UID', user.uid),
            _buildInfoRow('表示名', user.displayName ?? '未設定'),
            _buildInfoRow('メールアドレス', user.email),
            _buildInfoRow('アカウント作成', _formatDateTime(user.createdAt)),
            _buildInfoRow('最終ログイン', user.lastLoginAt != null 
                ? _formatDateTime(user.lastLoginAt!) 
                : '未ログイン'),
            _buildInfoRow('アカウント日数', '${user.daysSinceCreated}日'),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminPermissionsCard(AsyncValue<AdminPermissions?> adminPermissionsAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.admin_panel_settings, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '管理者権限',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAdminPermissionsDialog(adminPermissionsAsync.value),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('編集'),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            adminPermissionsAsync.when(
              data: (permissions) {
                if (permissions == null) {
                  return const Text(
                    '管理者権限なし',
                    style: TextStyle(color: Colors.grey),
                  );
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPermissionRow('管理者', permissions.isAdmin),
                    _buildPermissionRow('投稿管理', permissions.canManagePosts),
                    _buildPermissionRow('問い合わせ閲覧', permissions.canViewContacts),
                    _buildPermissionRow('ユーザー管理', permissions.canManageUsers),
                    _buildPermissionRow('カテゴリ管理', permissions.canManageCategories),
                    const SizedBox(height: 8),
                    if (permissions.grantedAt != null)
                      Text(
                        '権限付与日: ${_formatDateTime(permissions.grantedAt!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text('権限情報の読み込みエラー: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityHistoryCard(AsyncValue<List<UserActivity>> userActivitiesAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'アクティビティ履歴',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            userActivitiesAsync.when(
              data: (activities) {
                if (activities.isEmpty) {
                  return const Text(
                    'アクティビティ履歴がありません',
                    style: TextStyle(color: Colors.grey),
                  );
                }
                
                return Column(
                  children: activities.take(10).map((activity) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _getActivityIcon(activity.action),
                      title: Text(_getActivityTitle(activity.action)),
                      subtitle: activity.details != null 
                          ? Text(activity.details!) 
                          : null,
                      trailing: Text(
                        _formatDateTime(activity.timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text('履歴の読み込みエラー: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(String permission, bool hasPermission) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            hasPermission ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: hasPermission ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(permission),
        ],
      ),
    );
  }

  Icon _getActivityIcon(String action) {
    switch (action) {
      case 'user_updated':
        return const Icon(Icons.edit, color: Colors.blue);
      case 'user_activated':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'user_deactivated':
        return const Icon(Icons.cancel, color: Colors.red);
      case 'admin_granted':
        return const Icon(Icons.admin_panel_settings, color: Colors.amber);
      case 'admin_revoked':
        return const Icon(Icons.remove_circle, color: Colors.orange);
      default:
        return const Icon(Icons.info, color: Colors.grey);
    }
  }

  String _getActivityTitle(String action) {
    switch (action) {
      case 'user_updated':
        return 'ユーザー情報更新';
      case 'user_activated':
        return 'ユーザー有効化';
      case 'user_deactivated':
        return 'ユーザー無効化';
      case 'admin_granted':
        return '管理者権限付与';
      case 'admin_revoked':
        return '管理者権限取り消し';
      case 'admin_updated':
        return '管理者権限更新';
      default:
        return action;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showEditDialog() {
    final displayNameController = TextEditingController(text: widget.user.displayName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ユーザー情報を編集'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: displayNameController,
              decoration: const InputDecoration(
                labelText: '表示名',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _updateUser({
                'displayName': displayNameController.text.trim(),
              });
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showAdminPermissionsDialog(AdminPermissions? currentPermissions) {
    bool isAdmin = currentPermissions?.isAdmin ?? false;
    bool canManagePosts = currentPermissions?.canManagePosts ?? false;
    bool canViewContacts = currentPermissions?.canViewContacts ?? false;
    bool canManageUsers = currentPermissions?.canManageUsers ?? false;
    bool canManageCategories = currentPermissions?.canManageCategories ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('管理者権限を編集'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text('管理者権限'),
                subtitle: const Text('基本的な管理者機能へのアクセス'),
                value: isAdmin,
                onChanged: (value) => setState(() => isAdmin = value ?? false),
              ),
              CheckboxListTile(
                title: const Text('投稿管理'),
                subtitle: const Text('掲示板の投稿を管理する権限'),
                value: canManagePosts,
                onChanged: isAdmin ? (value) => setState(() => canManagePosts = value ?? false) : null,
              ),
              CheckboxListTile(
                title: const Text('問い合わせ閲覧'),
                subtitle: const Text('ユーザーからの問い合わせを閲覧する権限'),
                value: canViewContacts,
                onChanged: isAdmin ? (value) => setState(() => canViewContacts = value ?? false) : null,
              ),
              CheckboxListTile(
                title: const Text('ユーザー管理'),
                subtitle: const Text('他のユーザーを管理する権限'),
                value: canManageUsers,
                onChanged: isAdmin ? (value) => setState(() => canManageUsers = value ?? false) : null,
              ),
              CheckboxListTile(
                title: const Text('カテゴリ管理'),
                subtitle: const Text('投稿カテゴリを管理する権限'),
                value: canManageCategories,
                onChanged: isAdmin ? (value) => setState(() => canManageCategories = value ?? false) : null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            if (currentPermissions?.isAdmin == true)
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _revokeAdminPermission();
                },
                child: const Text('権限取り消し', style: TextStyle(color: Colors.red)),
              ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (isAdmin) {
                  await _updateAdminPermissions(
                    canManagePosts: canManagePosts,
                    canViewContacts: canViewContacts,
                    canManageUsers: canManageUsers,
                    canManageCategories: canManageCategories,
                  );
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateUser(Map<String, dynamic> updates) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(userManagementActionsProvider).updateUser(widget.user.uid, updates);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ユーザー情報を更新しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleUserStatus() async {
    setState(() => _isLoading = true);
    try {
      if (widget.user.isActive) {
        await ref.read(userManagementActionsProvider).deactivateUser(widget.user.uid);
      } else {
        await ref.read(userManagementActionsProvider).activateUser(widget.user.uid);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.user.isActive ? 'ユーザーを無効化しました' : 'ユーザーを有効化しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateAdminPermissions({
    required bool canManagePosts,
    required bool canViewContacts,
    required bool canManageUsers,
    required bool canManageCategories,
  }) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(userManagementActionsProvider).grantAdminPermission(
        widget.user.uid,
        canManagePosts: canManagePosts,
        canViewContacts: canViewContacts,
        canManageUsers: canManageUsers,
        canManageCategories: canManageCategories,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('管理者権限を更新しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('権限更新に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _revokeAdminPermission() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(userManagementActionsProvider).revokeAdminPermission(widget.user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('管理者権限を取り消しました'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('権限取り消しに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}