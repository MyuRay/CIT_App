import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/cwitter_provider.dart';
import '../../../core/providers/cwitter_quote_provider.dart';
import '../../../core/providers/schedule_provider.dart';
import '../../../models/community/cwitter_post.dart';
import '../../../services/community/cwitter_post_writer.dart';
import '../../../services/community/cwitter_service.dart';
import 'admin_ban_dialog.dart';
import 'cwitter_posting_guidelines_dialog.dart';
import 'cwitter_quoted_post.dart';
import 'cwitter_id_requirement.dart';

class CwitterQuoteComposer extends ConsumerStatefulWidget {
  const CwitterQuoteComposer({super.key, required this.post});

  final CwitterPost post;

  static Future<bool> show(BuildContext context, CwitterPost post) async {
    return await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => CwitterQuoteComposer(post: post)),
        ) ??
        false;
  }

  @override
  ConsumerState<CwitterQuoteComposer> createState() =>
      _CwitterQuoteComposerState();
}

class _CwitterQuoteComposerState extends ConsumerState<CwitterQuoteComposer> {
  final _controller = TextEditingController();
  final _form = GlobalKey<FormState>();
  late final String? _authorId;
  bool _posting = false;
  bool _closing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _authorId = ref.read(currentUserIdProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_posting || _closing) return;
    _closing = true;
    try {
      if (_controller.text.trim().isNotEmpty) {
        final discard = await showDialog<bool>(
          context: context,
          builder:
              (dialogContext) => AlertDialog(
                title: const Text('引用recweetを破棄しますか？'),
                content: const Text('入力したコメントは保存されません。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('編集を続ける'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('破棄する'),
                  ),
                ],
              ),
        );
        if (discard != true || !mounted) return;
      }
      if (mounted) Navigator.pop(context, false);
    } finally {
      _closing = false;
    }
  }

  Future<void> _submit() async {
    if (_posting || _form.currentState?.validate() != true) return;
    if (!hasCurrentCwitterIdentity(ref)) {
      await promptCwitterIdRegistration(context, ref, action: '引用recweet');
      return;
    }
    final user = ref.read(currentAppUserStreamProvider).valueOrNull;
    if (_authorId == null ||
        user?.uid != _authorId ||
        ref.read(currentUserIdProvider) != _authorId ||
        user?.hasCwitterId != true) {
      setState(() => _error = 'ログイン状態を確認して、もう一度開いてください。');
      return;
    }
    final source = ref.read(visibleCwitterQuotedPostProvider(widget.post.id));
    if (source.isLoading || source.hasError || source.valueOrNull == null) {
      setState(() => _error = '元のCweetを表示できないため引用できません。');
      return;
    }
    setState(() {
      _posting = true;
      _error = null;
    });
    try {
      final confirmed = await CwitterPostingGuidelinesDialog.confirmIfNeeded(
        context,
        ref,
      );
      if (!confirmed || !mounted) return;
      if (ref.read(currentUserIdProvider) != _authorId) {
        throw StateError('ログイン状態が変わりました');
      }
      await ref.read(submitCwitterQuoteProvider)(
        user!,
        widget.post.id,
        _controller.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      if (maybeShowBanNotice(context, error)) return;
      setState(
        () =>
            _error =
                error is CwitterPostRateLimitException ||
                        error is CwitterQuoteUnavailableException
                    ? '$error'
                    : '引用recweetできませんでした。もう一度お試しください。',
      );
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final author = ref.watch(currentAppUserStreamProvider);
    final currentUid = ref.watch(currentUserIdProvider);
    final canPostAsSelf =
        currentUid == _authorId &&
        author.valueOrNull?.uid == _authorId;
    final source = ref.watch(visibleCwitterQuotedPostProvider(widget.post.id));
    final available =
        !source.isLoading && !source.hasError && source.valueOrNull != null;
    return PopScope(
      canPop: !_posting && _controller.text.trim().isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _posting ? null : _close,
            icon: const Icon(Icons.close),
            tooltip: '閉じる',
          ),
          title: const Text('引用recweet'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _controller,
                    autofocus: true,
                    enabled: !_posting,
                    minLines: 3,
                    maxLines: 8,
                    maxLength: 280,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'コメントを追加',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.isEmpty) return 'コメントを入力してください';
                      if (text.length > 280) return 'コメントは280文字以内で入力してください';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  CwitterQuotedPost(postId: widget.post.id),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (!canPostAsSelf && !author.isLoading) ...[
                    const SizedBox(height: 12),
                    const Text('ログイン状態を確認して、もう一度開いてください。'),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed:
                        _posting || !available || !canPostAsSelf
                            ? null
                            : _submit,
                    icon:
                        _posting
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.format_quote),
                    label: Text(_posting ? '投稿中…' : '引用recweetする'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
