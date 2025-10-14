import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/bulletin/bulletin_model.dart';
import '../../core/providers/bulletin_provider.dart';
import '../../core/providers/admin_provider.dart';

class BulletinApprovalScreen extends ConsumerStatefulWidget {
  const BulletinApprovalScreen({super.key});

  @override
  ConsumerState<BulletinApprovalScreen> createState() => _BulletinApprovalScreenState();
}

class _BulletinApprovalScreenState extends ConsumerState<BulletinApprovalScreen> {
  String _selectedStatus = 'pending';

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
            title: const Text('投稿申請管理'),
            backgroundColor: Colors.orange.shade50,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.invalidate(bulletinPostsProvider);
                },
                tooltip: '更新',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Text('状態: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment<String>(
                            value: 'pending',
                            label: Text('承認待ち'),
                            icon: Icon(Icons.pending, size: 16),
                          ),
                          ButtonSegment<String>(
                            value: 'approved',
                            label: Text('承認済み'),
                            icon: Icon(Icons.check_circle, size: 16),
                          ),
                          ButtonSegment<String>(
                            value: 'rejected',
                            label: Text('却下済み'),
                            icon: Icon(Icons.cancel, size: 16),
                          ),
                        ],
                        selected: {_selectedStatus},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _selectedStatus = newSelection.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: _buildApplicationsList(),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('読み込み中...'),
          backgroundColor: Colors.orange.shade50,
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

  Widget _buildApplicationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bulletin_posts')
          .where('approvalStatus', isEqualTo: _selectedStatus)
          .orderBy('submittedAt', descending: true)
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
                  onPressed: () {
                    setState(() {}); // ストリームを再構築
                  },
                  child: const Text('再読み込み'),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _selectedStatus == 'pending' 
                    ? Icons.pending_actions_outlined
                    : _selectedStatus == 'approved'
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                  size: 64, 
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedStatus == 'pending' 
                    ? '承認待ちの申請はありません'
                    : _selectedStatus == 'approved'
                    ? '承認済みの申請はありません'
                    : '却下済みの申請はありません',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // ストリームを再構築
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              try {
                final data = docs[index].data() as Map<String, dynamic>;
                final post = BulletinPost.fromJson({
                  'id': docs[index].id,
                  ...data,
                });
                return _buildApplicationCard(post);
              } catch (e) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        Text('データ読み込みエラー: $e'),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildApplicationCard(BulletinPost post) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (post.approvalStatus) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = '承認済み';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = '却下済み';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = '承認待ち';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (post.approvalStatus == 'pending')
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleAction(value, post),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'approve',
                        child: Row(
                          children: [
                            Icon(Icons.check, size: 16, color: Colors.green),
                            SizedBox(width: 8),
                            Text('承認'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'reject',
                        child: Row(
                          children: [
                            Icon(Icons.close, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('却下'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'detail',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 16),
                            SizedBox(width: 8),
                            Text('詳細'),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  IconButton(
                    onPressed: () => _showPostDetails(post),
                    icon: const Icon(Icons.visibility),
                    tooltip: '詳細表示',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              post.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
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
                  '申請: ${_formatDate(post.submittedAt ?? post.createdAt)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            if (post.approvalStatus != 'pending' && post.approvedAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    post.approvalStatus == 'approved' ? Icons.check : Icons.close,
                    size: 16, 
                    color: post.approvalStatus == 'approved' ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.approvalStatus == 'approved' ? '承認' : '却下'}: ${_formatDate(post.approvedAt!)}',
                    style: TextStyle(
                      color: post.approvalStatus == 'approved' ? Colors.green : Colors.red, 
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleAction(String action, BulletinPost post) {
    switch (action) {
      case 'approve':
        _showApprovalConfirmation(post, true);
        break;
      case 'reject':
        _showApprovalConfirmation(post, false);
        break;
      case 'detail':
        _showPostDetails(post);
        break;
    }
  }

  void _showApprovalConfirmation(BulletinPost post, bool approve) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              approve ? Icons.check_circle : Icons.cancel,
              color: approve ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(approve ? '投稿を承認' : '投稿を却下'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              approve 
                ? '「${post.title}」を承認しますか？\n承認すると投稿が公開されます。'
                : '「${post.title}」を却下しますか？\n却下すると投稿者に通知されます。',
            ),
            const SizedBox(height: 16),
            const Text(
              '投稿内容:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              post.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processApproval(post, approve);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(approve ? '承認' : '却下'),
          ),
        ],
      ),
    );
  }

  Future<void> _processApproval(BulletinPost post, bool approve) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('ユーザーが認証されていません');
      }

      final batch = FirebaseFirestore.instance.batch();
      final postRef = FirebaseFirestore.instance
          .collection('bulletin_posts')
          .doc(post.id);

      // 投稿の承認状態を更新
      batch.update(postRef, {
        'approvalStatus': approve ? 'approved' : 'rejected',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': currentUser.uid,
        'isActive': approve, // 承認時は有効、却下時は無効
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? '投稿を承認しました' : '投稿を却下しました'),
            backgroundColor: approve ? Colors.green : Colors.red,
          ),
        );
        
        // プロバイダーを更新
        ref.invalidate(bulletinPostsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('処理に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
              _buildDetailRow('投稿者', post.authorName),
              _buildDetailRow('申請日', _formatDate(post.submittedAt ?? post.createdAt)),
              _buildDetailRow('状態', _getStatusText(post.approvalStatus)),
              if (post.approvedAt != null)
                _buildDetailRow(
                  post.approvalStatus == 'approved' ? '承認日' : '却下日',
                  _formatDate(post.approvedAt!),
                ),
              _buildDetailRow('カテゴリー', post.category.name),
              if (post.expiresAt != null)
                _buildDetailRow('有効期限', _formatDate(post.expiresAt!)),
              _buildDetailRow('コメント許可', post.allowComments ? 'はい' : 'いいえ'),
              if (post.pinRequested)
                _buildDetailRow('ピン留め申請', 'あり'),
              const SizedBox(height: 16),
              const Text(
                '内容:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(post.description),
              if (post.externalUrl != null && post.externalUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  '外部リンク:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  post.externalUrl!,
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
          if (post.approvalStatus == 'pending') ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showApprovalConfirmation(post, false);
              },
              child: const Text('却下', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showApprovalConfirmation(post, true);
              },
              child: const Text('承認'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return '承認済み';
      case 'rejected':
        return '却下済み';
      default:
        return '承認待ち';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}