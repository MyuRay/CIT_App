import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Shared by lecture details and attendance management.
enum AttendanceStatusStyle {
  present('present', '出席', Colors.green, Icons.check_circle),
  late('late', '遅刻', Colors.orange, Icons.access_time_filled),
  absent('absent', '欠席', Colors.red, Icons.cancel),
  cancelled('cancelled', '休講', Colors.pink, Icons.event_busy),
  unrecorded(null, '未記録', Colors.grey, Icons.radio_button_unchecked);

  const AttendanceStatusStyle(this.value, this.label, this.color, this.icon);
  final String? value;
  final String label;
  final Color color;
  final IconData icon;

  static AttendanceStatusStyle fromValue(String? value) {
    if (value == null || value.isEmpty) return unrecorded;
    return values.firstWhere(
      (item) => item.value == value,
      orElse: () => absent,
    );
  }
}

class AttendanceStatusChip extends StatelessWidget {
  const AttendanceStatusChip({
    super.key,
    required this.status,
    required this.selected,
    this.onSelected,
  });
  final AttendanceStatusStyle status;
  final bool selected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final background = Color.alphaBlend(
      status.color.withValues(alpha: selected ? 0.28 : 0.12),
      Theme.of(context).colorScheme.surface,
    );
    final foreground = AppColors.ensureContrast(status.color, background);
    return ChoiceChip(
      label: Text(status.label),
      avatar: Icon(status.icon, color: foreground, size: 18),
      selected: selected,
      showCheckmark: false,
      onSelected: onSelected == null ? null : (_) => onSelected!(),
      backgroundColor: background,
      selectedColor: background,
      disabledColor: background,
      labelStyle: TextStyle(color: foreground, fontWeight: FontWeight.w700),
      checkmarkColor: foreground,
      side: BorderSide(
        color: foreground.withValues(alpha: selected ? 1 : 0.45),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }
}
