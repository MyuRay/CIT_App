import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/schedule_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../models/user/profile_shortcut.dart';
import '../../screens/cafeteria/cafeteria_my_screen.dart';
import '../../screens/contact/contact_form_screen.dart';
import '../../screens/schedule/attendance_management_screen.dart';
import '../../services/schedule/schedule_service.dart';
import '../../widgets/assignments/assignment_list.dart';

/// よく使う機能タップ時の画面遷移。
class ProfileShortcutLauncher {
  ProfileShortcutLauncher._();

  static Future<void> open(
    BuildContext context,
    WidgetRef ref,
    ProfileShortcutId id, {
    required void Function() openThemeDialog,
    required void Function() openFontSizeDialog,
    required void Function() openCalendarDialog,
  }) async {
    final opened = await switch (id) {
      ProfileShortcutId.myCafeteria => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const MyCafeteriaScreen()))
          .then((_) => true),
      ProfileShortcutId.assignments => Navigator.of(context)
          .push(
            MaterialPageRoute<void>(
              builder:
                  (_) => Scaffold(
                    appBar: AppBar(title: const Text('課題管理')),
                    body: const AssignmentBoard(),
                  ),
            ),
          )
          .then((_) => true),
      ProfileShortcutId.contact => _openContact(context, ref),
      ProfileShortcutId.theme => Future.sync(() {
        openThemeDialog();
        return true;
      }),
      ProfileShortcutId.fontSize => Future.sync(() {
        openFontSizeDialog();
        return true;
      }),
      ProfileShortcutId.calendar => Future.sync(() {
        openCalendarDialog();
        return true;
      }),
      ProfileShortcutId.classroomMap =>
        context.push('/classroom-map').then((_) => true),
      ProfileShortcutId.attendance => _openAttendanceManagement(context, ref),
    };

    if (opened) {
      await ref.read(dismissProfileShortcutHighlightProvider)(id);
    }
  }

  static Future<bool> _openContact(BuildContext context, WidgetRef ref) async {
    if (ref.read(currentUserIdProvider) != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ContactFormScreen()),
      );
    } else {
      await Navigator.of(context).pushNamed('/login');
    }
    return true;
  }

  static Future<bool> _openAttendanceManagement(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      await Navigator.of(context).pushNamed('/login');
      return true;
    }

    final schedules = await ScheduleService.getAllSchedulesByUserId(userId);
    if (!context.mounted) return false;
    if (schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('対象の時間割が見つかりません')),
      );
      return false;
    }

    final selectedId = ref.read(selectedScheduleIdProvider);
    final scheduleId =
        selectedId != null && schedules.any((s) => s.id == selectedId)
            ? selectedId
            : schedules.first.id;

    final schedule = await ScheduleService.getScheduleById(scheduleId);
    if (!context.mounted) return false;
    if (schedule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('時間割の読み込みに失敗しました')),
      );
      return false;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AttendanceManagementScreen(schedule: schedule),
      ),
    );
    return true;
  }
}
