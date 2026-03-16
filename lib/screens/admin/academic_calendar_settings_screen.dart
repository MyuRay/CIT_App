import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/schedule/academic_calendar_event_model.dart';
import '../../services/schedule/academic_calendar_service.dart';

class AcademicCalendarSettingsScreen extends StatefulWidget {
  const AcademicCalendarSettingsScreen({super.key});

  @override
  State<AcademicCalendarSettingsScreen> createState() =>
      _AcademicCalendarSettingsScreenState();
}

class _AcademicCalendarSettingsScreenState
    extends State<AcademicCalendarSettingsScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学年暦予定管理')),
      body: StreamBuilder<List<AcademicCalendarEvent>>(
        stream: AcademicCalendarService.watchAllEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('読み込みエラー: ${snapshot.error}'));
          }
          final events = snapshot.data ?? const <AcademicCalendarEvent>[];
          if (events.isEmpty) {
            return const Center(child: Text('登録済みの予定はありません'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 8,
                    backgroundColor: _colorFromHex(event.colorHex),
                  ),
                  title: Text(event.title),
                  subtitle: Text(
                    '${_formatDate(event.date)}${event.note.isNotEmpty ? '\n${event.note}' : ''}',
                  ),
                  isThreeLine: event.note.isNotEmpty,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await _showEditDialog(event: event);
                      } else if (value == 'delete') {
                        await _deleteEvent(event);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('編集'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('削除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : () => _showEditDialog(),
        icon:
            _saving
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : const Icon(Icons.add),
        label: const Text('予定を追加'),
      ),
    );
  }

  Future<void> _showEditDialog({AcademicCalendarEvent? event}) async {
    DateTime selectedDate =
        event?.date ?? DateTime(DateTime.now().year, DateTime.now().month, 1);
    final titleController = TextEditingController(text: event?.title ?? '');
    final noteController = TextEditingController(text: event?.note ?? '');
    String colorHex = event?.colorHex ?? '#E53935';

    await showDialog<void>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx, setDialogState) {
              return AlertDialog(
                title: Text(event == null ? '学年暦予定を追加' : '学年暦予定を編集'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020, 1, 1),
                            lastDate: DateTime(2100, 12, 31),
                          );
                          if (picked == null) return;
                          setDialogState(() {
                            selectedDate =
                                DateTime(picked.year, picked.month, picked.day);
                          });
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text('日付: ${_formatDate(selectedDate)}'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: '予定名 *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'メモ（任意）',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: colorHex,
                        decoration: const InputDecoration(
                          labelText: '表示色',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            const [
                                  '#E53935',
                                  '#1E88E5',
                                  '#43A047',
                                  '#FB8C00',
                                  '#8E24AA',
                                ]
                                .map(
                                  (hex) => DropdownMenuItem<String>(
                                    value: hex,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: _colorFromHex(hex),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(hex),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => colorHex = value);
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('キャンセル'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('予定名を入力してください')),
                        );
                        return;
                      }
                      Navigator.of(ctx).pop();
                      await _saveEvent(
                        event: event,
                        date: selectedDate,
                        title: title,
                        note: noteController.text.trim(),
                        colorHex: colorHex,
                      );
                    },
                    child: const Text('保存'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> _saveEvent({
    required AcademicCalendarEvent? event,
    required DateTime date,
    required String title,
    required String note,
    required String colorHex,
  }) async {
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final payload = AcademicCalendarEvent(
        id: event?.id ?? '',
        date: DateTime(date.year, date.month, date.day),
        title: title,
        note: note,
        colorHex: colorHex,
        updatedBy: uid,
      );
      await AcademicCalendarService.upsertEvent(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(event == null ? '予定を追加しました' : '予定を更新しました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存に失敗しました: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _deleteEvent(AcademicCalendarEvent event) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('予定を削除'),
            content: Text('「${event.title}」を削除しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('削除'),
              ),
            ],
          ),
    );
    if (ok != true) return;

    setState(() => _saving = true);
    try {
      await AcademicCalendarService.deleteEvent(event.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('予定を削除しました')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('削除に失敗しました: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  static Color _colorFromHex(String hex) {
    final raw = hex.replaceAll('#', '');
    final normalized = raw.length == 6 ? 'FF$raw' : raw;
    return Color(int.tryParse(normalized, radix: 16) ?? 0xFFE53935);
  }
}
