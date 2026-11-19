import 'package:flutter/material.dart';

class BulletinReportButton extends StatelessWidget {
  const BulletinReportButton({super.key, required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'この投稿を通報',
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.flag_outlined, size: 18),
        label: const Text('通報'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          foregroundColor: colors.onSurfaceVariant,
          side: BorderSide(color: colors.outlineVariant),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}
