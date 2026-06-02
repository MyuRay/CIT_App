import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/chiba_channel_provider.dart';
import '../../../core/providers/cwitter_provider.dart';
import '../../../core/providers/schedule_provider.dart';
import '../../../models/community/chiba_channel_thread.dart';
import '../../../services/community/chiba_channel_service.dart';
import 'admin_ban_dialog.dart';

class ChibaChannelCreateThreadSheet extends ConsumerStatefulWidget {
  const ChibaChannelCreateThreadSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: const ChibaChannelCreateThreadSheet(),
      ),
    );
  }

  @override
  ConsumerState<ChibaChannelCreateThreadSheet> createState() =>
      _ChibaChannelCreateThreadSheetState();
}

class _ChibaChannelCreateThreadSheetState
    extends ConsumerState<ChibaChannelCreateThreadSheet> {
  final _titleController = TextEditingController();
  String _category = ChibaChannelThread.categories.first;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final uid = ref.read(currentUserIdProvider);
    final appUser = ref.read(currentAppUserStreamProvider).valueOrNull;
    if (uid == null || appUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインが必要です')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ChibaChannelService.createThread(
        authorId: uid,
        authorEmail: appUser.email,
        title: _titleController.text,
        category: _category,
      );
      if (!mounted) return;
      ref.invalidate(chibaChannelThreadsProvider);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('スレッドを作成しました')),
      );
    } catch (error) {
      if (!mounted) return;
      if (maybeShowBanNotice(context, error)) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('ArgumentError: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'スレを作成',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'カテゴリ',
              border: OutlineInputBorder(),
            ),
            items: ChibaChannelThread.categories
                .map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  ),
                )
                .toList(),
            onChanged: _isSubmitting
                ? null
                : (value) {
                    if (value != null) setState(() => _category = value);
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            enabled: !_isSubmitting,
            maxLength: 80,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'スレッドタイトル',
              hintText: ChibaChannelThread.titlePlaceholderFor(_category),
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('作成する'),
          ),
        ],
      ),
    );
  }
}
