import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/schedule/lecture_period_model.dart';
import '../../services/schedule/lecture_period_service.dart';

class LecturePeriodSettingsScreen extends StatefulWidget {
  const LecturePeriodSettingsScreen({super.key});

  @override
  State<LecturePeriodSettingsScreen> createState() =>
      _LecturePeriodSettingsScreenState();
}

class _LecturePeriodSettingsScreenState
    extends State<LecturePeriodSettingsScreen> {
  DateTime? _springStartDate;
  DateTime? _springEndDate;
  DateTime? _fallStartDate;
  DateTime? _fallEndDate;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('講義期間設定')),
      body: StreamBuilder<LecturePeriodSettings?>(
        stream: LecturePeriodService.watchLecturePeriod(),
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data != null &&
              _springStartDate == null &&
              _springEndDate == null &&
              _fallStartDate == null &&
              _fallEndDate == null) {
            _springStartDate = data.springStartDate;
            _springEndDate = data.springEndDate;
            _fallStartDate = data.fallStartDate;
            _fallEndDate = data.fallEndDate;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '講義期間（前期・後期）',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ホーム時間割カードの「第○週」表示に使われます。',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSemesterRow(
                        label: '前期',
                        start: _springStartDate,
                        end: _springEndDate,
                        onEdit: () => _showSemesterDialog(isSpring: true),
                      ),
                      const SizedBox(height: 10),
                      _buildSemesterRow(
                        label: '後期',
                        start: _fallStartDate,
                        end: _fallEndDate,
                        onEdit: () => _showSemesterDialog(isSpring: false),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label: Text(_isSaving ? '保存中...' : '保存'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSemesterRow({
    required String label,
    required DateTime? start,
    required DateTime? end,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label: ${_formatRange(start, end)}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onEdit,
            child: const Text('編集'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSemesterDialog({required bool isSpring}) async {
    DateTime? localStart = isSpring ? _springStartDate : _fallStartDate;
    DateTime? localEnd = isSpring ? _springEndDate : _fallEndDate;
    final now = DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('${isSpring ? '前期' : '後期'}の期間を編集'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  '開始日: ${localStart == null ? '未設定' : _formatDate(localStart!)}',
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: localStart ?? now,
                    firstDate: DateTime(now.year - 3, 1, 1),
                    lastDate: DateTime(now.year + 3, 12, 31),
                  );
                  if (picked == null) return;
                  setDialogState(() {
                    localStart = DateTime(picked.year, picked.month, picked.day);
                    if (localEnd != null && localEnd!.isBefore(localStart!)) {
                      localEnd = localStart;
                    }
                  });
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.stop),
                label: Text(
                  '終了日: ${localEnd == null ? '未設定' : _formatDate(localEnd!)}',
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: localEnd ?? (localStart ?? now),
                    firstDate: DateTime(now.year - 3, 1, 1),
                    lastDate: DateTime(now.year + 3, 12, 31),
                  );
                  if (picked == null) return;
                  setDialogState(() {
                    localEnd = DateTime(picked.year, picked.month, picked.day);
                  });
                },
              ),
              const SizedBox(height: 8),
              Text(_formatRange(localStart, localEnd)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  if (isSpring) {
                    _springStartDate = localStart;
                    _springEndDate = localEnd;
                  } else {
                    _fallStartDate = localStart;
                    _fallEndDate = localEnd;
                  }
                });
                Navigator.pop(ctx);
              },
              child: const Text('反映'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final hasOnlySpringOne = (_springStartDate == null) != (_springEndDate == null);
    final hasOnlyFallOne = (_fallStartDate == null) != (_fallEndDate == null);
    if (hasOnlySpringOne || hasOnlyFallOne) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('各学期は開始日と終了日をセットで設定してください')),
      );
      return;
    }
    if (_springStartDate != null &&
        _springEndDate != null &&
        _springStartDate!.isAfter(_springEndDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('前期の終了日は開始日以降にしてください')),
      );
      return;
    }
    if (_fallStartDate != null &&
        _fallEndDate != null &&
        _fallStartDate!.isAfter(_fallEndDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('後期の終了日は開始日以降にしてください')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await LecturePeriodService.updateLecturePeriod(
        springStartDate: _springStartDate,
        springEndDate: _springEndDate,
        fallStartDate: _fallStartDate,
        fallEndDate: _fallEndDate,
        updatedBy: FirebaseAuth.instance.currentUser?.uid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('講義期間を保存しました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String _formatRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '未設定';
    if (start == null || end == null) return '開始日/終了日を両方設定してください';
    return '${_formatDate(start)} - ${_formatDate(end)}';
  }
}
