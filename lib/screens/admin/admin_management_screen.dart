import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/admin/admin_model.dart';
import '../../core/providers/bulletin_provider.dart';
import '../../core/providers/comment_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/providers/notification_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'contact_management_screen.dart';
import 'user_management_screen.dart';
import 'bus_management_screen.dart';
import 'cafeteria_management_screen.dart';
import '../reports/report_management_screen.dart';

class AdminManagementScreen extends ConsumerStatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  ConsumerState<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends ConsumerState<AdminManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _userIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminPermissions = ref.watch(currentUserAdminProvider);
    
    return adminPermissions.when(
      data: (permissions) {
        if (permissions?.isAdmin != true) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('アクセス拒否'),
              backgroundColor: Colors.red.shade50,
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
            title: const Text('管理者ダッシュボード'),
            backgroundColor: Colors.red.shade50,
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard), text: 'ダッシュボード'),
                Tab(icon: Icon(Icons.article), text: '投稿管理'),
                Tab(icon: Icon(Icons.people), text: 'ユーザー'),
                Tab(icon: Icon(Icons.flag), text: '通報管理'),
                Tab(icon: Icon(Icons.help_center), text: 'お問い合わせ'),
                Tab(icon: Icon(Icons.notification_important), text: '通知管理'),
                Tab(icon: Icon(Icons.restaurant_menu), text: '学食管理'),
                Tab(icon: Icon(Icons.directions_bus), text: '学バス管理'),
                Tab(icon: Icon(Icons.admin_panel_settings), text: '管理者設定'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildDashboardTab(),
              _buildPostsManagementTab(),
              _buildUsersManagementTab(),
              _buildReportManagementTab(),
              _buildContactManagementTab(),
              _buildNotificationManagementTab(),
              _buildCafeteriaManagementTab(),
              _buildBusManagementTab(),
              _buildAdminSettingsTab(),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('読み込み中...'),
          backgroundColor: Colors.red.shade50,
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
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('戻る'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ダッシュボードタブ
  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // システム統計カード
          _buildSystemStatsCard(),
          const SizedBox(height: 16),
          
          // 最近のアクティビティ
          _buildRecentActivityCard(),
          const SizedBox(height: 16),
          
          // クイックアクション
          _buildQuickActionsCard(),
        ],
      ),
    );
  }

  // システム統計カード
  Widget _buildSystemStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'システム統計',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.article,
                    title: '投稿数',
                    value: _getPostsCount(),
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.comment,
                    title: 'コメント数',
                    value: _getCommentsCount(),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.people,
                    title: 'ユーザー数',
                    value: _getUsersCount(),
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.admin_panel_settings,
                    title: '管理者数',
                    value: _getAdminsCount(),
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required Widget value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          value,
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // 投稿数取得
  Widget _getPostsCount() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bulletin_posts').snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        if (snapshot.connectionState == ConnectionState.active || snapshot.connectionState == ConnectionState.done) {
          return Text(
            '$count',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          );
        }
        return const Text('...', style: TextStyle(fontSize: 24));
      },
    );
  }

  // コメント数取得
  Widget _getCommentsCount() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bulletin_comments').snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        if (snapshot.connectionState == ConnectionState.active || snapshot.connectionState == ConnectionState.done) {
          return Text(
            '$count',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          );
        }
        return const Text('...', style: TextStyle(fontSize: 24));
      },
    );
  }

  // ユーザー数取得
  Widget _getUsersCount() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        if (snapshot.connectionState == ConnectionState.active || snapshot.connectionState == ConnectionState.done) {
          return Text(
            '$count',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          );
        }
        return const Text('...', style: TextStyle(fontSize: 24));
      },
    );
  }

  // 管理者数取得
  Widget _getAdminsCount() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admin_permissions')
          .where('isAdmin', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        if (snapshot.connectionState == ConnectionState.active || snapshot.connectionState == ConnectionState.done) {
          return Text(
            '$count',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          );
        }
        return const Text('...', style: TextStyle(fontSize: 24));
      },
    );
  }

  // 最近のアクティビティカード
  Widget _buildRecentActivityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '最近のアクティビティ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bulletin_posts')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = snapshot.data?.docs ?? [];
                if (posts.isEmpty) {
                  return const Text('最近のアクティビティはありません');
                }

                return Column(
                  children: posts.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.article, size: 20),
                      title: Text(
                        data['title'] ?? 'タイトルなし',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${data['authorName'] ?? '不明'} • ${_formatTimestamp(data['createdAt'])}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        onPressed: () {
                          // TODO: 投稿詳細に遷移
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // クイックアクションカード
  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'クイックアクション',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.5,
              children: [
                _buildQuickActionButton(
                  icon: Icons.article,
                  label: '投稿管理',
                  onPressed: () => _tabController.animateTo(1),
                ),
                _buildQuickActionButton(
                  icon: Icons.people,
                  label: 'ユーザー管理',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const UserManagementScreen(),
                      ),
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.help_center,
                  label: 'お問い合わせ',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ContactManagementScreen(),
                      ),
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.refresh,
                  label: 'データ更新',
                  onPressed: () {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('データを更新しました')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 投稿管理タブ
  Widget _buildPostsManagementTab() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '投稿管理',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.pending), text: '承認待ち'),
              Tab(icon: Icon(Icons.check_circle), text: '承認済み'),
              Tab(icon: Icon(Icons.push_pin), text: 'ピン留め申請'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPendingPostsList(),
                _buildApprovedPostsList(),
                _buildPinRequestsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingPostsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bulletin_posts')
            .where('approvalStatus', isEqualTo: 'pending')
            .orderBy('submittedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data?.docs ?? [];
          if (posts.isEmpty) {
            return const Center(
              child: Column(
                children: [
                  Icon(Icons.pending, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('承認待ちの投稿はありません'),
                ],
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final doc = posts[index];
              final data = doc.data() as Map<String, dynamic>;
              
              return _buildPendingPostCard(doc.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildApprovedPostsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bulletin_posts')
            .where('approvalStatus', isEqualTo: 'approved')
            .orderBy('approvedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data?.docs ?? [];
          if (posts.isEmpty) {
            return const Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('承認済みの投稿はありません'),
                ],
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final doc = posts[index];
              final data = doc.data() as Map<String, dynamic>;
              final isPinned = data['isPinned'] == true;
              final pinRequested = data['pinRequested'] == true;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isPinned)
                        const Icon(Icons.push_pin, color: Colors.orange),
                      if (pinRequested && !isPinned)
                        const Icon(Icons.push_pin_outlined, color: Colors.blue),
                    ],
                  ),
                  title: Text(
                    data['title'] ?? 'タイトルなし',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['description'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Text(
                            '投稿者: ${data['authorName'] ?? '不明'} • ${_formatTimestamp(data['createdAt'])}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          if (pinRequested && !isPinned) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blue),
                              ),
                              child: const Text(
                                'ピン申請',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'delete') {
                        await _deletePost(doc.id);
                      } else if (value == 'approve_pin') {
                        await _approvePinRequest(doc.id);
                      } else if (value == 'reject_pin') {
                        await _rejectPinRequest(doc.id);
                      } else if (value == 'unpin') {
                        await _unpinPost(doc.id);
                      }
                    },
                    itemBuilder: (context) => [
                      if (pinRequested && !isPinned) ...[
                        const PopupMenuItem(
                          value: 'approve_pin',
                          child: Row(
                            children: [
                              Icon(Icons.check, color: Colors.green),
                              SizedBox(width: 8),
                              Text('ピン留め承認', style: TextStyle(color: Colors.green)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'reject_pin',
                          child: Row(
                            children: [
                              Icon(Icons.close, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('ピン留め却下', style: TextStyle(color: Colors.orange)),
                            ],
                          ),
                        ),
                      ],
                      if (isPinned) ...[
                        const PopupMenuItem(
                          value: 'unpin',
                          child: Row(
                            children: [
                              Icon(Icons.push_pin_outlined, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('ピン留め解除', style: TextStyle(color: Colors.orange)),
                            ],
                          ),
                        ),
                      ],
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('削除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPinRequestsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bulletin_posts')
            .where('pinRequested', isEqualTo: true)
            .where('isPinned', isEqualTo: false)
            .orderBy('pinRequestedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data?.docs ?? [];
          if (posts.isEmpty) {
            return const Center(
              child: Column(
                children: [
                  Icon(Icons.push_pin_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('ピン留め申請はありません'),
                ],
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final doc = posts[index];
              final data = doc.data() as Map<String, dynamic>;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: Colors.blue.withOpacity(0.05),
                child: ListTile(
                  leading: const Icon(Icons.push_pin_outlined, color: Colors.blue),
                  title: Text(
                    data['title'] ?? 'タイトルなし',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['description'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '投稿者: ${data['authorName'] ?? '不明'}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '申請日: ${_formatTimestamp(data['pinRequestedAt'])}',
                        style: const TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _approvePinRequest(doc.id),
                        tooltip: 'ピン留め承認',
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _rejectPinRequest(doc.id),
                        tooltip: 'ピン留め却下',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ユーザー管理タブ
  Widget _buildUsersManagementTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people, size: 80, color: Colors.blue),
          const SizedBox(height: 24),
          const Text(
            'ユーザー管理',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            '詳細なユーザー管理は専用画面で行えます',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UserManagementScreen(),
                ),
              );
            },
            icon: const Icon(Icons.people),
            label: const Text('ユーザー管理画面を開く'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // お問い合わせ管理タブ
  Widget _buildContactManagementTab() {
    return const ContactManagementScreen(showAppBar: false);
  }

  // 通知管理タブ
  Widget _buildNotificationManagementTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notification_important, size: 80, color: Colors.orange),
          const SizedBox(height: 24),
          const Text(
            '通知管理',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            '全体通知の作成・管理機能\n（実装予定）',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: null, // 実装予定
            icon: const Icon(Icons.notification_important),
            label: const Text('実装予定'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // 学バス管理タブ
  Widget _buildBusManagementTab() {
    return const BusManagementScreen();
  }

  // 学食管理タブ
  Widget _buildCafeteriaManagementTab() {
    // 遅延読み込みのため動的importは不要、直接画面を返す
    return const CafeteriaManagementScreen();
  }

  // 管理者設定タブ（既存の管理者一覧機能を移動）
  Widget _buildAdminSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 警告カード
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '注意',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const Text(
                          '管理者権限は慎重に付与してください。\n管理者は全ての投稿を編集・削除でき、お問い合わせも閲覧できます。',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 管理者追加フォーム
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '新しい管理者を追加',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _userIdController,
                    decoration: const InputDecoration(
                      labelText: 'ユーザーID',
                      hintText: 'current_user',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      helperText: '管理者権限を付与するユーザーのIDを入力',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _grantAdminPermissions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              '管理者権限を付与',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 既存管理者一覧
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '現在の管理者一覧',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: _buildAdminList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admin_permissions')
          .where('isAdmin', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('エラー: ${snapshot.error}'),
          );
        }

        final admins = snapshot.data?.docs ?? [];

        if (admins.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.admin_panel_settings, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('管理者が登録されていません'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: admins.length,
          itemBuilder: (context, index) {
            final adminDoc = admins[index];
            final admin = AdminPermissions.fromJson({
              ...adminDoc.data() as Map<String, dynamic>,
              'id': adminDoc.id,
            });

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
                title: Text(admin.userId),
                subtitle: Text('付与日: ${admin.grantedAt.year}/${admin.grantedAt.month.toString().padLeft(2, '0')}/${admin.grantedAt.day.toString().padLeft(2, '0')}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'revoke') {
                      _showRevokeDialog(admin);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'revoke',
                      child: Row(
                        children: [
                          Icon(Icons.remove_circle, color: Colors.red),
                          SizedBox(width: 8),
                          Text('権限を取り消す', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 承認待ち投稿カードを構築（画像表示機能付き）
  Widget _buildPendingPostCard(String postId, Map<String, dynamic> data) {
    final imageUrl = data['imageUrl'] as String?;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.orange.withOpacity(0.05),
      child: Column(
        children: [
          // メインコンテンツ
          ListTile(
            leading: const Icon(Icons.pending, color: Colors.orange),
            title: Text(
              data['title'] ?? 'タイトルなし',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['description'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '投稿者: ${data['authorName'] ?? '不明'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (hasImage) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image, size: 12, color: Colors.blue),
                            SizedBox(width: 2),
                            Text(
                              '画像あり',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '申請日: ${_formatTimestamp(data['submittedAt'])}',
                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () => _approvePost(postId),
                  tooltip: '投稿承認',
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => _rejectPost(postId),
                  tooltip: '投稿却下',
                ),
                if (hasImage)
                  IconButton(
                    icon: const Icon(Icons.visibility, color: Colors.blue),
                    onPressed: () => _showImagePreview(context, imageUrl!),
                    tooltip: '画像を表示',
                  ),
              ],
            ),
          ),
          
          // 画像がある場合のプレビュー
          if (hasImage)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: InkWell(
                onTap: () => _showImagePreview(context, imageUrl),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey.shade100,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade100,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 32, color: Colors.grey),
                              SizedBox(height: 4),
                              Text(
                                '画像の読み込みに失敗しました',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 画像プレビューダイアログを表示
  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            // タップで閉じるための透明なオーバーレイ
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(color: Colors.transparent),
              ),
            ),
            // 画像表示
            Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ヘッダー
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.image, color: Colors.white),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              '投稿画像プレビュー',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    // 画像
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.7,
                        maxWidth: MediaQuery.of(context).size.width * 0.9,
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 200,
                              color: Colors.grey.shade100,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey.shade100,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    '画像の読み込みに失敗しました',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 承認済み投稿カードを構築（画像表示機能付き）
  Widget _buildApprovedPostCard(String postId, Map<String, dynamic> data) {
    final imageUrl = data['imageUrl'] as String?;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final isPinned = data['isPinned'] == true;
    final pinRequested = data['pinRequested'] == true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // メインコンテンツ
          ListTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isPinned)
                  const Icon(Icons.push_pin, color: Colors.orange),
                if (pinRequested && !isPinned)
                  const Icon(Icons.push_pin_outlined, color: Colors.blue),
                if (!isPinned && !pinRequested)
                  const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            title: Text(
              data['title'] ?? 'タイトルなし',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['description'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '投稿者: ${data['authorName'] ?? '不明'} • ${_formatTimestamp(data['createdAt'])}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (hasImage) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image, size: 10, color: Colors.green),
                            SizedBox(width: 2),
                            Text(
                              '画像',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (pinRequested && !isPinned) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: const Text(
                          'ピン申請',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasImage)
                  IconButton(
                    icon: const Icon(Icons.visibility, color: Colors.blue, size: 20),
                    onPressed: () => _showImagePreview(context, imageUrl!),
                    tooltip: '画像を表示',
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'delete') {
                      await _deletePost(postId);
                    } else if (value == 'approve_pin') {
                      await _approvePinRequest(postId);
                    } else if (value == 'reject_pin') {
                      await _rejectPinRequest(postId);
                    } else if (value == 'unpin') {
                      await _unpinPost(postId);
                    } else if (value == 'view_image') {
                      _showImagePreview(context, imageUrl!);
                    }
                  },
                  itemBuilder: (context) => [
                    if (hasImage)
                      const PopupMenuItem(
                        value: 'view_image',
                        child: Row(
                          children: [
                            Icon(Icons.image, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('画像を表示'),
                          ],
                        ),
                      ),
                    if (pinRequested && !isPinned) ...[
                      const PopupMenuItem(
                        value: 'approve_pin',
                        child: Row(
                          children: [
                            Icon(Icons.check, color: Colors.green),
                            SizedBox(width: 8),
                            Text('ピン留め承認', style: TextStyle(color: Colors.green)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'reject_pin',
                        child: Row(
                          children: [
                            Icon(Icons.close, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('ピン留め却下', style: TextStyle(color: Colors.orange)),
                          ],
                        ),
                      ),
                    ],
                    if (isPinned) ...[
                      const PopupMenuItem(
                        value: 'unpin',
                        child: Row(
                          children: [
                            Icon(Icons.push_pin_outlined, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('ピン留め解除', style: TextStyle(color: Colors.orange)),
                          ],
                        ),
                      ),
                    ],
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('削除', style: TextStyle(color: Colors.red)),
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
    );
  }

  // ユーティリティメソッド
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '不明';
    
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return '不明';
    }
    
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}';
  }

  // 投稿削除
  Future<void> _deletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('投稿を削除'),
        content: const Text('この投稿を削除しますか？この操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('bulletin_posts')
            .doc(postId)
            .delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('投稿を削除しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('投稿の削除に失敗しました: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _grantAdminPermissions() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ユーザーIDを入力してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 現在の管理者のUIDを取得
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('認証が必要です');
      }

      // 指定されたユーザーIDが存在するかチェック
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        throw Exception('指定されたユーザーIDが見つかりません: $userId');
      }

      // 既に管理者権限があるかチェック
      final existingAdmin = await FirebaseFirestore.instance
          .collection('admin_permissions')
          .doc(userId)
          .get();
      
      if (existingAdmin.exists) {
        final data = existingAdmin.data()!;
        if (data['isAdmin'] == true) {
          throw Exception('このユーザーは既に管理者権限を持っています');
        }
      }

      final adminPermissions = AdminPermissions(
        userId: userId,
        isAdmin: true,
        canManagePosts: true,
        canManageUsers: true,
        canViewContacts: true,
        canManageCategories: true,
        grantedAt: DateTime.now(),
        grantedBy: currentUser.uid, // 実際の管理者UID
      );

      await FirebaseFirestore.instance
          .collection('admin_permissions')
          .doc(userId)
          .set(adminPermissions.toJson());

      _userIdController.clear();

      if (mounted) {
        final userData = userDoc.data()!;
        final displayName = userData['displayName'] ?? userId;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$displayName ($userId) に管理者権限を付与しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('権限付与に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showRevokeDialog(AdminPermissions admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('管理者権限の取り消し'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${admin.userId} の管理者権限を取り消しますか？'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚠️ この操作は元に戻せません。\n該当ユーザーは管理機能を使用できなくなります。',
                style: TextStyle(fontSize: 12),
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
              await _revokeAdminPermissions(admin.userId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('取り消す'),
          ),
        ],
      ),
    );
  }

  Future<void> _revokeAdminPermissions(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('admin_permissions')
          .doc(userId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userId の管理者権限を取り消しました'),
            backgroundColor: Colors.green,
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
    }
  }

  // ピン留め申請承認
  Future<void> _approvePinRequest(String postId) async {
    try {
      // 投稿データを取得
      final postDoc = await FirebaseFirestore.instance
          .collection('bulletin_posts')
          .doc(postId)
          .get();
      
      if (!postDoc.exists) throw Exception('投稿が見つかりません');
      
      final postData = postDoc.data()!;
      final postTitle = postData['title'] as String;
      final postAuthorId = postData['authorId'] as String;

      await FirebaseFirestore.instance
          .collection('bulletin_posts')
          .doc(postId)
          .update({
        'isPinned': true,
        'pinRequested': false,
        'pinRequestedAt': null,
        'pinnedAt': FieldValue.serverTimestamp(),
        'pinnedBy': FirebaseAuth.instance.currentUser?.uid,
      });

      // ピン留め承認通知を送信
      try {
        await NotificationService.sendPinApprovedNotification(
          postAuthorId: postAuthorId,
          postTitle: postTitle,
          postId: postId,
        );
      } catch (notificationError) {
        print('ピン留め承認通知送信エラー: $notificationError');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ピン留めを承認しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ピン留め承認に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ピン留め申請却下
  Future<void> _rejectPinRequest(String postId) async {
    try {
      // 投稿データを取得
      final postDoc = await FirebaseFirestore.instance
          .collection('bulletin_posts')
          .doc(postId)
          .get();
      
      if (!postDoc.exists) throw Exception('投稿が見つかりません');
      
      final postData = postDoc.data()!;
      final postTitle = postData['title'] as String;
      final postAuthorId = postData['authorId'] as String;

      await FirebaseFirestore.instance
          .collection('bulletin_posts')
          .doc(postId)
          .update({
        'pinRequested': false,
        'pinRequestedAt': null,
      });

      // ピン留め却下通知を送信
      try {
        await NotificationService.sendPinRejectedNotification(
          postAuthorId: postAuthorId,
          postTitle: postTitle,
          postId: postId,
          reason: 'ピン留めの基準を満たしていません',
        );
      } catch (notificationError) {
        print('ピン留め却下通知送信エラー: $notificationError');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ピン留め申請を却下しました'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ピン留め申請却下に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ピン留め解除
  Future<void> _unpinPost(String postId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bulletin_posts')
          .doc(postId)
          .update({
        'isPinned': false,
        'pinnedAt': null,
        'pinnedBy': null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ピン留めを解除しました'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ピン留め解除に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 投稿承認
  Future<void> _approvePost(String postId) async {
    try {
      // 投稿データを取得
      final postDoc = await FirebaseFirestore.instance
          .collection('bulletin_posts')
          .doc(postId)
          .get();
      
      if (!postDoc.exists) throw Exception('投稿が見つかりません');
      
      final postData = postDoc.data()!;
      final postTitle = postData['title'] as String;
      final postAuthorId = postData['authorId'] as String;

      await FirebaseFirestore.instance
          .collection('bulletin_posts')
          .doc(postId)
          .update({
        'approvalStatus': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(), // 承認時に表示順用の日時を設定
      });

      // 投稿承認通知を送信
      try {
        await NotificationService.sendPostApprovedNotification(
          postAuthorId: postAuthorId,
          postTitle: postTitle,
          postId: postId,
        );
      } catch (notificationError) {
        print('投稿承認通知送信エラー: $notificationError');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('投稿を承認しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('投稿承認に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 投稿却下
  Future<void> _rejectPost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('投稿却下'),
        content: const Text('この投稿を却下しますか？却下された投稿は削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('却下', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // 投稿データを取得
        final postDoc = await FirebaseFirestore.instance
            .collection('bulletin_posts')
            .doc(postId)
            .get();
        
        if (!postDoc.exists) throw Exception('投稿が見つかりません');
        
        final postData = postDoc.data()!;
        final postTitle = postData['title'] as String;
        final postAuthorId = postData['authorId'] as String;

        await FirebaseFirestore.instance
            .collection('bulletin_posts')
            .doc(postId)
            .update({
          'approvalStatus': 'rejected',
        });

        // 投稿却下通知を送信
        try {
          await NotificationService.sendPostRejectedNotification(
            postAuthorId: postAuthorId,
            postTitle: postTitle,
            postId: postId,
            reason: '投稿内容が基準を満たしていません',
          );
        } catch (notificationError) {
          print('投稿却下通知送信エラー: $notificationError');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('投稿を却下しました'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('投稿却下に失敗しました: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // 通報管理タブ
  Widget _buildReportManagementTab() {
    return const ReportManagementScreen();
  }
}
