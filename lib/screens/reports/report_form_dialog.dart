import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/reports/report_model.dart';
import '../../core/providers/report_provider.dart';

class ReportFormDialog extends ConsumerStatefulWidget {
  final ReportType type;
  final String targetId;
  final String targetTitle;
  final ReportModerationSnapshot? moderation;

  const ReportFormDialog({
    super.key,
    required this.type,
    required this.targetId,
    required this.targetTitle,
    this.moderation,
  });

  @override
  ConsumerState<ReportFormDialog> createState() => _ReportFormDialogState();
}

class _ReportFormDialogState extends ConsumerState<ReportFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _detailController = TextEditingController();
  ReportReason? _selectedReason;
  bool _isLoading = false;

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('通報理由を選択してください')),
      );
      return;
    }

    // 確認ダイアログ
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('通報の確認'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('以下の内容で通報します。よろしいですか？'),
            const SizedBox(height: 16),
            Text('対象: ${widget.targetTitle}'),
            Text('種別: ${widget.type.displayName}'),
            Text('理由: ${_selectedReason!.displayName}'),
            if (_detailController.text.isNotEmpty)
              Text('詳細: ${_detailController.text}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('通報する'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(reportSubmitProvider.notifier).submitReport(
            type: widget.type,
            targetId: widget.targetId,
            reason: _selectedReason!,
            detail: _detailController.text.isNotEmpty
                ? _detailController.text
                : null,
            moderation: widget.moderation,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('通報を受け付けました。ご協力ありがとうございます。'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('通報の送信に失敗しました: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: mediaQuery.size.height * 0.8,
            maxWidth: 500,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ヘッダー
                    Row(
                      children: [
                        const Icon(Icons.flag, color: Colors.red, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '通報する',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                widget.targetTitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: colorScheme.onSurface),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 説明カード
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer
                            .withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '不適切なコンテンツを見つけた場合は、通報してください。管理者が確認します。',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 通報理由選択
                    Text(
                      '通報理由 *',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...ReportReason.values.map((reason) {
                      return RadioListTile<ReportReason>(
                        title: Text(
                          reason.displayName,
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                        value: reason,
                        groupValue: _selectedReason,
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedReason = value;
                                });
                              },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),

                    const SizedBox(height: 16),

                    // 詳細入力
                    TextFormField(
                      controller: _detailController,
                      maxLines: 4,
                      maxLength: 500,
                      enabled: !_isLoading,
                      decoration: const InputDecoration(
                        labelText: '詳細（任意）',
                        border: OutlineInputBorder(),
                        hintText: '具体的な内容を記入してください（500文字以内）',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value != null && value.length > 500) {
                          return '詳細は500文字以内で入力してください';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('通報する'),
          ),
        ],
      ),
    );
  }
}

/// 通報フォームダイアログを表示する関数
Future<bool?> showReportDialog(
  BuildContext context, {
  required ReportType type,
  required String targetId,
  required String targetTitle,
  ReportModerationSnapshot? moderation,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => ReportFormDialog(
      type: type,
      targetId: targetId,
      targetTitle: targetTitle,
      moderation: moderation,
    ),
  );
}
