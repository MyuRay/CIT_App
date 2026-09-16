import 'package:flutter/material.dart';
import '../../models/admin/admin_destination.dart';
import '../../widgets/admin/admin_access_gate.dart';
import 'academic_calendar_settings_screen.dart';
import 'bulletin_approval_screen.dart';
import 'bulletin_management_screen.dart';
import 'bus_admin_screen.dart';
import 'contact_management_screen.dart';
import 'in_app_ad_management_screen.dart';
import 'lecture_period_settings_screen.dart';
import 'notification_management_screen.dart';
import 'user_management_screen.dart';
import '../reports/report_management_screen.dart';

class AdminDestinationPage extends StatelessWidget {
  const AdminDestinationPage({
    super.key,
    required this.destination,
    this.pendingOnly = false,
  });
  final AdminDestination destination;
  final bool pendingOnly;
  @override
  Widget build(BuildContext context) => AdminAccessGate(
    title: destination.title,
    builder:
        (_) => switch (destination) {
          AdminDestination.bulletin => const BulletinManagementScreen(),
          AdminDestination.ads => const InAppAdManagementScreen(),
          AdminDestination.notifications =>
            const NotificationManagementScreen(),
          AdminDestination.approvals => const BulletinApprovalScreen(),
          AdminDestination.contacts => ContactManagementScreen(
            initialStatus: pendingOnly ? 'pending' : null,
          ),
          AdminDestination.reports => const ReportManagementScreen(),
          AdminDestination.users => const UserManagementScreen(),
          AdminDestination.bus => const BusAdminScreen(),
          AdminDestination.lecturePeriod => const LecturePeriodSettingsScreen(),
          AdminDestination.calendar => const AcademicCalendarSettingsScreen(),
        },
  );
}
