import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/assignment_provider.dart';
import '../../models/assignments/assignment.dart';
import '../../models/schedule/schedule_model.dart';
import 'assignment_editor.dart';

class AssignmentBoard extends ConsumerStatefulWidget {
  const AssignmentBoard({super.key, this.preferredSchedule});
  final Schedule? preferredSchedule;
  @override
  ConsumerState<AssignmentBoard> createState() => _AssignmentBoardState();
}

class _AssignmentBoardState extends ConsumerState<AssignmentBoard> {
  bool _completed = false;
  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(assignmentsProvider);
    final uid = ref.watch(assignmentUserIdProvider);
    final data = tasks.valueOrNull ?? const <Assignment>[];
    final visible =
        data.where((t) => t.isCompleted == _completed).toList()
          ..sort(Assignment.compare);
    return CustomScrollView(
      key: const PageStorageKey('assignment-board'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(
                      '課題管理',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    FilledButton.icon(
                      onPressed:
                          uid == null
                              ? null
                              : () => showAssignmentEditor(
                                context,
                                ref,
                                schedule: widget.preferredSchedule,
                              ),
                      icon: const Icon(Icons.add),
                      label: const Text('課題を登録'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'すべての学期の課題を締切順に表示',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    ChoiceChip(
                      label: Text(
                        '未完了 ${data.where((t) => !t.isCompleted).length}',
                      ),
                      selected: !_completed,
                      onSelected: (_) => setState(() => _completed = false),
                    ),
                    ChoiceChip(
                      label: Text(
                        '完了 ${data.where((t) => t.isCompleted).length}',
                      ),
                      selected: _completed,
                      onSelected: (_) => setState(() => _completed = true),
                    ),
                  ],
                ),
                if (tasks.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (tasks.hasError)
                  AssignmentLoadError(onRetry: () => retryAssignments(ref)),
                if (!tasks.isLoading && !tasks.hasError && visible.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 40,
                      horizontal: 8,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _completed
                              ? Icons.task_alt
                              : Icons.assignment_outlined,
                          size: 40,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _completed
                              ? '完了した課題はありません'
                              : data.isEmpty
                              ? '現在課題は登録されていません'
                              : '課題はすべて完了しました',
                          textAlign: TextAlign.center,
                        ),
                        if (!_completed)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              '「課題を登録」から追加できます',
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList.builder(
            itemCount: visible.length,
            itemBuilder:
                (context, index) => AssignmentTile(
                  key: ValueKey('${uid}_${visible[index].id}'),
                  task: visible[index],
                ),
          ),
        ),
      ],
    );
  }
}

class AssignmentTile extends ConsumerStatefulWidget {
  const AssignmentTile({super.key, required this.task});
  final Assignment task;
  @override
  ConsumerState<AssignmentTile> createState() => _AssignmentTileState();
}

class _AssignmentTileState extends ConsumerState<AssignmentTile> {
  bool _busy = false;
  Future<void> _run(Future<void> Function() operation) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await operation();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('変更できませんでした。通信状態を確認して再度お試しください。')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('課題を削除しますか？'),
            content: Text(widget.task.draft.title),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('削除'),
              ),
            ],
          ),
    );
    if (confirmed == true && mounted) {
      await _run(
        () =>
            ref.read(assignmentRepositoryProvider).delete(uid, widget.task.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(assignmentUserIdProvider);
    final now =
        ref.watch(assignmentClockProvider).valueOrNull ?? DateTime.now();
    final task = widget.task;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child:
                _busy
                    ? const SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                    : Checkbox(
                      value: task.isCompleted,
                      semanticLabel:
                          '${task.draft.title}を${task.isCompleted ? '未完了に戻す' : '完了にする'}',
                      onChanged:
                          uid == null
                              ? null
                              : (value) => _run(
                                () => ref
                                    .read(assignmentRepositoryProvider)
                                    .setCompleted(uid, task.id, value!),
                              ),
                    ),
          ),
          Expanded(
            child: InkWell(
              onTap:
                  uid == null || _busy
                      ? null
                      : () =>
                          showAssignmentEditor(context, ref, assignment: task),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.draft.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        decoration:
                            task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      assignmentDueLabel(task, now),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            task.isOverdue(now) ? scheme.error : scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (task.draft.course != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          task.draft.course!.label,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    if (task.draft.notes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          task.draft.notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            enabled: uid != null && !_busy,
            tooltip: '課題の操作',
            onSelected: (action) {
              if (action == 'delete') {
                _delete(uid!);
              } else {
                showAssignmentEditor(context, ref, assignment: task);
              }
            },
            itemBuilder:
                (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('編集')),
                  PopupMenuItem(value: 'delete', child: Text('削除')),
                ],
          ),
        ],
      ),
    );
  }
}

class AssignmentLoadError extends StatelessWidget {
  const AssignmentLoadError({super.key, required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '課題を読み込めませんでした。',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('再読み込み'),
      ),
    ],
  );
}

class AssignmentHomeCard extends ConsumerWidget {
  const AssignmentHomeCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(assignmentsProvider);
    final uid = ref.watch(assignmentUserIdProvider);
    final pending =
        (tasks.valueOrNull ?? const <Assignment>[])
            .where((t) => !t.isCompleted)
            .toList()
          ..sort(Assignment.compare);
    void openBoard() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => Scaffold(
              appBar: AppBar(title: const Text('課題管理')),
              body: const AssignmentBoard(),
            ),
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 24,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '課題',
                          key: const ValueKey('assignment-home-title'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    if (pending.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${pending.length}件',
                          style: Theme.of(
                            context,
                          ).textTheme.labelMedium?.copyWith(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
                TextButton.icon(
                  onPressed:
                      uid == null
                          ? null
                          : () => showAssignmentEditor(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('登録'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (tasks.isLoading) const LinearProgressIndicator(),
            if (tasks.hasError)
              AssignmentLoadError(onRetry: () => retryAssignments(ref)),
            if (!tasks.isLoading && !tasks.hasError && pending.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  tasks.valueOrNull?.isNotEmpty == true
                      ? '課題はすべて完了しました'
                      : '現在課題は登録されていません',
                ),
              ),
            for (final task in pending.take(3))
              AssignmentTile(key: ValueKey('${uid}_${task.id}'), task: task),
            TextButton(
              onPressed: openBoard,
              child: Text(
                pending.length > 3
                    ? 'すべての課題を見る（${pending.length}件）'
                    : '課題管理を開く',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
