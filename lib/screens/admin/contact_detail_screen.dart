import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/admin/admin_model.dart';
import '../../core/providers/contact_provider.dart';

class ContactDetailScreen extends ConsumerStatefulWidget {
  final ContactForm contact;

  const ContactDetailScreen({
    super.key,
    required this.contact,
  });

  @override
  ConsumerState<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends ConsumerState<ContactDetailScreen> {
  final TextEditingController _responseController = TextEditingController();
  String _selectedStatus = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.contact.status;
    if (widget.contact.response != null) {
      _responseController.text = widget.contact.response!;
    }
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // IDが空の場合のエラーハンドリング
    if (widget.contact.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('エラー'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('お問い合わせIDが無効です'),
            ],
          ),
        ),
      );
    }
    
    final contactDetailAsync = ref.watch(contactDetailProvider(widget.contact.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('お問い合わせ詳細'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('ステータスを変更'),
                onTap: () => _showStatusDialog(),
              ),
              PopupMenuItem(
                child: const Text('お問い合わせを削除'),
                onTap: () => _showDeleteDialog(),
              ),
            ],
          ),
        ],
      ),
      body: contactDetailAsync.when(
        data: (contact) => contact != null 
            ? _buildContactDetail(contact)
            : const Center(child: Text('お問い合わせが見つかりません')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorWidget(error),
      ),
      bottomNavigationBar: _isLoading 
          ? const LinearProgressIndicator()
          : _buildBottomBar(),
    );
  }

  Widget _buildContactDetail(ContactForm contact) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 基本情報カード
          _buildBasicInfoCard(contact),
          
          const SizedBox(height: 16),
          
          // お問い合わせ内容カード
          _buildContentCard(contact),
          
          const SizedBox(height: 16),
          
          // 返信カード
          _buildResponseCard(contact),
          
          const SizedBox(height: 100), // BottomBarのスペース確保
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard(ContactForm contact) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: contact.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: contact.statusColor.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text(
                      contact.categoryIcon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.subject,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${contact.name ?? '匿名'} (${contact.email ?? '未入力'})',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: contact.statusColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              contact.statusDisplayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Text(
                              contact.categoryName,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            _buildInfoRow('お問い合わせID', contact.id),
            _buildInfoRow('作成日時', _formatDateTime(contact.createdAt)),
            if (contact.updatedAt != null)
              _buildInfoRow('更新日時', _formatDateTime(contact.updatedAt!)),
            if (contact.respondedAt != null)
              _buildInfoRow('返信日時', _formatDateTime(contact.respondedAt!)),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(ContactForm contact) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.message, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'お問い合わせ内容',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                contact.message,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseCard(ContactForm contact) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.reply, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  '返信',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            if (contact.response != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Text(
                  contact.response!,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '返信済み: ${_formatDateTime(contact.respondedAt!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              const Text('返信を編集:'),
              const SizedBox(height: 8),
            ] else ...[
              const Text('まだ返信がありません。返信を作成してください。'),
              const SizedBox(height: 16),
            ],
            
            TextField(
              controller: _responseController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'お客様への返信内容を入力してください...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showStatusDialog(),
              child: Text('ステータス変更'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _responseController.text.trim().isEmpty 
                  ? null 
                  : () => _sendResponse(),
              child: const Text('返信を送信'),
            ),
          ),
        ],
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
            onPressed: () => ref.invalidate(contactDetailProvider(widget.contact.id)),
            child: const Text('再読み込み'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ステータスを変更'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('未対応'),
              value: 'pending',
              groupValue: _selectedStatus,
              onChanged: (value) => setState(() => _selectedStatus = value!),
            ),
            RadioListTile<String>(
              title: const Text('対応中'),
              value: 'in_progress',
              groupValue: _selectedStatus,
              onChanged: (value) => setState(() => _selectedStatus = value!),
            ),
            RadioListTile<String>(
              title: const Text('解決済み'),
              value: 'resolved',
              groupValue: _selectedStatus,
              onChanged: (value) => setState(() => _selectedStatus = value!),
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
              await _updateStatus();
            },
            child: const Text('更新'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('お問い合わせを削除'),
        content: const Text('このお問い合わせを完全に削除しますか？この操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteContact();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(contactActionsProvider).updateStatus(widget.contact.id, _selectedStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ステータスを更新しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ステータス更新に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendResponse() async {
    final response = _responseController.text.trim();
    if (response.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(contactActionsProvider).sendResponse(widget.contact.id, response);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('返信を送信しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('返信送信に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteContact() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(contactActionsProvider).deleteContact(widget.contact.id);
      if (mounted) {
        context.pop(); // 削除後は前の画面に戻る
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('お問い合わせを削除しました'),
            backgroundColor: Colors.orange,
          ),
        );
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
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
