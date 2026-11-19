import '../../widgets/schedule/saturday_visibility_button.dart';
import '../../models/assignments/assignment.dart';
import '../../core/providers/assignment_notification_provider.dart';
import '../../models/schedule/academic_term.dart';
import '../../widgets/schedule/academic_term_selector.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/period_time_resolver.dart';
import '../../widgets/common/retained_async_view.dart';
import '../../widgets/notification/reminder_alarm_permission.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/schedule_provider.dart';
import '../../core/providers/auth_provider.dart' show firebaseAuthProvider;
import '../../core/providers/settings_provider.dart';
import '../../models/schedule/schedule_model.dart';
import '../../models/schedule/lecture_period_model.dart';
import '../../widgets/schedule/schedule_grid_widget.dart';
import '../../widgets/schedule/schedule_image_footer.dart';
import '../../widgets/schedule/schedule_class_move_dialog.dart';
import '../../widgets/schedule/semester_switch_button.dart';
import '../../widgets/assignments/assignment_flip_view.dart';
import '../../widgets/assignments/assignment_list.dart';
import '../../widgets/assignments/assignment_editor.dart';
import '../../widgets/assignments/assignment_header.dart';
import '../../core/providers/assignment_provider.dart';
import '../../widgets/schedule/excel_import_review_dialog.dart';
import '../../widgets/schedule/excel_import_semester_dialog.dart';
import 'schedule_edit_screen.dart';
import '../../core/providers/in_app_ad_provider.dart';
import '../../models/ads/in_app_ad_model.dart';
import '../../widgets/ads/in_app_ad_card.dart';
import '../../services/schedule/schedule_notification_service.dart';
import '../../services/schedule/schedule_service.dart';
import '../../services/schedule/schedule_image_save_service.dart';
import '../../services/schedule/excel_schedule_import_service.dart';
import '../../services/schedule/excel_import_feedback_service.dart';
import '../../services/schedule/attendance_service.dart';
import '../../services/schedule/lecture_period_service.dart';
import '../../services/widget/home_widgets_service.dart';
import 'attendance_management_screen.dart';
import 'attendance_qr_reader_screen.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key, this.semesterAnchorKey,
    this.assignmentAnchorKey, this.attendanceAnchorKey, this.editAnchorKey,
    this.shareAnchorKey, this.saturdayAnchorKey, this.excelImportAnchorKey});
  final GlobalKey? semesterAnchorKey;
  final GlobalKey? assignmentAnchorKey;
  final GlobalKey? attendanceAnchorKey;
  final GlobalKey? editAnchorKey;
  final GlobalKey? shareAnchorKey;
  final GlobalKey? saturdayAnchorKey;
  final GlobalKey? excelImportAnchorKey;

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

enum _ScheduleSheetAction { add, rename, delete }

enum _ScheduleExportAction { saveImage, share }

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  bool get _isEditMode => ref.read(scheduleEditingProvider);
  set _isEditMode(bool value) => ref.read(scheduleEditingProvider.notifier).state = value;
  bool _isExporting = false;
  bool _isUpdatingNotifications = false;
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
    final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (userId == null) return;
    try {
      final title = schedule == null ? '週間時間割' : _scheduleLabel(schedule);
      await HomeWidgetsService.updateWeeklyFullSchedule(
        schedule,
        userId: userId,
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
      debugPrint('🔕 学期切替: 通知 OFF のため再予約スキップ (schedule=${schedule.id})');
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
    ref.watch(scheduleEditingProvider);
    final showAssignments = ref.watch(assignmentViewOpenProvider);
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
    const headerActionsWidth = 4 * kMinInteractiveDimension;
    final headerTitleSpace = _isEditMode ? 88.0 : 8.0;
    final semesterButtonWidth = (MediaQuery.sizeOf(context).width -
            headerActionsWidth - headerTitleSpace)
        .clamp(96.0, 200.0);

    return Scaffold(
      appBar: !_isEditMode ? AssignmentHeader.appBar(context,
        semesterButton: KeyedSubtree(key: widget.semesterAnchorKey,
          child: userId == null ? const Text('時間割') :
            _buildHeaderScheduleChip(context, scheduleListAsync, userId)),
        toggleAnchorKey: widget.assignmentAnchorKey,
        showAssignments: showAssignments,
        onToggle: () {
          if (!_isExporting) {
            ref.read(assignmentViewOpenProvider.notifier).state = !showAssignments;
          }
        },
        actions: [
          IconButton(
            icon: Icon(ref.watch(scheduleNotificationEnabledProvider) || ref.watch(assignmentNotificationsEnabledProvider)
              ? Icons.notifications_active : Icons.notifications_off),
            tooltip: '時間割・課題の通知設定',
            onPressed: () {
              _showNotificationInfoDialog(context);
            },
          ),
          IconButton(key: widget.attendanceAnchorKey, icon: const Icon(Icons.fact_check_outlined),
            tooltip: '出欠管理', onPressed: () => _openAttendanceManagement(context)),
          IconButton(key: widget.editAnchorKey, icon: const Icon(Icons.edit), tooltip: '時間割を編集',
            onPressed: _isExporting ? null : () {
              ref.read(assignmentViewOpenProvider.notifier).state = false;
              setState(() => _isEditMode = true);
            }),
          IconButton(
            key: widget.shareAnchorKey,
            icon: const Icon(Icons.share),
            tooltip: '時間割を共有',
            onPressed: showAssignments || _isExporting
                ? null
                : () => _showScheduleExportSheet(context),
          ),
        ],
      ) : AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: userId != null && _isEditMode ? semesterButtonWidth : null,
        leading:
            userId != null && _isEditMode
                ? Padding(
                  padding: const EdgeInsets.only(left: 12, right: 4),
                  child: _buildHeaderScheduleChip(
                    context,
                    scheduleListAsync,
                    userId,
                  ),
                )
                : null,
        title: const Text(
                  '編集モード',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.black),
                ),
        titleSpacing: _isEditMode ? null : 12,
        centerTitle: false,
        backgroundColor: _isEditMode ? Colors.orange.shade50 : null,
        foregroundColor: _isEditMode ? Colors.black : null,
        actions: [
          // 土曜日表示切り替えボタン（編集モードのみ）
          if (_isEditMode)
            SaturdayVisibilityButton(
              key: widget.saturdayAnchorKey,
              visible: showSaturday,
              onPressed: () async {
                await ref.read(settingsProvider.notifier).toggleShowSaturday();
                if (!context.mounted) return;
                final visible = ref.read(showSaturdayProvider);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(visible ? '土曜日を表示しました' : '土曜日を非表示にしました'),
                  duration: const Duration(seconds: 2),
                ));
              },
            ),

          // Excelインポートボタン（編集モードのみ）
          if (_isEditMode)
            IconButton(
              key: widget.excelImportAnchorKey,
              icon: const Icon(Icons.upload_file),
              onPressed:
                  () => _pickAndImportExcel(context, _selectedScheduleId),
              tooltip: 'Excelから自動入力',
            ),

          // 編集/表示モード切り替えボタン
          if (_isEditMode) IconButton(
            icon: Icon(_isEditMode ? Icons.visibility : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isEditMode ? '講義をタップして編集、長押ししてドラッグで移動できます' : '表示モードに切り替えました',
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppColors.snackBarSurface(context, _isEditMode ? Colors.orange : Colors.blue),
                ),
              );
            },
            tooltip: _isEditMode ? '表示モードに切り替え' : '編集モードに切り替え',
          ),

          IconButton(icon: const Icon(Icons.clear_all), tooltip: '時間割をクリア',
            onPressed: () => _handleMenuAction(context, 'clear')),
        ],
      ),
      body:
          userId == null
              ? const Center(child: CircularProgressIndicator())
              : AssignmentFlipView(
                showAssignments: showAssignments,
                assignments: AssignmentBoard(
                  key: ValueKey('assignments-$userId'),
                  preferredSchedule: scheduleListAsync.valueOrNull?.isNotEmpty == true
                    ? _resolveSelectedSchedule(scheduleListAsync.valueOrNull!) : null,
                ),
                timetable: RetainedAsyncView<List<Schedule>>(
                value: scheduleListAsync,
                onRetry: () => ref.invalidate(scheduleListProvider(userId)),
                data: (schedules) {
                  if (schedules.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             Icon(
                              Icons.schedule,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '時間割データがありません',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '左上プルダウンで切替できる時間割を追加できます。',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                  final canShowAttendanceButton =
                      _isWithinConfiguredLecturePeriod(
                        settings: lecturePeriodAsync.valueOrNull,
                        semester: selectedSchedule.semester,
                      );
                  final showAttendanceActions = canShowAttendanceButton;
                  final adSection = scheduleAdAsync.when(
                    data:
                        (ad) =>
                            ad == null
                                ? const SizedBox.shrink()
                                : Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
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
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isEditMode && !_isExporting)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                                      child: Text('タップで編集・長押ししてドラッグで移動',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ScheduleGridWidget(
                                    schedule: selectedSchedule,
                                    onAddPeriod: () => _addPeriod(selectedSchedule),
                                    onRemovePeriod: () => _removePeriod(selectedSchedule),
                                    onAddAssignment: (lesson) => showAssignmentEditor(context, ref,
                                      schedule: selectedSchedule, lesson: lesson),
                                    onClassLongPress: (day, period, lesson) => _moveClass(
                                      selectedSchedule, day, period, lesson,
                                    ),
                                    onClassMove: (day, period, lesson, destinationDay, destinationPeriod) =>
                                        _saveMovedClass(selectedSchedule, day, period, lesson, destinationDay, destinationPeriod),
                                    onClassTap: (
                                      weekdayKey,
                                      period,
                                      scheduleClass,
                                    ) {
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
                                    onClassNotesSave: (
                                      weekdayKey,
                                      period,
                                      scheduleClass,
                                      notes,
                                    ) {
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
                                            ? (
                                              weekdayKey,
                                              period,
                                              scheduleClass,
                                            ) async {
                                              await _markAttendanceFromSchedule(
                                                context: context,
                                                schedule: selectedSchedule,
                                                weekdayKey: weekdayKey,
                                                period: period,
                                                scheduleClass: scheduleClass,
                                              );
                                            }
                                            : null,
                                    onLoadAttendanceSummary: (
                                      weekdayKey,
                                      period,
                                      scheduleClass,
                                    ) async {
                                      final userId = ref.read(
                                        currentUserIdProvider,
                                      );
                                      if (userId == null) {
                                        return const AttendanceClassSummary(
                                          presentCount: 0,
                                          lateCount: 0,
                                          absentCount: 0,
                                        );
                                      }
                                      final window =
                                          _attendanceSummaryWindowForSemester(
                                            settings:
                                                lecturePeriodAsync.valueOrNull,
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
                                    showAttendanceActions:
                                        showAttendanceActions,
                                    onLoadAttendanceSessions: (weekdayKey, period, scheduleClass) async {
                                      final userId = ref.read(currentUserIdProvider);
                                      if (userId == null || userId != selectedSchedule.userId) {
                                        throw StateError('ログイン状態を確認してください');
                                      }
                                      final settings = lecturePeriodAsync.valueOrNull ?? await LecturePeriodService.getLecturePeriod();
                                      final start = settings?.startDateForSemester(selectedSchedule.semester);
                                      if (start == null) return [];
                                      return AttendanceService.getClassAttendanceSessions(
                                        userId: userId,
                                        scheduleId: selectedSchedule.id,
                                        classId: scheduleClass.id,
                                        weekdayKey: weekdayKey,
                                        startPeriod: period,
                                        semesterStartDate: start,
                                      );
                                    },
                                    onSaveAttendanceStatus: (weekdayKey, period, scheduleClass, session, status) async {
                                      final userId = ref.read(currentUserIdProvider);
                                      if (userId == null || userId != selectedSchedule.userId) {
                                        throw StateError('ログイン状態を確認してください');
                                      }
                                      await AttendanceService.upsertAttendanceStatus(
                                        userId: userId,
                                        scheduleId: selectedSchedule.id,
                                        classId: scheduleClass.id,
                                        subjectName: scheduleClass.subjectName,
                                        weekdayKey: weekdayKey,
                                        startPeriod: period,
                                        duration: scheduleClass.duration,
                                        attendanceDate: session.date,
                                        status: status,
                                        existingRecordId: session.recordId,
                                      );
                                    },
                                    isEditMode: _isEditMode && !_isExporting,
                                    showSaturday: showSaturday,
                                    forceFullHeight: _isExporting,
                                    enableScroll: false,
                                  ),
                                  if (_isExporting)
                                    const ScheduleImageFooter(),
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
                error:
                    (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Icon(Icons.error, size: 64, color: AppColors.accent(context, Colors.red)),
                          const SizedBox(height: 16),
                          Text('エラーが発生しました: $error'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed:
                                () => ref.invalidate(
                                  scheduleListProvider(userId),
                                ),
                            child: const Text('再読み込み'),
                          ),
                        ],
                      ),
                    ),
              )),
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
    return schedule.name?.trim().isNotEmpty == true ? schedule.name! : schedule.semester;
  }

  Widget _buildHeaderScheduleChip(
    BuildContext context,
    AsyncValue<List<Schedule>> scheduleListAsync,
    String userId,
  ) {
    return scheduleListAsync.when(
      data: (schedules) {
        if (schedules.isEmpty) {
          return SemesterSwitchButton(label: '時間割を追加', onPressed: () => _showCreateScheduleDialog(context, userId, schedules));
        }
        final selected = _resolveSelectedSchedule(schedules);
        return SemesterSwitchButton(
          label: _scheduleLabel(selected),
          onPressed: () => _showScheduleSwitchSheet(
            context: context,
            userId: userId,
            schedules: schedules,
            selected: selected,
          ),
        );
      },
      loading:
          () => const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
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
    if (_isExporting) return;
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
                        icon: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.accent(context, Colors.red),
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
                style: FilledButton.styleFrom(foregroundColor: AppColors.onColor(Colors.red), backgroundColor: Colors.red),
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
    final input = await Navigator.of(context).push<({String name, AcademicTerm? term})>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (_) => _CreateScheduleInputPage(currentSchedules: currentSchedules),
      ),
    );

    if (input == null) return;

    try {
      final created = await ScheduleService.createNamedSchedule(
        userId: userId,
        name: input.name,
        semester: input.term?.label ?? input.name,
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
      semester: selected.semester,
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
      ref.read(selectedScheduleIdProvider.notifier).set(updatedSchedule.id);
      _syncWidgetsForSelectedSchedule(updatedSchedule);
      _rescheduleNotificationsForSchedule(updatedSchedule);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('時間割名を「${_scheduleLabel(updatedSchedule)}」に変更しました'),
        ),
      );
    });
  }

  Future<void> _showScheduleExportSheet(BuildContext context) async {
    if (_isExporting || ref.read(assignmentViewOpenProvider)) return;
    final canSaveToPhotos = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!canSaveToPhotos) {
      await _exportSchedule(context, saveToPhotos: false);
      return;
    }

    final action = await showModalBottomSheet<_ScheduleExportAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('画像で保存'),
                subtitle: const Text('端末の写真・ギャラリーに保存'),
                onTap: () => Navigator.of(sheetContext).pop(
                  _ScheduleExportAction.saveImage,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('他のアプリに共有'),
                onTap: () => Navigator.of(sheetContext).pop(
                  _ScheduleExportAction.share,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    await _exportSchedule(
      context,
      saveToPhotos: action == _ScheduleExportAction.saveImage,
    );
  }

  Future<void> _exportSchedule(
    BuildContext context, {
    required bool saveToPhotos,
  }) async {
    if (_isExporting || ref.read(assignmentViewOpenProvider)) return;
    if (_scheduleKey.currentContext == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('時間割が表示されてからもう一度お試しください')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final screenBox = context.findRenderObject() as RenderBox?;
    final shareOrigin = screenBox != null && screenBox.hasSize
        ? screenBox.localToGlobal(Offset.zero) & screenBox.size
        : null;
    setState(() => _isExporting = true);
    messenger
      ..clearSnackBars()
      ..removeCurrentSnackBar();
    final progress = messenger.showSnackBar(
      const SnackBar(
        content: Text('時間割の画像を作成中…'),
        duration: Duration(minutes: 1),
      ),
    );
    var progressClosed = false;
    unawaited(progress.closed.then<void>((_) => progressClosed = true));
    void dismissProgress() {
      if (!progressClosed && messenger.mounted) {
        progressClosed = true;
        progress.close();
      }
    }

    try {
      // フッターのアイコンも読み込んだ後、描画完了を待って全体を撮影する。
      await precacheImage(
        const AssetImage('assets/icons/app_launcher_icon.png'),
        context,
      );
      if (!mounted) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final boundary =
          _scheduleKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        throw StateError('時間割が表示されていません');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      late final Uint8List pngBytes;
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          throw StateError('画像データを作成できませんでした');
        }
        pngBytes = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );
      } finally {
        image.dispose();
      }
      if (!mounted) return;
      dismissProgress();
      final fileName =
          'cit_schedule_${DateTime.now().millisecondsSinceEpoch}.png';

      if (saveToPhotos) {
        await ScheduleImageSaveService.savePng(pngBytes, fileName: fileName);
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('時間割を写真・ギャラリーに保存しました')),
        );
      } else {
        final result = await Share.shareXFiles(
          [XFile.fromData(pngBytes, mimeType: 'image/png', name: fileName)],
          fileNameOverrides: [fileName],
          text: '時間割',
          subject: 'CIT App - 私の時間割',
          sharePositionOrigin: shareOrigin,
        );
        // キャンセルや結果不明の場合は共有完了と表示しない。
        if (mounted && result.status == ShareResultStatus.success) {
          messenger.showSnackBar(
            const SnackBar(content: Text('時間割を共有しました')),
          );
        }
      }
    } catch (error, stackTrace) {
      debugPrint('時間割画像の出力に失敗: $error\n$stackTrace');
      if (!mounted) return;
      final permissionDenied =
          error is PlatformException && error.code == 'permission_denied';
      dismissProgress();
      messenger.showSnackBar(
          SnackBar(
            content: Text(
              permissionDenied
                  ? '写真への保存が許可されていません。端末の設定でCIT Appの写真への追加を許可してください。'
                  : saveToPhotos
                      ? '時間割を保存できませんでした。もう一度お試しください。'
                      : '時間割を共有できませんでした。もう一度お試しください。',
            ),
          ),
        );
    } finally {
      dismissProgress();
      if (mounted) setState(() => _isExporting = false);
    }
  }
  Future<void> _pickAndImportExcel(
    BuildContext context,
    String? scheduleId,
  ) async {
    final canStartImport = await _showExcelImportTutorialDialog(context);
    if (canStartImport != true) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('時間割の取り込みにはログインが必要です')));
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

      final workbook = await ExcelScheduleImportService.parseWorkbookBytes(bytes);
      if (!context.mounted) return;
      if (workbook.semesters.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('大学の学生時間割表を確認できませんでした。Excelファイルを確認してください。')),
        );
        return;
      }
      final schedules = await ScheduleService.getAllSchedulesByUserId(userId);
      if (!context.mounted) return;
      if (schedules.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('先に取り込み先の時間割を作成してください')),
        );
        return;
      }
      final selection = await showExcelImportSemesterDialog(
        context,
        workbook: workbook,
        schedules: schedules,
        selectedScheduleId: scheduleId,
      );
      if (selection == null || !context.mounted) return;
      final draft = selection.source.draft;
      if (draft.entries.isEmpty) {
        final message =
            draft.warnings.isEmpty
                ? '取り込み可能な講義が見つかりませんでした'
                : draft.warnings.first;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        return;
      }

      final review = await showExcelImportReviewDialog(
        context,
        draft,
        sourceSemesterLabel: selection.source.label,
        targetScheduleLabel: _scheduleLabel(selection.target),
        onEditEntry: _showEditImportEntryDialog,
      );
      if (review == null) return;

      final applyResult = await ExcelScheduleImportService.applyImport(
        scheduleId: selection.target.id,
        entries: review.entries,
        clearExisting: review.clearExisting,
        autoColorAdjacent: review.autoColorAdjacent,
      );

      if (!mounted) return;
      setState(() => _selectedScheduleId = selection.target.id);
      await ref.read(selectedScheduleIdProvider.notifier).set(selection.target.id);
      if (!mounted) return;
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
              excelBytes: bytes,
              sourceSheetNames: selection.source.sourceSheetNames,
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
      final warningText =
          applyResult.warnings.isEmpty
              ? ''
              : '\n警告: ${applyResult.warnings.length}件';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Excel取り込みを適用しました（${applyResult.appliedCount}件）$warningText$trainingNotice',
          ),
          backgroundColor: AppColors.snackBarSurface(context, Colors.green),
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
        builder: (context) => AttendanceManagementScreen(schedule: schedule, onSettingsChanged: () {
          ref.invalidate(scheduleListProvider(schedule.userId));
          ref.invalidate(scheduleProvider(schedule.userId));
          ref.invalidate(currentUserSelectedTodayScheduleProvider);
          ref.invalidate(currentUserScheduleProvider);
        }),
      ),
    );
  }

  Future<bool?> _showExcelImportTutorialDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Excelインポート手順'),
            content: SizedBox(
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
                  Text('6. CIT AppでExcelを選び、取り込む学期と保存先を選択'),
                  SizedBox(height: 10),
                  Text(
                    '準備ができたら「準備できたのでインポート」を押してください。',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '注意: 自動判別で講義情報を抽出しているため、表示される情報が誤っている可能性があります。インポート後は情報に誤りがないか必ず確認してください。',
                    style: TextStyle(fontSize: 12, color: AppColors.accent(context, Colors.redAccent)),
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
                            decoration: const InputDecoration(
                              labelText: '教室情報',
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: weekdayKey,
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
                                  initialValue: startPeriod,
                                  decoration: const InputDecoration(
                                    labelText: '始点時限',
                                  ),
                                  items:
                                      List.generate(PeriodTimeResolver.maxPeriod, (i) => i + 1).map((p) {
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
                                  initialValue: duration,
                                  decoration: const InputDecoration(
                                    labelText: '連続コマ数',
                                  ),
                                  items:
                                      List.generate(5, (i) => i + 1).map((d) {
                                        return DropdownMenuItem<int>(
                                          value: d,
                                          child: Text('$dコマ'),
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
                  foregroundColor: AppColors.onColor(Colors.red),
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
                 Icon(Icons.construction, color: AppColors.accent(context, Colors.orange)),
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
                    color: AppColors.tintedSurface(context, Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: AppColors.accent(context, Colors.blue), size: 16),
                          SizedBox(width: 4),
                          Text(
                            '現在利用可能な機能',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.accent(context, Colors.blue),
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

  Future<void> _removePeriod(Schedule schedule) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('${schedule.periodCount}限を削除'),
      content: const Text('末尾の拡張時限を削除します。この時限にかかる講義は、連続講義も含めて時間割から削除されます。'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('削除'))],
    ));
    if (confirmed != true || !mounted) return;
    await _addPeriod(schedule, remove: true);
  }

  Future<void> _addPeriod(Schedule schedule, {bool remove = false}) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || userId != schedule.userId) {
      throw StateError('ログイン状態を確認してください');
    }
    final updated = remove
        ? await ScheduleService.removeLastPeriod(scheduleId: schedule.id, expectedPeriod: schedule.periodCount, removeClasses: true)
        : await ScheduleService.addPeriod(scheduleId: schedule.id);
    if (!mounted || ref.read(currentUserIdProvider) != userId) return;
    ref.invalidate(scheduleListProvider(userId));
    ref.invalidate(scheduleProvider(userId));
    ref.invalidate(weeklyScheduleProvider(userId));
    ref.invalidate(todayScheduleProvider(userId));
    ref.invalidate(nextClassProvider(userId));
    ref.invalidate(currentPeriodProvider(userId));
    ref.invalidate(todayScheduleByIdProvider(schedule.id));
    ref.invalidate(currentUserSelectedTodayScheduleProvider);
    ref.read(homeRefreshNotifierProvider.notifier).state++;
    await ref.read(scheduleListProvider(userId).future);
    if (!mounted || ref.read(currentUserIdProvider) != userId) return;
    _rescheduleNotificationsForSchedule(updated);
    unawaited(_syncWidgetsForSelectedSchedule(updated));
  }

  Future<void> _moveClass(Schedule schedule, String day, int period, ScheduleClass lesson) async {
    if (!_isEditMode) return;
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ScheduleClassMoveDialog(
        schedule: schedule, weekdayKey: day, period: period, scheduleClass: lesson,
        onMove: (destinationDay, destinationPeriod) => _saveMovedClass(
          schedule, day, period, lesson, destinationDay, destinationPeriod,
        ),
      ),
    );
  }

  Future<void> _saveMovedClass(
    Schedule schedule, String day, int period, ScheduleClass lesson,
    String destinationDay, int destinationPeriod,
  ) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || userId != schedule.userId) {
      throw StateError('ログイン状態を確認してください');
    }
    final updated = await ScheduleService.moveClass(
      scheduleId: schedule.id, fromWeekdayKey: day, fromPeriod: period,
      toWeekdayKey: destinationDay, toPeriod: destinationPeriod, expectedClass: lesson,
    );
    if (!mounted || ref.read(currentUserIdProvider) != userId) return;
    ref.invalidate(scheduleListProvider(userId));
    ref.invalidate(scheduleProvider(userId));
    ref.invalidate(weeklyScheduleProvider(userId));
    ref.invalidate(todayScheduleProvider(userId));
    ref.invalidate(nextClassProvider(userId));
    ref.invalidate(currentPeriodProvider(userId));
    ref.invalidate(todayScheduleByIdProvider(schedule.id));
    ref.invalidate(currentUserSelectedTodayScheduleProvider);
    ref.invalidate(currentUserTodayScheduleProvider);
    ref.invalidate(currentUserScheduleProvider);
    ref.invalidate(currentUserNextClassProvider);
    ref.invalidate(currentUserCurrentPeriodProvider);
    ref.read(homeRefreshNotifierProvider.notifier).state++;
    if (destinationDay == Weekday.saturday.name) {
      try {
        await ref.read(settingsProvider.notifier).setShowSaturday(true);
      } catch (error) {
        debugPrint('土曜日の表示設定を保存できませんでした: $error');
      }
    }
    if (!mounted || ref.read(currentUserIdProvider) != userId) return;
    _rescheduleNotificationsForSchedule(updated);
    unawaited(_syncWidgetsForSelectedSchedule(updated));
    final label = Weekday.values.firstWhere((value) => value.name == destinationDay).shortName;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${lesson.subjectName}を$label曜日 $destinationPeriod限に移動しました')),
      );
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('時間割の取得に失敗しました')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('QRリーダーを起動できませんでした: $e')));
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
          backgroundColor: AppColors.snackBarSurface(context, result.success ? Colors.green : Colors.orange),
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
    final isWeb =
        (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
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

    if (settings.periodForSemester(semester)?.isActive == false) return false;
    final start = settings.startDateForSemester(semester);
    final end = settings.endDateForSemester(semester);
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
    final start = settings.startDateForSemester(semester);
    final end = settings.endDateForSemester(semester);
    if (start == null || end == null) return null;

    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return DateTimeRange(start: startDay, end: endDay);
  }

  Future<void> _showNotificationInfoDialog(BuildContext context) async {
    final initialLectures = ref.read(scheduleNotificationEnabledProvider);
    final initialAssignments = ref.read(assignmentNotificationsEnabledProvider);
    var lectures = initialLectures;
    var assignments = initialAssignments;
    var checkingAlarmAccess = false;
    final save = await showDialog<bool>(context: context, builder: (dialogContext) =>
      StatefulBuilder(builder: (context, update) {
        Future<void> changeReminder(bool value, VoidCallback apply) async {
          if (!value) {
            update(apply);
            return;
          }
          update(() => checkingAlarmAccess = true);
          try {
            final allowed = await ensureReminderAlarmPermission(context);
            if (context.mounted && allowed) update(apply);
          } finally {
            if (context.mounted) update(() => checkingAlarmAccess = false);
          }
        }
        return AlertDialog(
        title: const Text('時間割・課題の通知'), scrollable: true,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('講義開始の通知'),
            subtitle: const Text('講義開始の15分前にお知らせ'), value: lectures,
            onChanged: checkingAlarmAccess ? null :
              (value) => changeReminder(value, () => lectures = value)),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('課題の締切通知も受け取る'),
            subtitle: const Text('締切の24時間前と1時間前。完了した課題は通知しません。時刻未設定の課題はその日の終了を締切として通知します。'), value: assignments,
            onChanged: checkingAlarmAccess ? null :
              (value) => changeReminder(value, () => assignments = value)),
          const Text('アプリを閉じていても端末から通知します。Androidでは「アラームとリマインダー」の許可が必要です。端末の省電力設定や強制停止により遅れることがあります。'),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('キャンセル')),
          FilledButton(onPressed: checkingAlarmAccess ? null :
            () => Navigator.pop(dialogContext, true), child: const Text('保存'))],
        );
      }));
    if (save != true || !context.mounted || _isUpdatingNotifications) return;
    _isUpdatingNotifications = true;
    try {
      final uid = ref.read(currentUserIdProvider);
      if (uid == null) throw StateError('ログイン状態を確認してください');
      if (lectures || assignments) {
        if ((lectures && !initialLectures) ||
            (assignments && !initialAssignments)) {
          if (!await ensureReminderAlarmPermission(context) || !mounted) {
            return;
          }
        }
        await ScheduleNotificationService.ensureNotificationAccess();
      }
      if (!mounted || ref.read(currentUserIdProvider) != uid) return;
      if (lectures) {
        final schedule = await ScheduleService.getSelectedScheduleByUserId(uid,
          selectedScheduleId: _selectedScheduleId);
        if (schedule == null) throw StateError('先に時間割を作成してください');
        await ScheduleNotificationService.scheduleWeeklyNotifications(schedule);
      } else {
        await ScheduleNotificationService.cancelAllNotifications();
      }
      if (!mounted || ref.read(currentUserIdProvider) != uid) return;
      await ref.read(setScheduleNotificationEnabledProvider)(lectures);
      final tasks = assignments ? await ref.read(userAssignmentsProvider(uid).future) : const <Assignment>[];
      await ScheduleNotificationService.scheduleAssignmentReminders(uid, tasks, enabled: assignments);
      if (!mounted || ref.read(currentUserIdProvider) != uid) return;
      await ref.read(setAssignmentNotificationsEnabledProvider)(assignments);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('通知設定を保存しました')));
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        error is StateError ? error.message.toString() : '通知を設定できませんでした。もう一度お試しください')));
    } finally { _isUpdatingNotifications = false; }
  }

}

class _CreateScheduleInputPage extends StatefulWidget {
  const _CreateScheduleInputPage({required this.currentSchedules});

  final List<Schedule> currentSchedules;

  @override
  State<_CreateScheduleInputPage> createState() =>
      _CreateScheduleInputPageState();
}

class _CreateScheduleInputPageState extends State<_CreateScheduleInputPage> {
  AcademicTerm? _term;
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
      (schedule) => (schedule.name ?? schedule.semester).trim().toLowerCase() == normalizedInput,
    );
    if (duplicateExists) {
      setState(() {
        _errorMessage = '同じ時間割名が既に存在します。違う名前を入力してください。';
      });
      return;
    }
    Navigator.of(context).pop((name: input, term: _term));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('時間割を追加'),
        actions: [TextButton(onPressed: _submit, child: const Text('追加'))],
      ),
      body: SingleChildScrollView(
        child: Padding(
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
            const SizedBox(height: 20),
            AcademicTermSelector(value: _term, optional: true, onChanged: (value) async {
              final enabling = _term == null && value != null;
              setState(() => _term = value);
              if (!enabling) return;
              final useName = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
                title: const Text('時間割名も変更しますか？'),
                content: Text('時間割名を「' + value.label + '」にしますか？あとから名前を変更できます。'),
                actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('現在の名前を使う')),
                  FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('年度・学期を名前にする'))],
              ));
              if (mounted && useName == true) _controller.text = value.label;
            }),
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
  State<_RenameScheduleInputPage> createState() =>
      _RenameScheduleInputPageState();
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
        _errorMessage = '時間割名を入力してください';
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
        title: const Text('時間割名を編集'),
        actions: [TextButton(onPressed: _submit, child: const Text('保存'))],
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
