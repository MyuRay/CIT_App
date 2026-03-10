import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/schedule/schedule_model.dart';
import '../../core/providers/schedule_provider.dart';
import '../../services/schedule/schedule_service.dart';

class ScheduleEditScreen extends ConsumerStatefulWidget {
  final String scheduleId;
  final String weekdayKey;
  final int period;
  final ScheduleClass? initialClass;

  const ScheduleEditScreen({
    super.key,
    required this.scheduleId,
    required this.weekdayKey,
    required this.period,
    this.initialClass,
  });

  @override
  ConsumerState<ScheduleEditScreen> createState() => _ScheduleEditScreenState();
}

class _ScheduleEditScreenState extends ConsumerState<ScheduleEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _subjectController;
  late TextEditingController _classroomController;
  late TextEditingController _instructorController;
  late TextEditingController _notesController;
  
  String _selectedColor = '#2196F3';
  int _selectedDuration = 1; // 1=単体、2=2時間連続、3=3時間連続、4=4時間連続
  bool _isLoading = false;

  final List<String> _colorOptions = [
    '#2196F3', // Blue
    '#4CAF50', // Green
    '#FF9800', // Orange
    '#F44336', // Red
    '#9C27B0', // Purple
    '#607D8B', // Blue Grey
    '#795548', // Brown
    '#E91E63', // Pink
    '#00BCD4', // Cyan
    '#8BC34A', // Light Green
  ];

  final Map<String, String> _weekdayNames = {
    'monday': '月曜日',
    'tuesday': '火曜日',
    'wednesday': '水曜日',
    'thursday': '木曜日',
    'friday': '金曜日',
    'saturday': '土曜日',
  };

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.initialClass?.subjectName ?? '');
    _classroomController = TextEditingController(text: widget.initialClass?.classroom ?? '');
    _instructorController = TextEditingController(text: widget.initialClass?.instructor ?? '');
    _notesController = TextEditingController(text: widget.initialClass?.notes ?? '');
    _selectedColor = widget.initialClass?.color ?? '#2196F3';
    _selectedDuration = widget.initialClass?.duration ?? 1;
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _classroomController.dispose();
    _instructorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Widget _buildDurationButton(int duration, String label, IconData icon) {
    final isSelected = _selectedDuration == duration;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDuration = duration;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeSlots = ref.watch(timeSlotsProvider);
    final periodSlot = timeSlots.firstWhere((slot) => slot.period == widget.period);
    final weekdayName = _weekdayNames[widget.weekdayKey] ?? widget.weekdayKey;

    return Scaffold(
      appBar: AppBar(
        title: Text('${weekdayName} ${widget.period}限の編集'),
        foregroundColor: Colors.black,
        actions: [
          // 右上に保存ボタンを配置（新規/編集どちらでも表示）
          OutlinedButton(
            onPressed: _isLoading ? null : _saveClass,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black54),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: const StadiumBorder(),
              backgroundColor: Colors.white.withOpacity(0.9),
            ),
            child: const Text('保存', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (widget.initialClass != null)
            IconButton(
              icon: const Icon(Icons.delete),
              color: Colors.red,
              onPressed: _showDeleteDialog,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 時間枠情報
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '時間枠情報',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.schedule, color: Colors.black),
                        const SizedBox(width: 8),
                        Text('${weekdayName} ${widget.period}限'),
                        const Spacer(),
                        Text('${periodSlot.startTime} - ${periodSlot.endTime}'),
                      ],
                    ),
                    if (_selectedDuration > 1) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.timer, color: Colors.black),
                          const SizedBox(width: 8),
                          Text('連続講義範囲'),
                          const Spacer(),
                          Text(_getExtendedTimeRange()),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 講義時間選択
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '講義時間',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDurationButton(1, '1時間', Icons.schedule),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDurationButton(2, '2時間連続', Icons.schedule),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDurationButton(3, '3時間連続', Icons.schedule),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDurationButton(4, '4時間連続', Icons.schedule),
                        ),
                      ],
                    ),
                    if (_selectedDuration > 1) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info, size: 16, color: Colors.black),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '連続講義として複数の時限に登録されます',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 科目名
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: '科目名',
                hintText: '例: プログラミング基礎',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '科目名を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 教室
            TextFormField(
              controller: _classroomController,
              decoration: const InputDecoration(
                labelText: '教室',
                hintText: '例: A棟201',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '教室を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 担当教員（任意）
            TextFormField(
              controller: _instructorController,
              decoration: const InputDecoration(
                labelText: '担当教員（任意）',
                hintText: '例: 田中教授',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              // 任意入力のためバリデーションなし
            ),
            const SizedBox(height: 16),

            // 表示色選択
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '表示色',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _colorOptions.map((color) {
                        final isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(int.parse('0xff${color.substring(1)}')),
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.black, width: 3)
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 24,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // メモ（任意）
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'メモ（任意）',
                hintText: '持ち物・注意事項・資料URLなど (https://...)',
                helperText: 'URLを含めると表示時にタップできます',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 200,
            ),
            const SizedBox(height: 32),

            // 保存ボタン
            ElevatedButton(
              onPressed: _isLoading ? null : _saveClass,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.initialClass != null ? '更新' : '保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        throw Exception('ユーザーが認証されていません');
      }
      final classId = widget.initialClass?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final scheduleClass = ScheduleClass(
        id: classId,
        subjectName: _subjectController.text.trim(),
        classroom: _classroomController.text.trim(),
        instructor: _instructorController.text.trim(),
        color: _selectedColor,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        duration: _selectedDuration,
        isStartCell: true,
      );
      // 編集時はいったん既存の同一講義を削除してから再配置する
      if (widget.initialClass != null) {
        await ScheduleService.removeClass(
          scheduleId: widget.scheduleId,
          weekdayKey: widget.weekdayKey,
          period: widget.period,
        );
      }

      final latest = await ScheduleService.getScheduleById(widget.scheduleId);
      if (latest == null) {
        throw Exception('対象の時間割が見つかりません');
      }
      for (int i = 0; i < _selectedDuration; i++) {
        final currentPeriod = widget.period + i;
        if (currentPeriod > 10) {
          throw Exception('${_selectedDuration}時間連続講義は${widget.period}限から開始できません（10限を超えます）');
        }
        final existingClass = latest.timetable[widget.weekdayKey]?[currentPeriod];
        if (existingClass != null && existingClass.id != classId) {
          throw Exception('${currentPeriod}限には既に「${existingClass.subjectName}」が登録されています');
        }
      }

      for (int i = 0; i < _selectedDuration; i++) {
        final currentPeriod = widget.period + i;
        final classToAdd = ScheduleClass(
          id: classId,
          subjectName: scheduleClass.subjectName,
          classroom: scheduleClass.classroom,
          instructor: scheduleClass.instructor,
          color: scheduleClass.color,
          notes: scheduleClass.notes,
          duration: scheduleClass.duration,
          isStartCell: i == 0,
        );
        await ScheduleService.addOrUpdateClass(
          scheduleId: widget.scheduleId,
          weekdayKey: widget.weekdayKey,
          period: currentPeriod,
          scheduleClass: classToAdd,
        );
      }

      // ホーム画面のプロバイダーを無効化（即時反映のため）
      // 年度別切り替え機能を削除したので、常に現在の年度・学期を使用
      final currentYear = ref.read(currentAcademicYearProvider);
      print('📅 現在の年度・学期: ${currentYear.displayName}');
      
      // 常にホーム画面を更新
      ref.invalidate(currentUserTodayScheduleProvider);
      ref.invalidate(currentUserCurrentPeriodProvider);
      ref.invalidate(currentUserNextClassProvider);
      ref.invalidate(timeSlotsProvider);
      
      // 追加で基本プロバイダーも無効化
      if (userId != null) {
        ref.invalidate(todayScheduleProvider(userId));
        ref.invalidate(nextClassProvider(userId));
        ref.invalidate(currentPeriodProvider(userId));
        ref.invalidate(scheduleProvider(userId));
        ref.invalidate(weeklyScheduleProvider(userId));
        ref.invalidate(scheduleListProvider(userId));
      }
      
      // さらに、便利プロバイダーも無効化
      ref.invalidate(currentUserWeeklyScheduleProvider);
      ref.invalidate(currentUserScheduleProvider);
      
      print('✅ ホーム画面のプロバイダーを強制無効化しました');
      
      // グローバルなリフレッシュ通知を送信
      final currentRefresh = ref.read(homeRefreshNotifierProvider);
      ref.read(homeRefreshNotifierProvider.notifier).state = currentRefresh + 1;
      print('📡 ホーム画面リフレッシュ通知を送信しました');
      
      // 少し待ってから再度無効化（プロバイダーの更新を確実にするため）
      await Future.delayed(const Duration(milliseconds: 100));
      ref.invalidate(currentUserTodayScheduleProvider);
      ref.invalidate(currentUserCurrentPeriodProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.initialClass != null ? '科目を更新しました' : '科目を追加しました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('科目を削除'),
          ],
        ),
        content: Text('${widget.weekdayKey} ${widget.period}限の科目を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteClass();
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

  Future<void> _deleteClass() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        throw Exception('ユーザーが認証されていません');
      }
      await ScheduleService.removeClass(
        scheduleId: widget.scheduleId,
        weekdayKey: widget.weekdayKey,
        period: widget.period,
      );

      // ホーム画面のプロバイダーを無効化（即時反映のため）
      // 年度別切り替え機能を削除したので、常に現在の年度・学期を使用
      final currentYear = ref.read(currentAcademicYearProvider);
      print('📅 現在の年度・学期: ${currentYear.displayName}');
      
      // 常にホーム画面を更新
      ref.invalidate(currentUserTodayScheduleProvider);
      ref.invalidate(currentUserCurrentPeriodProvider);
      ref.invalidate(currentUserNextClassProvider);
      ref.invalidate(timeSlotsProvider);
      
      // 追加で基本プロバイダーも無効化
      if (userId != null) {
        ref.invalidate(todayScheduleProvider(userId));
        ref.invalidate(nextClassProvider(userId));
        ref.invalidate(currentPeriodProvider(userId));
        ref.invalidate(scheduleProvider(userId));
        ref.invalidate(weeklyScheduleProvider(userId));
        ref.invalidate(scheduleListProvider(userId));
      }
      
      // さらに、便利プロバイダーも無効化
      ref.invalidate(currentUserWeeklyScheduleProvider);
      ref.invalidate(currentUserScheduleProvider);
      
      print('✅ ホーム画面のプロバイダーを強制無効化しました');
      
      // グローバルなリフレッシュ通知を送信
      final currentRefresh = ref.read(homeRefreshNotifierProvider);
      ref.read(homeRefreshNotifierProvider.notifier).state = currentRefresh + 1;
      print('📡 ホーム画面リフレッシュ通知を送信しました');
      
      // 少し待ってから再度無効化（プロバイダーの更新を確実にするため）
      await Future.delayed(const Duration(milliseconds: 100));
      ref.invalidate(currentUserTodayScheduleProvider);
      ref.invalidate(currentUserCurrentPeriodProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('科目を削除しました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getExtendedTimeRange() {
    final timeSlots = ref.watch(timeSlotsProvider);
    final startSlot = timeSlots.firstWhere((slot) => slot.period == widget.period);
    final endPeriod = widget.period + _selectedDuration - 1;
    final endSlot = timeSlots.firstWhere(
      (slot) => slot.period == endPeriod,
      orElse: () => TimeSlot(
        period: endPeriod,
        startTime: '${endPeriod + 8}:00',
        endTime: '${endPeriod + 9}:00',
      ),
    );
    
    return '${widget.period}-${endPeriod}限 (${startSlot.startTime} - ${endSlot.endTime})';
  }
}
