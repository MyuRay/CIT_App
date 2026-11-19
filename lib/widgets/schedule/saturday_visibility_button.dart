import 'package:flutter/material.dart';

class SaturdayVisibilityButton extends StatelessWidget {
  const SaturdayVisibilityButton({
    super.key,
    required this.visible,
    required this.onPressed,
  });
  final bool visible;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton.filledTonal(
      isSelected: visible,
      tooltip: visible ? '土曜日を非表示' : '土曜日を表示',
      onPressed: onPressed,
      icon: const Text(
        '土',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor:
            visible ? colors.secondaryContainer : colors.surfaceContainerLow,
        foregroundColor:
            visible ? colors.onSecondaryContainer : colors.onSurfaceVariant,
        side: BorderSide(
          color: visible ? colors.secondary : colors.outlineVariant,
        ),
      ),
    );
  }
}
