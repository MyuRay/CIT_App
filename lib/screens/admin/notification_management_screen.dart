import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../widgets/admin/admin_access_gate.dart';
import '../../models/notification/notification_model.dart';
import '../../core/providers/global_notification_provider.dart';

class NotificationManagementScreen extends ConsumerStatefulWidget {
  const NotificationManagementScreen({super.key});

  @override
  ConsumerState<NotificationManagementScreen> createState() =>
      _NotificationManagementScreenState();
}

class _NotificationManagementScreenState
    extends ConsumerState<NotificationManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminAccessGate(title: '通知管理', builder: (_) => _content(context));
  }

  Widget _content(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '通知作成', icon: Icon(Icons.add_circle_outline)),
            Tab(text: '通知履歴', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: TabBarView(
          controller: _tabController,
          children: const [NotificationCreationTab(), NotificationHistoryTab()],
        ),
      ),
    );
  }
}

class NotificationCreationTab extends ConsumerStatefulWidget {
  const NotificationCreationTab({super.key});

  @override
  ConsumerState<NotificationCreationTab> createState() =>
      _NotificationCreationTabState();
}

class _NotificationCreationTabState
    extends ConsumerState<NotificationCreationTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _versionController = TextEditingController();
  final _urlController = TextEditingController();

  NotificationType _selectedType = NotificationType.general;
  DateTime? _expiryDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _titleController,
      _messageController,
      _versionController,
      _urlController,
    ]) {
      controller.addListener(_updatePreview);
    }
  }

  void _updatePreview() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _versionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 通知タイプ選択
            _buildTypeSelection(),
            const SizedBox(height: 24),

            // タイトル入力
            _buildTitleField(),
            const SizedBox(height: 16),

            // メッセージ入力
            _buildMessageField(),
            const SizedBox(height: 16),

            // バージョン入力（アップデート通知の場合）
            if (_selectedType == NotificationType.appUpdate) ...[
              _buildVersionField(),
              const SizedBox(height: 16),
            ],

            // URL入力（新機能通知の場合）
            if (_selectedType == NotificationType.feature) ...[
              _buildUrlField(),
              const SizedBox(height: 16),
            ],

            // 有効期限設定
            _buildExpiryDateField(),
            const SizedBox(height: 32),

            // プレビュー
            _buildPreview(),
            const SizedBox(height: 32),

            // 送信ボタン
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '通知タイプ',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children:
                  NotificationType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return FilterChip(
                      label: Text('${type.emoji} ${type.displayName}'),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          final previousDefault = _getDefaultTitle(
                            _selectedType,
                          );
                          if (_titleController.text.trim().isEmpty ||
                              _titleController.text == previousDefault) {
                            _titleController.text = _getDefaultTitle(type);
                          }
                          _selectedType = type;
                        });
                      },
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'タイトル',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.title),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'タイトルを入力してください';
        }
        return null;
      },
    );
  }

  Widget _buildMessageField() {
    return TextFormField(
      controller: _messageController,
      decoration: const InputDecoration(
        labelText: 'メッセージ',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.message),
        alignLabelWithHint: true,
      ),
      maxLines: 4,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'メッセージを入力してください';
        }
        return null;
      },
    );
  }

  Widget _buildVersionField() {
    return TextFormField(
      controller: _versionController,
      decoration: const InputDecoration(
        labelText: 'アプリバージョン',
        hintText: '例: 1.2.0',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.info),
      ),
      validator: (value) {
        if (_selectedType == NotificationType.appUpdate &&
            (value == null || value.trim().isEmpty)) {
          return 'バージョン番号を入力してください';
        }
        return null;
      },
    );
  }

  Widget _buildUrlField() {
    return TextFormField(
      controller: _urlController,
      decoration: const InputDecoration(
        labelText: '関連URL（任意）',
        hintText: 'https://example.com',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.link),
      ),
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final uri = Uri.tryParse(value);
          if (uri == null || !uri.hasAbsolutePath) {
            return '正しいURLを入力してください';
          }
        }
        return null;
      },
    );
  }

  Widget _buildExpiryDateField() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.event),
        title: const Text('有効期限'),
        subtitle:
            _expiryDate != null
                ? Text(
                  '${_expiryDate!.year}/${_expiryDate!.month}/${_expiryDate!.day}',
                )
                : const Text('期限なし（永続）'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_expiryDate != null)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() => _expiryDate = null),
              ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _selectExpiryDate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.preview, size: 20),
                const SizedBox(width: 8),
                Text(
                  'プレビュー',
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
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _selectedType.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _titleController.text.isNotEmpty
                              ? _titleController.text
                              : _getDefaultTitle(_selectedType),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _messageController.text.isNotEmpty
                        ? _messageController.text
                        : '（メッセージ内容）',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (_selectedType == NotificationType.appUpdate &&
                      _versionController.text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'バージョン: ${_versionController.text}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _submitNotification,
        icon:
            _isLoading
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : const Icon(Icons.send),
        label: Text(_isLoading ? '送信中...' : '通知を送信'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  String _getDefaultTitle(NotificationType type) {
    switch (type) {
      case NotificationType.appUpdate:
        return 'CIT App アップデートのお知らせ';
      case NotificationType.maintenance:
        return 'メンテナンスのお知らせ';
      case NotificationType.important:
        return '重要なお知らせ';
      case NotificationType.feature:
        return '新機能のご紹介';
      case NotificationType.general:
        return 'お知らせ';
      default:
        return 'お知らせ';
    }
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _expiryDate = date);
    }
  }

  Future<void> _submitNotification() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notificationCreation = ref.read(notificationCreationProvider);

      await notificationCreation.createNotification(
        GlobalNotification(
          id: '',
          type: _selectedType,
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
          createdAt: DateTime.now(),
          version:
              _selectedType == NotificationType.appUpdate
                  ? _versionController.text.trim()
                  : null,
          url:
              _selectedType == NotificationType.feature &&
                      _urlController.text.trim().isNotEmpty
                  ? _urlController.text.trim()
                  : null,
          expiresAt: _expiryDate,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.onInverseSurface,
                ),
                const SizedBox(width: 8),
                const Expanded(child: Text('通知を送信しました')),
              ],
            ),
            backgroundColor: AppColors.snackBarSurface(context, Colors.green),
          ),
        );

        // フォームをリセット
        _formKey.currentState!.reset();
        _titleController.clear();
        _messageController.clear();
        _versionController.clear();
        _urlController.clear();
        setState(() {
          _selectedType = NotificationType.general;
          _expiryDate = null;
        });
      }
    } catch (e, stackTrace) {
      print('❌ 通知送信エラー: $e');
      print('❌ StackTrace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('送信に失敗しました'),
                Text('エラー: $e', style: const TextStyle(fontSize: 12)),
              ],
            ),
            backgroundColor: AppColors.snackBarSurface(context, Colors.red),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class NotificationHistoryTab extends ConsumerWidget {
  const NotificationHistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(allGlobalNotificationsProvider);

    return notificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                SizedBox(height: 16),
                Text(
                  '送信した通知がありません',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(child: Text(notification.emoji)),
                title: Text(
                  notification.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${notification.createdAt.month}/${notification.createdAt.day} ${notification.createdAt.hour}:${notification.createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (action) async {
                    switch (action) {
                      case 'deactivate':
                        await ref
                            .read(notificationCreationProvider)
                            .deactivateNotification(notification.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('通知を無効化しました')),
                          );
                        }
                        break;
                      case 'delete':
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder:
                              (ctx) => AlertDialog(
                                title: const Text('通知を削除'),
                                content: const Text(
                                  'この通知を履歴から完全に削除します。よろしいですか？',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('キャンセル'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: FilledButton.styleFrom(
                                      foregroundColor: AppColors.onColor(
                                        Colors.red,
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text('削除'),
                                  ),
                                ],
                              ),
                        );
                        if (confirmed == true) {
                          await ref
                              .read(notificationCreationProvider)
                              .deleteNotification(notification.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('通知を削除しました')),
                            );
                          }
                        }
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        if (notification.isCurrentlyActive)
                          const PopupMenuItem(
                            value: 'deactivate',
                            child: Text('無効化'),
                          ),
                        const PopupMenuItem(value: 'delete', child: Text('削除')),
                      ],
                  icon:
                      notification.isCurrentlyActive
                          ? const Icon(Icons.more_vert)
                          : Icon(
                            Icons.more_vert,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error,
                  size: 64,
                  color: AppColors.accent(context, Colors.red),
                ),
                const SizedBox(height: 16),
                Text('エラーが発生しました: $error'),
              ],
            ),
          ),
    );
  }
}

// NotificationTypeの拡張
extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.appUpdate:
        return 'アプリアップデート';
      case NotificationType.maintenance:
        return 'メンテナンス';
      case NotificationType.important:
        return '重要なお知らせ';
      case NotificationType.general:
        return 'お知らせ';
      case NotificationType.feature:
        return '新機能';
      default:
        return 'その他';
    }
  }

  String get emoji {
    switch (this) {
      case NotificationType.appUpdate:
        return '🔄';
      case NotificationType.maintenance:
        return '🔧';
      case NotificationType.important:
        return '⚠️';
      case NotificationType.general:
        return '📢';
      case NotificationType.feature:
        return '✨';
      default:
        return '📱';
    }
  }
}
