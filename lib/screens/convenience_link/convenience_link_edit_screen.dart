import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/convenience_link/convenience_link_model.dart';
import '../../services/convenience_link/convenience_link_service.dart';

class ConvenienceLinkEditScreen extends ConsumerStatefulWidget {
  final ConvenienceLink? initialLink;
  final String userId;

  const ConvenienceLinkEditScreen({
    super.key,
    this.initialLink,
    required this.userId,
  });

  @override
  ConsumerState<ConvenienceLinkEditScreen> createState() =>
      _ConvenienceLinkEditScreenState();
}

class _ConvenienceLinkEditScreenState
    extends ConsumerState<ConvenienceLinkEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  
  String _selectedIcon = 'link';
  String _selectedColor = 'blue';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLink != null) {
      _titleController.text = widget.initialLink!.title;
      _urlController.text = widget.initialLink!.url;
      _selectedIcon = widget.initialLink!.iconName;
      _selectedColor = widget.initialLink!.color;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialLink != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'リンクを編集' : 'リンクを追加'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteConfirmDialog,
              tooltip: 'リンクを削除',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // プレビューカード
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'プレビュー',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      _buildPreviewTile(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // タイトル入力
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'タイトル *',
                  hintText: '例: 学生ポータル',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'タイトルを入力してください';
                  }
                  if (value.trim().length > 30) {
                    return 'タイトルは30文字以内で入力してください';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // URL入力
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL *',
                  hintText: 'https://example.com',
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'URLを入力してください';
                  }
                  if (!ConvenienceLinkService.isValidUrl(value.trim())) {
                    return '正しいURL形式で入力してください（http:// または https://）';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),

              // アイコン選択
              Text(
                'アイコン',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: LinkIcons.iconList.map((entry) {
                    final isSelected = _selectedIcon == entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedIcon = entry.key),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 60,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Icon(
                            entry.value,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // カラー選択
              Text(
                'カラー',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: LinkColors.colorList.map((entry) {
                  final isSelected = _selectedColor == entry.key;
                  return InkWell(
                    onTap: () => setState(() => _selectedColor = entry.key),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: entry.value,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.black, width: 3)
                            : Border.all(color: Colors.grey.shade300),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              // 保存ボタン
              ElevatedButton(
                onPressed: _isLoading ? null : _saveLink,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? '更新' : '追加'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewTile() {
    final title = _titleController.text.trim().isEmpty 
        ? 'タイトル' 
        : _titleController.text.trim();
    final url = _urlController.text.trim().isEmpty 
        ? 'URL' 
        : _urlController.text.trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LinkColors.getColor(_selectedColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: LinkColors.getColor(_selectedColor).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: LinkColors.getColor(_selectedColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              LinkIcons.getIcon(_selectedIcon),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  url,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final link = ConvenienceLink(
        id: widget.initialLink?.id ?? ConvenienceLinkService.generateId(),
        title: _titleController.text.trim(),
        url: _urlController.text.trim(),
        iconName: _selectedIcon,
        color: _selectedColor,
        order: widget.initialLink?.order ?? 0,
        isEnabled: widget.initialLink?.isEnabled ?? true,
        createdAt: widget.initialLink?.createdAt,
        updatedAt: DateTime.now(),
      );

      if (widget.initialLink == null) {
        await ConvenienceLinkService.addLink(widget.userId, link);
      } else {
        await ConvenienceLinkService.updateLink(widget.userId, link);
      }

      if (mounted) {
        Navigator.of(context).pop(true); // 成功を示すためにtrueを返す
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.initialLink == null 
                ? 'リンクを追加しました' 
                : 'リンクを更新しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('リンクを削除'),
        content: Text('「${widget.initialLink!.title}」を削除しますか？\nこの操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteLink();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLink() async {
    setState(() => _isLoading = true);

    try {
      await ConvenienceLinkService.deleteLink(widget.userId, widget.initialLink!.id);
      
      if (mounted) {
        Navigator.of(context).pop(true); // 成功を示すためにtrueを返す
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('リンクを削除しました'),
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}