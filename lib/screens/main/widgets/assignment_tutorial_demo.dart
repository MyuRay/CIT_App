import 'package:flutter/material.dart';

/// A local example: never reads or writes the user's assignments.
class AssignmentTutorialDemo extends StatefulWidget {
  const AssignmentTutorialDemo({super.key});

  @override
  State<AssignmentTutorialDemo> createState() => _AssignmentTutorialDemoState();
}

class _AssignmentTutorialDemoState extends State<AssignmentTutorialDemo> {
  final _title = TextEditingController(text: '第3回レポート');
  bool _board = false;
  bool _editing = false;
  bool _registered = false;
  bool _completed = false;
  bool _showCompleted = false;
  bool _dueToday = false;
  String _savedTitle = '';
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = '課題名を入力してください');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _savedTitle = title;
      _registered = true;
      _editing = false;
      _completed = false;
      _showCompleted = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final due = _dueToday ? '今日 23:59' : '明日 23:59';
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('2026 後期'),
              Semantics(
                toggled: _board,
                child: TextButton.icon(
                  key: const Key('demo_assignment_toggle'),
                  onPressed: () => setState(() => _board = !_board),
                  icon: Icon(
                    _board
                        ? Icons.calendar_view_week
                        : Icons.assignment_outlined,
                  ),
                  label: Text(_board ? '時間割' : '課題'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: colors.secondaryContainer,
                    foregroundColor: colors.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_board) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '月曜 2限\n情報基礎',
                style: TextStyle(color: colors.onPrimaryContainer),
              ),
            ),
          ] else if (_editing) ...[
            Text('課題を登録', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            TextField(
              key: const Key('demo_assignment_title'),
              controller: _title,
              textInputAction: TextInputAction.done,
              maxLength: 120,
              decoration: InputDecoration(
                labelText: '課題名',
                errorText: _error,
                counterText: '',
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 12),
            const Text('講義：情報基礎'),
            const SizedBox(height: 8),
            Text('締切：$due'),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final today in [true, false])
                  ChoiceChip(
                    key: ValueKey('demo_assignment_due_$today'),
                    label: Text(today ? '今日' : '明日'),
                    selected: _dueToday == today,
                    onSelected: (_) => setState(() => _dueToday = today),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('demo_assignment_save'),
              onPressed: _save,
              child: const Text('登録する'),
            ),
          ] else ...[
            if (!_registered)
              FilledButton.icon(
                key: const Key('demo_assignment_add'),
                onPressed: () => setState(() => _editing = true),
                icon: const Icon(Icons.add),
                label: const Text('課題を登録'),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final completed in [false, true])
                  ChoiceChip(
                    key: ValueKey('demo_assignment_filter_$completed'),
                    label: Text(completed ? '完了' : '未完了'),
                    selected: _showCompleted == completed,
                    onSelected:
                        (_) => setState(() => _showCompleted = completed),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_registered && _completed == _showCompleted)
              Container(
                padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: _completed ? '課題を未完了に戻す' : '課題を完了にする',
                      child: Checkbox(
                        key: const Key('demo_assignment_complete'),
                        value: _completed,
                        onChanged:
                            (value) => setState(() => _completed = value!),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_savedTitle, style: theme.textTheme.titleSmall),
                          const Text('情報基礎'),
                          Text(
                            '締切 $due',
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                _showCompleted
                    ? '完了した課題はありません'
                    : _registered
                    ? '課題はすべて完了しました'
                    : '現在課題は登録されていません',
              ),
          ],
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              !_board
                  ? '学期の隣にある「課題」をタップしてみましょう。'
                  : _editing
                  ? '課題名と締切を確認して「登録する」をタップ。実際の登録では日付・時刻を指定できます。'
                  : !_registered
                  ? '「課題を登録」をタップして、登録の流れを試しましょう。'
                  : _completed
                  ? '完了した課題は「完了」から確認できます。チェックを外すと未完了に戻せます。'
                  : '「今日」「明日」で締切を確認。提出したら左のチェックを付けます。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
