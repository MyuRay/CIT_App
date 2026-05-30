import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/schedule_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../models/schedule/schedule_model.dart';
import '../../models/schedule/lecture_period_model.dart';
import '../../widgets/schedule/schedule_grid_widget.dart';
import 'schedule_edit_screen.dart';
import '../../core/providers/in_app_ad_provider.dart';
import '../../models/ads/in_app_ad_model.dart';
import '../../widgets/ads/in_app_ad_card.dart';
import '../../services/schedule/schedule_notification_service.dart';
import '../../services/schedule/schedule_service.dart';
import '../../services/schedule/excel_schedule_import_service.dart';
import '../../services/schedule/excel_import_feedback_service.dart';
import '../../services/schedule/attendance_service.dart';
import '../../services/widget/home_widgets_service.dart';
import 'attendance_management_screen.dart';
import 'attendance_qr_reader_screen.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

enum _ScheduleSheetAction { add, rename, delete }

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  bool _isEditMode = false;
  bool _isSharing = false; // 共有中フラグ
  String? _selectedScheduleId;
  final GlobalKey _scheduleKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectedScheduleId = ref.read(selectedScheduleIdProvider);
    // 画面起動時にもホームウィジェットへ最新の選択時間割を再同期する
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncWidgetsFromCurrentSelection();
    });
  }

  Future<void> _syncWidgetsFromCurrentSelection() async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        await _syncWidgetsForSelectedSchedule(null);
        return;
      }

      final schedules = await ScheduleService.getAllSchedulesByUserId(userId);
      if (schedules.isEmpty) {
        await _syncWidgetsForSelectedSchedule(null);
        return;
      }

      final selectedId = ref.read(selectedScheduleIdProvider);
      final selected =
          selectedId != null
              ? schedules.where((s) => s.id == selectedId).firstOrNull
              : null;
      await _syncWidgetsForSelectedSchedule(selected ?? schedules.first);
    } catch (e) {
      debugPrint('⚠️ 起動時ウィジェット同期に失敗: $e');
    }
  }

  Future<void> _syncWidgetsForSelectedSchedule(Schedule? schedule) async {
    try {
      final title = schedule == null ? '週間時間割' : _scheduleLabel(schedule);
      await HomeWidgetsService.updateWeeklyFullSchedule(
        schedule,
        scheduleTitle: title,
      );
      if (schedule == null) {
        await HomeWidgetsService.updateTodaySchedule(
          null,
          scheduleTitle: '今日の時間割',
        );
        return;
      }
      final todayClasses = ScheduleUtils.getTodayClasses(schedule);
      final currentPeriod = ScheduleUtils.getCurrentPeriod(schedule.timeSlots);
      await HomeWidgetsService.updateTodaySchedule(
        todayClasses,
        currentPeriod: currentPeriod,
        scheduleTitle: title,
      );
    } catch (e) {
      debugPrint('⚠️ 選択時間割のウィジェット同期に失敗: $e');
    }
  }

  /// 学期切替（時間割切替）後に、通知が ON ならば新しく選択された時間割で
  /// 講義通知を再予約する。古い学期の予約は内部で全キャンセルされる。
  void _rescheduleNotificationsForSchedule(Schedule schedule) {
    final notificationEnabled = ref.read(scheduleNotificationEnabledProvider);
    if (!notificationEnabled) {
      debugPrint(
        '🔕 学期切替: 通知 OFF のため再予約スキップ (schedule=${schedule.id})',
      );
      return;
    }
    debugPrint('🔁 学期切替: ${schedule.semester} (${schedule.id}) で通知を再予約します');
    // sync 文脈から呼ばれる想定なので fire-and-forget。
    () async {
      try {
        await ScheduleNotificationService.scheduleWeeklyNotifications(schedule);
      } catch (e) {
        debugPrint('⚠️ 学期切替後の通知再予約に失敗: $e');
      }
    }();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final showSaturday = ref.watch(showSaturdayProvider);
    final lecturePeriodAsync = ref.watch(lecturePeriodSettingsProvider);
    final scheduleListAsync =
        userId == null
            ? const AsyncValue<List<Schedule>>.loading()
            : ref.watch(scheduleListProvider(userId));
    final scheduleAdAsync = ref.watch(
      inAppAdProvider(AdPlacement.scheduleBottom),
    );

    return Scaffold(
      appBar: AppBar(
        leadingWidth: userId != null ? 138 : null,
        leading:
            userId != null
                ? Padding(
                  padding: const EdgeInsets.only(left: 6, right: 2),
                  child: _buildHeaderScheduleChip(
                    context,
                    scheduleListAsync,
                    userId,
                  ),
                )
                : null,
        title: _isEditMode
            ? const Text(
                '編集モード',
                style: TextStyle(color: Colors.black),
              )
            : const SizedBox.shrink(),
        centerTitle: true,
        backgroundColor: _isEditMode ? Colors.orange.shade50 : null,
        foregroundColor: _isEditMode ? Colors.black : null,
        actions: [
          // 講義通知ON/OFFボタン（表示モードのみ）
          if (!_isEditMode)
            Consumer(
              builder: (context, ref, child) {
                final notificationEnabled =
                    ref.watch(scheduleNotificationEnabledProvider);
                return IconButton(
                  icon: Icon(
                    notificationEnabled
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    color: notificationEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                  onPressed: () {
                    if (notificationEnabled) {
                      _showDisableNotificationDialog(context);
                    } else {
                      _showNotificationInfoDialog(context);
                    }
                  },
                  tooltip: notificationEnabled ? '講義通知をOFF' : '講義通知をON',
                );
              },
            ),

          // 土曜日表示切り替えボタン（編集モードのみ）
          if (_isEditMode)
            IconButton(
              icon: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          showSaturday
                              ? Theme.of(context).primaryColor.withOpacity(0.15)
                              : Colors.grey.withOpacity(0.15),
                      border: Border.all(
                        color:
                            showSaturday
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '土',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              showSaturday
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  if (!showSaturday)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Icon(
                        Icons.visibility_off,
                        size: 14,
                        color: Colors.red.shade700,
                      ),
                    ),
                ],
              ),
              onPressed: () async {
                await ref.read(settingsProvider.notifier).toggleShowSaturday();
                final newState = ref.read(showSaturdayProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(newState ? '土曜日を表示しました' : '土曜日を非表示にしました'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              tooltip: showSaturday ? '土曜日を非表示' : '土曜日を表示',
            ),

          // Excelインポートボタン（編集モードのみ）
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: () => _pickAndImportExcel(context, _selectedScheduleId),
              tooltip: 'Excelから自動入力',
            ),

          // 出欠管理ボタン（表示モード時のみ、編集/表示切替ボタンの左側）
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.fact_check_outlined),
              onPressed: () => _openAttendanceManagement(context),
              tooltip: '出欠管理',
            ),

          // 編集/表示モード切り替えボタン
          IconButton(
            icon: Icon(_isEditMode ? Icons.visibility : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isEditMode ? '編集モードに切り替えました' : '表示モードに切り替えました',
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: _isEditMode ? Colors.orange : Colors.blue,
                ),
              );
            },
            tooltip: _isEditMode ? '表示モードに切り替え' : '編集モードに切り替え',
          ),

          // 表示モード時のみ表示される共有ボタン
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareSchedule(context),
              tooltip: '時間割を共有',
            ),

          // 編集モード時のみ表示されるアクション
          if (_isEditMode) ...[
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(context, value),
              itemBuilder:
                  (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'clear',
                      child: Row(
                        children: [
                          Icon(Icons.clear_all),
                          SizedBox(width: 8),
                          Text('時間割をクリア'),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ],
      ),
      body: userId == null
          ? const Center(child: CircularProgressIndicator())
          : ref.watch(scheduleListProvider(userId)).when(
              data: (schedules) {
                if (schedules.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule, size: 64, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text('時間割データがありません', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Text(
                            '左上プルダウンで切替できる時間割を追加できます。',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('時間割を追加'),
                            onPressed:
                                () => _showCreateScheduleDialog(
                                  context,
                                  userId,
                                  schedules,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final selectedSchedule = _resolveSelectedSchedule(schedules);
                final canShowAttendanceButton = _isWithinConfiguredLecturePeriod(
                  settings: lecturePeriodAsync.valueOrNull,
                  semester: selectedSchedule.semester,
                );
                final showAttendanceActions = canShowAttendanceButton;
                final adSection = scheduleAdAsync.when(
                  data: (ad) => ad == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: InAppAdCard(
                            ad: ad,
                            placement: AdPlacement.scheduleBottom,
                          ),
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: RepaintBoundary(
                          key: _scheduleKey,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ScheduleGridWidget(
                                  schedule: selectedSchedule,
                                  onClassTap: (weekdayKey, period, scheduleClass) {
                                    _navigateToEdit(
                                      context,
                                      selectedSchedule.id,
                                      weekdayKey,
                                      period,
                                      scheduleClass,
                                    );
                                  },
                                  onEmptySlotTap: (weekdayKey, period) {
                                    _navigateToEdit(
                                      context,
                                      selectedSchedule.id,
                                      weekdayKey,
                                      period,
                                      null,
                                    );
                                  },
                                  onClassNotesSave:
                                      (weekdayKey, period, scheduleClass, notes) {
                                        return _saveClassNotesInline(
                                          context: context,
                                          schedule: selectedSchedule,
                                          weekdayKey: weekdayKey,
                                          period: period,
                                          scheduleClass: scheduleClass,
                                          notes: notes,
                                        );
                                      },
                                  onClassAttendanceTap:
                                      canShowAttendanceButton
                                          ? (weekdayKey, period, scheduleClass) async {
                                              await _markAttendanceFromSchedule(
                                                context: context,
                                                schedule: selectedSchedule,
                                                weekdayKey: weekdayKey,
                                                period: period,
                                                scheduleClass: scheduleClass,
                                              );
                                            }
                                          : null,
                                  onLoadAttendanceSummary:
                                      (weekdayKey, period, scheduleClass) async {
                                    final userId = ref.read(currentUserIdProvider);
                                    if (userId == null) {
                                      return const AttendanceClassSummary(
                                        presentCount: 0,
                                        lateCount: 0,
                                        absentCount: 0,
                                      );
                                    }
                                    final window = _attendanceSummaryWindowForSemester(
                                      settings: lecturePeriodAsync.valueOrNull,
                                      semester: selectedSchedule.semester,
                                    );
                                    if (window == null) {
                                      return AttendanceService.getClassAttendanceSummary(
                                        userId: userId,
                                        scheduleId: selectedSchedule.id,
                                        classId: scheduleClass.id,
                                      );
                                    }
                                    return AttendanceService.getClassAttendanceSummaryForRange(
                                      userId: userId,
                                      scheduleId: selectedSchedule.id,
                                      classId: scheduleClass.id,
                                      weekdayKey: weekdayKey,
                                      startPeriod: period,
                                      startDate: window.start,
                                      endDate: window.end,
                                    );
                                  },
                                  showAttendanceActions: showAttendanceActions,
                                  isEditMode: _isEditMode,
                                  showSaturday: showSaturday,
                                  forceFullHeight: _isSharing,
                                  enableScroll: false,
                                ),
                                if (_isSharing)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.1),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(8),
                                        bottomRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.school,
                                          size: 20,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'CIT App - 千葉工業大学 学生支援アプリ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      adSection,
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('エラーが発生しました: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(scheduleListProvider(userId)),
                      child: const Text('再読み込み'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Schedule _resolveSelectedSchedule(List<Schedule> schedules) {
    final selected = schedules.where((s) => s.id == _selectedScheduleId);
    if (selected.isNotEmpty) {
      return selected.first;
    }
    return schedules.first;
  }

  String _scheduleLabel(Schedule schedule) {
    return schedule.semester;
  }

  Widget _buildHeaderScheduleChip(
    BuildContext context,
    AsyncValue<List<Schedule>> scheduleListAsync,
    String userId,
  ) {
    return scheduleListAsync.when(
      data: (schedules) {
        if (schedules.isEmpty) {
          return const SizedBox.shrink();
        }
        final selected = _resolveSelectedSchedule(schedules);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap:
                () => _showScheduleSwitchSheet(
                  context: context,
                  userId: userId,
                  schedules: schedules,
                  selected: selected,
                ),
            child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: SizedBox(
            height: 14,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune,
                    size: 11,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 0.5),
                  Flexible(
                    child: Text(
                      '学期切替',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 15,
                        height: 1.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 0),
                  const Icon(Icons.expand_more, size: 11),
                ],
              ),
            ),
          ),
            ),
          ),
        );
      },
      loading:
          () => const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _showScheduleSwitchSheet({
    required BuildContext context,
    required String userId,
    required List<Schedule> schedules,
    required Schedule selected,
  }) async {
    final action = await showModalBottomSheet<_ScheduleSheetAction>(
      context: context,
      showDragHandle: true,
      builder:
          (sheetContext) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '学期切替',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...schedules.map((s) {
                          final isSelected = s.id == selected.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              materialTapTargetSize:
                                  MaterialTapTargetSize.padded,
                              visualDensity: VisualDensity.standard,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              label: Text(_scheduleLabel(s)),
                              selected: isSelected,
                              onSelected: (_) {
                                if (!mounted) return;
                                setState(() => _selectedScheduleId = s.id);
                                ref
                                    .read(selectedScheduleIdProvider.notifier)
                                    .set(s.id);
                                _syncWidgetsForSelectedSchedule(s);
                                _rescheduleNotificationsForSchedule(s);
                                Navigator.of(sheetContext).pop();
                              },
                            ),
                          );
                        }),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text('時間割を追加'),
                          onPressed: () {
                            Navigator.of(
                              sheetContext,
                            ).pop(_ScheduleSheetAction.add);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('選択中を編集'),
                        onPressed: () {
                          Navigator.of(
                            sheetContext,
                          ).pop(_ScheduleSheetAction.rename);
                        },
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.red,
                        ),
                        label: const Text('選択中を削除'),
                        onPressed: () {
                          Navigator.of(
                            sheetContext,
                          ).pop(_ScheduleSheetAction.delete);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );

    if (!mounted || action == null) return;
    switch (action) {
      case _ScheduleSheetAction.add:
        await _showCreateScheduleDialog(
          context,
          userId,
          List<Schedule>.from(schedules),
        );
        break;
      case _ScheduleSheetAction.rename:
        await _showRenameScheduleDialog(
          context: context,
          userId: userId,
          schedules: List<Schedule>.from(schedules),
          selected: selected,
        );
        break;
      case _ScheduleSheetAction.delete:
        await _showDeleteScheduleDialog(
          context: context,
          userId: userId,
          schedules: List<Schedule>.from(schedules),
          selected: selected,
        );
        break;
    }
  }

  Future<void> _showDeleteScheduleDialog({
    required BuildContext context,
    required String userId,
    required List<Schedule> schedules,
    required Schedule selected,
  }) async {
    if (schedules.length <= 1) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('削除できません'),
              content: const Text('最後の1件は削除できません'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('時間割を削除'),
            content: Text('「${_scheduleLabel(selected)}」を削除しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('削除'),
              ),
            ],
          ),
    );

    if (shouldDelete != true) return;

    await ScheduleService.deleteSchedule(selected.id);
    ref.invalidate(scheduleListProvider(userId));
    if (!mounted) return;
    setState(() => _selectedScheduleId = null);
    await ref.read(selectedScheduleIdProvider.notifier).set(null);
    await _syncWidgetsForSelectedSchedule(null);
    // 削除した時間割の予約済み通知が残らないようキャンセル
    debugPrint('🗑️ 時間割削除: 講義通知を全キャンセル (deleted=${selected.id})');
    unawaited(ScheduleNotificationService.cancelAllNotifications());
  }

  Future<void> _showCreateScheduleDialog(
    BuildContext context,
    String userId,
    List<Schedule> currentSchedules,
  ) async {
    final timetableName = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (_) => _CreateScheduleInputPage(currentSchedules: currentSchedules),
      ),
    );

    if (timetableName == null || timetableName.isEmpty) return;

    try {
      final created = await ScheduleService.createNamedSchedule(
        userId: userId,
        // 時間割名のみ管理するため、semesterに同じ値を保存する
        name: timetableName,
        semester: timetableName,
      );
      if (!mounted) return;
      setState(() => _selectedScheduleId = created.id);
      await ref.read(selectedScheduleIdProvider.notifier).set(created.id);
      ref.invalidate(scheduleListProvider(userId));
      await _syncWidgetsForSelectedSchedule(created);
      _rescheduleNotificationsForSchedule(created);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('追加に失敗しました: $e')));
    }
  }

  Future<void> _showRenameScheduleDialog({
    required BuildContext context,
    required String userId,
    required List<Schedule> schedules,
    required Schedule selected,
  }) async {
    final newName = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (_) => _RenameScheduleInputPage(
              currentSchedules: schedules,
              selectedScheduleId: selected.id,
              initialName: _scheduleLabel(selected),
            ),
      ),
    );
    if (newName == null || newName.isEmpty) return;
    if (!mounted) return;

    final updatedSchedule = Schedule(
      id: selected.id,
      userId: selected.userId,
      name: newName,
      semester: newName,
      timetable: selected.timetable,
      timeSlots: selected.timeSlots,
      createdAt: selected.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      await ScheduleService.updateSchedule(updatedSchedule);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('更新に失敗しました: $e')));
      return;
    }

    // ダイアログ破棄と同フレームで親画面更新すると、まれにSemantics assertが発生する。
    // 次フレームへずらして安全に反映する。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(scheduleListProvider(userId));
      setState(() => _selectedScheduleId = updatedSchedule.id);
      ref
          .read(selectedScheduleIdProvider.notifier)
          .set(updatedSchedule.id);
      _syncWidgetsForSelectedSchedule(updatedSchedule);
      _rescheduleNotificationsForSchedule(updatedSchedule);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('学期名を「${_scheduleLabel(updatedSchedule)}」に変更しました'),
        ),
      );
    });
  }

  // 時間割を共有する機能
  Future<void> _shareSchedule(BuildContext context) async {
    try {
      print('🔄 共有開始...');

      // ローディング表示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('時間割の画像を作成中...'),
              ],
            ),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.blue,
          ),
        );
      }

      // フッターを表示するためにUIを更新
      setState(() {
        _isSharing = true;
      });

      // UI更新を十分に待つ（レンダリング完了まで）
      await Future.delayed(const Duration(milliseconds: 500));

      // スクリーンショットを撮影
      final RenderObject? renderObject =
          _scheduleKey.currentContext?.findRenderObject();
      if (renderObject == null) {
        throw Exception('時間割表示エリアが見つかりません');
      }

      final RenderRepaintBoundary boundary =
          renderObject as RenderRepaintBoundary;
      print('📸 スクリーンショット撮影中...');

      // より高解像度で撮影（共有用）
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception('画像データの生成に失敗しました');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      print('✅ 画像生成完了: ${pngBytes.length}バイト');

      // 一時ディレクトリに画像を保存
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath =
          '${tempDir.path}/cit_schedule_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File(tempPath);
      await file.writeAsBytes(pngBytes);
      print('💾 画像保存完了: $tempPath');

      // フッターを非表示に戻す
      setState(() {
        _isSharing = false;
      });

      // 共有テキスト
      const String shareText =
          '私の時間割📚\n\nCIT Appで作成しました！\n\n'
          '📱 便利な機能：\n'
          '• 時間割管理\n'
          '• 掲示板\n'
          '• 学食情報\n'
          '• キャンパスマップ\n\n'
          '🔗 アプリをダウンロード: [🔎CIT App]';

      // share_plusを使った共有を再試行
      print('🚀 share_plus再試行中...');
      await _shareWithSharePlus(context, tempPath, shareText);

      print('✅ 共有完了');

      // 成功メッセージ
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('時間割を共有しました！'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ 共有エラー: $e');
      print('📍 スタックトレース: $stackTrace');

      // フッターを非表示に戻す
      setState(() {
        _isSharing = false;
      });

      if (context.mounted) {
        String errorMessage = '共有に失敗しました';

        if (e.toString().contains('Permission') ||
            e.toString().contains('permission')) {
          errorMessage = 'ストレージへのアクセス権限が必要です';
        } else if (e.toString().contains('No application')) {
          errorMessage = '共有できるアプリが見つかりません';
        } else if (e.toString().contains('見つかりません')) {
          errorMessage = '時間割が表示されていません。しばらく待ってから再試行してください。';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text(errorMessage)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'エラー詳細: ${e.toString().length > 100 ? e.toString().substring(0, 100) + '...' : e.toString()}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: '再試行',
              textColor: Colors.white,
              onPressed: () => _shareSchedule(context),
            ),
          ),
        );
      }
    }
  }

  // share_plusを使った共有機能（再試行版）
  Future<void> _shareWithSharePlus(
    BuildContext context,
    String imagePath,
    String shareText,
  ) async {
    try {
      print('🔄 複数の共有方法を試行中...');

      // 方法1: share_plusを試行
      try {
        final XFile imageFile = XFile(imagePath);
        await Share.shareXFiles(
          [imageFile],
          text: shareText,
          subject: 'CIT App - 私の時間割',
        );
        print('✅ share_plus成功');
        return;
      } catch (e1) {
        print('⚠️ share_plus失敗: $e1');
      }

      // 方法2: プラットフォームチャンネルを使用
      try {
        const platform = MethodChannel('flutter/share');
        await platform.invokeMethod('share', {
          'text': shareText,
          'subject': 'CIT App - 私の時間割',
        });
        print('✅ プラットフォームチャンネル成功（テキストのみ）');

        // 画像は別途ダイアログで案内
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('テキストを共有しました！画像は手動で添付してください'),
              backgroundColor: Colors.blue,
              action: SnackBarAction(
                label: '画像場所を表示',
                textColor: Colors.white,
                onPressed: () => _showImageLocation(context, imagePath),
              ),
            ),
          );
        }
        return;
      } catch (e2) {
        print('⚠️ プラットフォームチャンネル失敗: $e2');
      }

      // 方法3: フォールバック
      if (Platform.isAndroid) {
        await _shareOnAndroid(context, imagePath, shareText);
      } else {
        final imageBytes = await File(imagePath).readAsBytes();
        await _fallbackShare(context, imageBytes, shareText, imagePath);
      }
    } catch (e) {
      print('❌ すべての共有方法が失敗: $e');
      final imageBytes = await File(imagePath).readAsBytes();
      await _fallbackShare(context, imageBytes, shareText, imagePath);
    }
  }

  // 画像の場所を表示
  void _showImageLocation(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.image, color: Colors.blue),
                SizedBox(width: 8),
                Text('画像の場所'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('時間割画像は以下の場所に保存されています：'),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    imagePath,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'ファイルマネージャーでこの場所を開き、画像を手動で共有アプリに添付してください。',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: imagePath));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('パスをコピーしました'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: const Text('パスをコピー'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          ),
    );
  }

  // Android用の共有機能（標準共有ダイアログでLINEなどを選択可能）
  Future<void> _shareOnAndroid(
    BuildContext context,
    String imagePath,
    String shareText,
  ) async {
    try {
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('画像ファイルが見つかりません: $imagePath');
      }

      print('📱 Android共有機能を使用中...');

      // 複数の方法を試行する
      bool shared = false;

      // 方法1: 画像とテキストを同時に共有
      try {
        final AndroidIntent intent = AndroidIntent(
          action: 'android.intent.action.SEND',
          type: 'image/png',
          arguments: <String, dynamic>{
            'android.intent.extra.STREAM': imagePath,
            'android.intent.extra.TEXT': shareText,
            'android.intent.extra.SUBJECT': 'CIT App - 私の時間割',
          },
        );

        await intent.launch();
        shared = true;
        print('✅ 方法1成功: 画像とテキスト同時共有');
      } catch (e1) {
        print('⚠️ 方法1失敗: $e1');
      }

      // 方法2: 画像のみ共有
      if (!shared) {
        try {
          final AndroidIntent intent = AndroidIntent(
            action: 'android.intent.action.SEND',
            type: 'image/*',
            arguments: <String, dynamic>{
              'android.intent.extra.STREAM': imagePath,
              'android.intent.extra.SUBJECT': 'CIT App - 私の時間割',
            },
          );

          await intent.launch();
          shared = true;
          print('✅ 方法2成功: 画像のみ共有');

          // テキストは別途クリップボードにコピー
          await Clipboard.setData(ClipboardData(text: shareText));

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('画像を共有しました！テキストはクリップボードにコピー済みです'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } catch (e2) {
          print('⚠️ 方法2失敗: $e2');
        }
      }

      if (!shared) {
        throw Exception('すべての共有方法が失敗しました');
      }
    } catch (e) {
      print('❌ Android共有エラー: $e');
      // フォールバックに切り替え
      final imageBytes = await File(imagePath).readAsBytes();
      await _fallbackShare(context, imageBytes, shareText, imagePath);
    }
  }

  // 外部ストレージに画像をコピー（共有用）
  Future<String> _copyToExternalStorage(File imageFile) async {
    try {
      // Downloadsフォルダに一時的にコピー
      final Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        throw Exception('外部ストレージにアクセスできません');
      }

      final String fileName =
          'cit_schedule_${DateTime.now().millisecondsSinceEpoch}.png';
      final String externalPath = '${externalDir.path}/$fileName';
      final File externalFile = File(externalPath);

      await imageFile.copy(externalPath);
      print('📂 外部ストレージにコピー完了: $externalPath');

      return externalPath;
    } catch (e) {
      print('⚠️ 外部ストレージコピー失敗、元のパスを使用: $e');
      return imageFile.path;
    }
  }

  // フォールバック共有機能（画像保存 + テキストコピー + 案内表示）
  Future<void> _fallbackShare(
    BuildContext context,
    Uint8List imageBytes,
    String shareText,
    String imagePath,
  ) async {
    try {
      // 画像をクリップボードにコピー（テスト用）
      await Clipboard.setData(ClipboardData(text: shareText));

      if (context.mounted) {
        // 共有方法の選択ダイアログを表示
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.share, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('時間割を共有'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '時間割画像を作成しました！\n以下の方法で共有できます：',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Text(
                                '画像の場所',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '画像は以下のパスに保存されました：\n$imagePath',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.copy, color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text(
                                '共有テキスト（コピー済み）',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              shareText,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      // テキストを再度クリップボードにコピー
                      await Clipboard.setData(ClipboardData(text: shareText));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('テキストをクリップボードにコピーしました'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: const Text('テキストをコピー'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('閉じる'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      print('フォールバック共有エラー: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('共有に失敗しました: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _pickAndImportExcel(
    BuildContext context,
    String? scheduleId,
  ) async {
    final canStartImport = await _showExcelImportTutorialDialog(context);
    if (canStartImport != true) return;

    String? targetScheduleId = scheduleId;
    if (targetScheduleId == null) {
      targetScheduleId = await _resolveImportTargetScheduleId();
    }

    if (targetScheduleId == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('先に対象の時間割を選択してください')));
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Excelファイルの読み込みに失敗しました')));
        return;
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Excelを解析中です...'),
          duration: Duration(seconds: 1),
        ),
      );

      final draft = await ExcelScheduleImportService.parseExcelBytes(bytes);
      if (!context.mounted) return;
      if (draft.entries.isEmpty) {
        final message = draft.warnings.isEmpty
            ? '取り込み可能な講義が見つかりませんでした'
            : draft.warnings.first;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        return;
      }

      final review = await _showImportReviewDialog(context, draft);
      if (review == null) return;

      final applyResult = await ExcelScheduleImportService.applyImport(
        scheduleId: targetScheduleId,
        entries: review.entries,
        clearExisting: review.clearExisting,
        autoColorAdjacent: review.autoColorAdjacent,
      );

      final currentUserId = ref.read(currentUserIdProvider);
      if (currentUserId != null) {
        ref.invalidate(scheduleListProvider(currentUserId));
      }

      String trainingNotice = '';
      if (review.provideTrainingData) {
        if (currentUserId == null) {
          trainingNotice = '\n学習データ送信: 未ログインのためスキップ';
        } else {
          try {
            await ExcelImportFeedbackService.submitTrainingSample(
              userId: currentUserId,
              originalFileName: file.name,
              excelBytes: bytes,
              autoExtractedEntries: draft.entries,
              reviewedEntries: review.entries,
              parserWarnings: draft.warnings,
            );
            trainingNotice = '\n学習データ送信: 完了';
          } catch (_) {
            trainingNotice = '\n学習データ送信: 失敗（インポートは完了）';
          }
        }
      }

      if (!context.mounted) return;
      final warningText = applyResult.warnings.isEmpty
          ? ''
          : '\n警告: ${applyResult.warnings.length}件';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Excel取り込みを適用しました（${applyResult.appliedCount}件）$warningText$trainingNotice',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Excel取り込み中にエラー: $e')));
    }
  }

  Future<void> _openAttendanceManagement(BuildContext context) async {
    final scheduleId = await _resolveImportTargetScheduleId();
    if (scheduleId == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('対象の時間割が見つかりません')));
      return;
    }

    final schedule = await ScheduleService.getScheduleById(scheduleId);
    if (schedule == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('時間割の読み込みに失敗しました')));
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AttendanceManagementScreen(schedule: schedule),
      ),
    );
  }

  Future<bool?> _showExcelImportTutorialDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Excelインポート手順'),
            content: const SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('以下の手順でExcelファイルを準備してください。'),
                  SizedBox(height: 10),
                  Text('1. CITポータルにログイン'),
                  Text('2. 「教務関連」を開く'),
                  Text('3. 「学生時間割」を開く'),
                  Text('4. 開講年度学期でインポートしたい学期を表示'),
                  Text('   （必ず前期/後期を選択してください）'),
                  Text('5. 右上の「Excel」ボタンからエクスポート'),
                  Text('6. CIT Appへインポート'),
                  SizedBox(height: 10),
                  Text(
                    '準備ができたら「準備できたのでインポート」を押してください。',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '注意: 自動判別で講義情報を抽出しているため、表示される情報が誤っている可能性があります。インポート後は情報に誤りがないか必ず確認してください。',
                    style: TextStyle(fontSize: 12, color: Colors.redAccent),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('キャンセル'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                icon: const Icon(Icons.upload_file),
                label: const Text('準備できたのでインポート'),
              ),
            ],
          ),
    );
  }

  Future<String?> _resolveImportTargetScheduleId() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return null;

    final schedules = await ScheduleService.getAllSchedulesByUserId(userId);
    if (schedules.isEmpty) return null;

    final selectedId = _selectedScheduleId;
    if (selectedId != null && schedules.any((s) => s.id == selectedId)) {
      return selectedId;
    }

    // 画面上で現在表示される先頭学期へ自動適用
    final fallbackId = schedules.first.id;
    if (mounted) {
      setState(() => _selectedScheduleId = fallbackId);
    }
    await ref.read(selectedScheduleIdProvider.notifier).set(fallbackId);
    final fallbackSchedule = schedules.firstWhere((s) => s.id == fallbackId);
    _syncWidgetsForSelectedSchedule(fallbackSchedule);
    _rescheduleNotificationsForSchedule(fallbackSchedule);
    return fallbackId;
  }

  Future<_ImportReviewResult?> _showImportReviewDialog(
    BuildContext context,
    ScheduleImportDraft draft,
  ) {
    final entries = List<ImportedScheduleEntry>.from(draft.entries);
    bool clearExisting = false;
    bool autoColorAdjacent = true;
    bool provideTrainingData = true;
    final warnings = List<String>.from(draft.warnings);

    return showDialog<_ImportReviewResult>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: const Text('Excel取り込みの確認'),
                content: SizedBox(
                  width: 640,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('抽出件数: ${entries.length}件'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: clearExisting,
                            onChanged: (value) {
                              setDialogState(() {
                                clearExisting = value ?? false;
                              });
                            },
                          ),
                          const Expanded(
                            child: Text('既存の時間割をクリアしてから適用する'),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: autoColorAdjacent,
                            onChanged: (value) {
                              setDialogState(() {
                                autoColorAdjacent = value ?? true;
                              });
                            },
                          ),
                          const Expanded(
                            child: Text('上下左右で隣接する講義を自動色分けする'),
                          ),
                        ],
                      ),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 4, bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: provideTrainingData,
                              onChanged: (value) {
                                setDialogState(() {
                                  provideTrainingData = value ?? false;
                                });
                              },
                            ),
                            const Expanded(
                              child: Text(
                                '抽出精度向上のため、個人情報（Excelファイルのsheet1/sheet2のI4・AG4）を匿名化したデータを提供する',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (warnings.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Text(
                            '解析時の警告: ${warnings.join(' / ')}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: entries.length,
                          separatorBuilder:
                              (_, __) => const Divider(height: 1),
                          itemBuilder: (itemContext, index) {
                            final e = entries[index];
                            return ListTile(
                              dense: true,
                              title: Text(
                                '${_weekdayLabel(e.weekdayKey)} ${e.startPeriod}限 (${e.duration}コマ) ${e.subjectName}',
                              ),
                              subtitle: Text(
                                '講師: ${e.instructor.isEmpty ? '未設定' : e.instructor} / 教室: ${e.classroom.isEmpty ? '未設定' : e.classroom}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () async {
                                      final edited =
                                          await _showEditImportEntryDialog(
                                            dialogContext,
                                            e,
                                          );
                                      if (edited == null) return;
                                      setDialogState(() {
                                        entries[index] = edited;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setDialogState(() {
                                        entries.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('キャンセル'),
                  ),
                  FilledButton(
                    onPressed:
                        entries.isEmpty
                            ? null
                            : () {
                              Navigator.of(dialogContext).pop(
                                _ImportReviewResult(
                                  entries: entries,
                                  clearExisting: clearExisting,
                                  autoColorAdjacent: autoColorAdjacent,
                                  provideTrainingData: provideTrainingData,
                                ),
                              );
                            },
                    child: const Text('この内容で適用'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<ImportedScheduleEntry?> _showEditImportEntryDialog(
    BuildContext context,
    ImportedScheduleEntry entry,
  ) {
    final subjectController = TextEditingController(text: entry.subjectName);
    final instructorController = TextEditingController(text: entry.instructor);
    final classroomController = TextEditingController(text: entry.classroom);
    String weekdayKey = entry.weekdayKey;
    int startPeriod = entry.startPeriod;
    int duration = entry.duration;

    return showDialog<ImportedScheduleEntry>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (dialogContext, setDialogState) => AlertDialog(
                  title: const Text('取り込み内容を編集'),
                  content: SingleChildScrollView(
                    child: SizedBox(
                      width: 420,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: subjectController,
                            decoration: const InputDecoration(labelText: '講義名'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: instructorController,
                            decoration: const InputDecoration(labelText: '講師名'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: classroomController,
                            decoration: const InputDecoration(labelText: '教室情報'),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: weekdayKey,
                            decoration: const InputDecoration(labelText: '曜日'),
                            items:
                                const [
                                  'monday',
                                  'tuesday',
                                  'wednesday',
                                  'thursday',
                                  'friday',
                                  'saturday',
                                ].map((key) {
                                  return DropdownMenuItem<String>(
                                    value: key,
                                    child: Text(_weekdayLabelStatic(key)),
                                  );
                                }).toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setDialogState(() => weekdayKey = v);
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: startPeriod,
                                  decoration: const InputDecoration(
                                    labelText: '始点時限',
                                  ),
                                  items:
                                      List.generate(
                                        10,
                                        (i) => i + 1,
                                      ).map((p) {
                                        return DropdownMenuItem<int>(
                                          value: p,
                                          child: Text('$p限'),
                                        );
                                      }).toList(),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setDialogState(() => startPeriod = v);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: duration,
                                  decoration: const InputDecoration(
                                    labelText: '連続コマ数',
                                  ),
                                  items:
                                      List.generate(
                                        5,
                                        (i) => i + 1,
                                      ).map((d) {
                                        return DropdownMenuItem<int>(
                                          value: d,
                                          child: Text('${d}コマ'),
                                        );
                                      }).toList(),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setDialogState(() => duration = v);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('キャンセル'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(
                          ImportedScheduleEntry(
                            subjectName: subjectController.text.trim(),
                            instructor: instructorController.text.trim(),
                            classroom: classroomController.text.trim(),
                            weekdayKey: weekdayKey,
                            startPeriod: startPeriod,
                            duration: duration,
                          ),
                        );
                      },
                      child: const Text('更新'),
                    ),
                  ],
                ),
          ),
    );
  }

  String _weekdayLabel(String key) => _weekdayLabelStatic(key);

  static String _weekdayLabelStatic(String key) {
    switch (key) {
      case 'monday':
        return '月';
      case 'tuesday':
        return '火';
      case 'wednesday':
        return '水';
      case 'thursday':
        return '木';
      case 'friday':
        return '金';
      case 'saturday':
        return '土';
      default:
        return key;
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'clear':
        _showClearConfirmDialog(context, _selectedScheduleId);
        break;
    }
  }

  void _showClearConfirmDialog(BuildContext context, String? scheduleId) {
    if (scheduleId == null) return;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('時間割をクリア'),
            content: const Text('すべての科目を削除します。この操作は元に戻せません。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final userId = ref.read(currentUserIdProvider);
                  if (userId == null) return;
                  await ScheduleService.clearSchedule(scheduleId);
                  ref.invalidate(scheduleListProvider(userId));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('時間割をクリアしました')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('クリア'),
              ),
            ],
          ),
    );
  }

  void _showDevelopmentMessage(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.construction, color: Colors.orange),
                const SizedBox(width: 8),
                Text('$featureName（開発中）'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$featureNameは現在開発中です。',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '現在利用可能な機能',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text('• 手動での科目追加・編集・削除', style: TextStyle(fontSize: 12)),
                      Text(
                        '• リアルタイム同期によるデータ保存',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text('• カラー設定とメモ機能', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('了解'),
              ),
            ],
          ),
    );
  }

  void _navigateToEdit(
    BuildContext context,
    String scheduleId,
    String weekdayKey,
    int period,
    ScheduleClass? scheduleClass,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder:
            (context) => ScheduleEditScreen(
              scheduleId: scheduleId,
              weekdayKey: weekdayKey,
              period: period,
              initialClass: scheduleClass,
            ),
      ),
    );

    if (result == true) {
      // 時間割が更新された場合の処理（必要に応じて）
    }
  }

  Future<bool> _saveClassNotesInline({
    required BuildContext context,
    required Schedule schedule,
    required String weekdayKey,
    required int period,
    required ScheduleClass scheduleClass,
    required String? notes,
  }) async {
    try {
      final latest = await ScheduleService.getScheduleById(schedule.id);
      if (latest == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('時間割の取得に失敗しました')),
          );
        }
        return false;
      }

      final updatedTimetable = <String, Map<int, ScheduleClass?>>{};
      for (final dayEntry in latest.timetable.entries) {
        updatedTimetable[dayEntry.key] = <int, ScheduleClass?>{};
        for (final periodEntry in dayEntry.value.entries) {
          final value = periodEntry.value;
          if (dayEntry.key == weekdayKey &&
              value != null &&
              value.id == scheduleClass.id) {
            updatedTimetable[dayEntry.key]![periodEntry.key] = ScheduleClass(
              id: value.id,
              subjectName: value.subjectName,
              classroom: value.classroom,
              instructor: value.instructor,
              color: value.color,
              notes: notes,
              duration: value.duration,
              isStartCell: value.isStartCell,
            );
          } else {
            updatedTimetable[dayEntry.key]![periodEntry.key] = value;
          }
        }
      }

      final updatedSchedule = Schedule(
        id: latest.id,
        userId: latest.userId,
        name: latest.name,
        semester: latest.semester,
        timetable: updatedTimetable,
        timeSlots: latest.timeSlots,
        createdAt: latest.createdAt,
        updatedAt: DateTime.now(),
      );
      await ScheduleService.updateSchedule(updatedSchedule);

      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        ref.invalidate(scheduleListProvider(userId));
        ref.invalidate(scheduleProvider(userId));
        ref.invalidate(todayScheduleProvider(userId));
        ref.invalidate(currentPeriodProvider(userId));
        ref.invalidate(nextClassProvider(userId));
      }
      ref.invalidate(todayScheduleByIdProvider(schedule.id));
      ref.invalidate(currentUserSelectedTodayScheduleProvider);
      ref.invalidate(currentUserTodayScheduleProvider);
      ref.invalidate(currentUserScheduleProvider);
      // ホーム画面側も即時再取得させる
      ref.read(homeRefreshNotifierProvider.notifier).state++;

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('メモを更新しました')));
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('メモ更新に失敗しました: $e')));
      }
      return false;
    }
  }

  Future<void> _markAttendanceFromSchedule({
    required BuildContext context,
    required Schedule schedule,
    required String weekdayKey,
    required int period,
    required ScheduleClass scheduleClass,
  }) async {
    String? scannedRaw;
    try {
      scannedRaw = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const AttendanceQrReaderScreen()),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QRリーダーを起動できませんでした: $e')),
        );
      }
      return;
    }
    if (scannedRaw == null || scannedRaw.trim().isEmpty) return;
    await _openAttendancePortalFromQr(context: context, scannedRaw: scannedRaw);

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ログインが必要です')));
      }
      return;
    }

    try {
      final result = await AttendanceService.markAttendanceFromTap(
        userId: userId,
        scheduleId: schedule.id,
        schedule: schedule,
        weekdayKey: weekdayKey,
        startPeriod: period,
        scheduleClass: scheduleClass,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('出欠記録に失敗しました: $e')));
    }
  }

  Future<void> _openAttendancePortalFromQr({
    required BuildContext context,
    required String scannedRaw,
  }) async {
    final raw = scannedRaw.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    final isWeb = (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
    if (!isWeb) return;
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('出席サイトを開けませんでした')));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('出席サイトを開けませんでした: $e')));
    }
  }

  bool _isWithinConfiguredLecturePeriod({
    required LecturePeriodSettings? settings,
    required String semester,
    DateTime? now,
  }) {
    // 設定未取得/未設定時は従来どおり表示する
    if (settings == null) return true;
    final current = now ?? DateTime.now();
    final day = DateTime(current.year, current.month, current.day);

    final isFall = semester.contains('後期');
    final startRaw = isFall ? settings.fallStartDate : settings.springStartDate;
    final endRaw = isFall ? settings.fallEndDate : settings.springEndDate;
    final legacyStart = settings.lectureStartDate;
    final legacyEnd = settings.lectureEndDate;

    final start = startRaw ?? (!isFall ? legacyStart : null);
    final end = endRaw ?? (!isFall ? legacyEnd : null);
    if (start == null || end == null) return true;

    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return !day.isBefore(startDay) && !day.isAfter(endDay);
  }

  DateTimeRange? _attendanceSummaryWindowForSemester({
    required LecturePeriodSettings? settings,
    required String semester,
  }) {
    if (settings == null) return null;
    final isFall = semester.contains('後期');
    final startRaw = isFall ? settings.fallStartDate : settings.springStartDate;
    final endRaw = isFall ? settings.fallEndDate : settings.springEndDate;
    final legacyStart = settings.lectureStartDate;
    final legacyEnd = settings.lectureEndDate;

    final start = startRaw ?? (!isFall ? legacyStart : null);
    final end = endRaw ?? (!isFall ? legacyEnd : null);
    if (start == null || end == null) return null;

    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return DateTimeRange(start: startDay, end: endDay);
  }

  void _showNotificationInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.notifications,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('講義通知をONにしますか？'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '講義開始の約15分前に「次の講義名・教室・QRで出席」の通知を受け取ります。',
            ),
            SizedBox(height: 12),
            Text(
              '※ アプリの仕様上、講義開始後まで通知が遅れる可能性があります。',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _enableNotifications(context);
            },
            child: const Text('ONにする'),
          ),
        ],
      ),
    );
  }

  void _showDisableNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.notifications_off),
            const SizedBox(width: 8),
            const Text('講義通知をOFFにしますか？'),
          ],
        ),
        content: const Text('すべての講義通知がキャンセルされます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.grey.shade700),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _disableNotifications(context);
            },
            child: const Text('OFFにする'),
          ),
        ],
      ),
    );
  }

  Future<void> _enableNotifications(BuildContext context) async {
    await ref.read(setScheduleNotificationEnabledProvider)(true);

    final schedule = ref.read(currentUserScheduleProvider).maybeWhen(
          data: (value) => value,
          orElse: () => null,
        );
    if (schedule != null) {
      await ScheduleNotificationService.scheduleWeeklyNotifications(schedule);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('講義通知を有効にしました。講義開始まもなく通知します。'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('時間割データを読み込み中です。完了後に自動で通知を設定します。'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _disableNotifications(BuildContext context) async {
    await ref.read(setScheduleNotificationEnabledProvider)(false);
    await ScheduleNotificationService.cancelAllNotifications();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('講義通知を無効にしました。'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _CreateScheduleInputPage extends StatefulWidget {
  const _CreateScheduleInputPage({required this.currentSchedules});

  final List<Schedule> currentSchedules;

  @override
  State<_CreateScheduleInputPage> createState() => _CreateScheduleInputPageState();
}

class _CreateScheduleInputPageState extends State<_CreateScheduleInputPage> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorMessage = '時間割名を入力してください';
      });
      return;
    }
    final normalizedInput = input.toLowerCase();
    final duplicateExists = widget.currentSchedules.any(
      (schedule) => schedule.semester.trim().toLowerCase() == normalizedInput,
    );
    if (duplicateExists) {
      setState(() {
        _errorMessage = '同じ時間割名が既に存在します。違う名前を入力してください。';
      });
      return;
    }
    Navigator.of(context).pop(input);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('時間割を追加'),
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text('追加'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '時間割名',
                hintText: '例: 2026年前期 / 3s',
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RenameScheduleInputPage extends StatefulWidget {
  const _RenameScheduleInputPage({
    required this.currentSchedules,
    required this.selectedScheduleId,
    required this.initialName,
  });

  final List<Schedule> currentSchedules;
  final String selectedScheduleId;
  final String initialName;

  @override
  State<_RenameScheduleInputPage> createState() => _RenameScheduleInputPageState();
}

class _RenameScheduleInputPageState extends State<_RenameScheduleInputPage> {
  late final TextEditingController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorMessage = '学期名を入力してください';
      });
      return;
    }
    final normalizedInput = input.toLowerCase();
    final duplicateExists = widget.currentSchedules.any(
      (schedule) =>
          schedule.id != widget.selectedScheduleId &&
          schedule.semester.trim().toLowerCase() == normalizedInput,
    );
    if (duplicateExists) {
      setState(() {
        _errorMessage = '同じ学期名が既に存在します。違う名前を入力してください。';
      });
      return;
    }
    Navigator.of(context).pop(input);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学期名を編集'),
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text('保存'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '学期名',
                hintText: '例: 2026年前期 / 3s',
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImportReviewResult {
  const _ImportReviewResult({
    required this.entries,
    required this.clearExisting,
    required this.autoColorAdjacent,
    required this.provideTrainingData,
  });

  final List<ImportedScheduleEntry> entries;
  final bool clearExisting;
  final bool autoColorAdjacent;
  final bool provideTrainingData;
}
