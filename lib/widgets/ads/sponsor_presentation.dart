import 'package:flutter/material.dart';

/// Shared gold surfaces keep sponsor placements recognizable in both themes.
class SponsorPalette {
  const SponsorPalette._(this.surface, this.highlight, this.ink, this.border);
  factory SponsorPalette.of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const SponsorPalette._(
            Color(0xFF302715),
            Color(0xFF46371B),
            Color(0xFFFFE7A3),
            Color(0xFFE0B74C),
          )
          : const SponsorPalette._(
            Color(0xFFFFF4D5),
            Color(0xFFF2D78C),
            Color(0xFF503907),
            Color(0xFFA67A16),
          );
  final Color surface;
  final Color highlight;
  final Color ink;
  final Color border;

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, highlight, surface],
  );
}

class SponsorBanner extends StatelessWidget {
  const SponsorBanner({super.key, required this.name, this.compact = false});
  final String name;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = SponsorPalette.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 7 : 12,
      ),
      decoration: BoxDecoration(
        gradient: colors.gradient,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium_outlined, color: colors.ink, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name.trim().isEmpty ? 'スポンサー' : name.trim(),
              style: TextStyle(
                color: colors.ink,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 11 : 14,
              ),
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '広告',
            style: TextStyle(
              color: colors.ink,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// The same controls are used by bulletin and advertisement editors.
class SponsorFields extends StatelessWidget {
  const SponsorFields({
    super.key,
    required this.enabled,
    required this.nameController,
    required this.onChanged,
    this.onNameChanged,
    this.readOnly = false,
  });
  final bool enabled;
  final TextEditingController nameController;
  final ValueChanged<bool> onChanged;
  final ValueChanged<String>? onNameChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final colors = SponsorPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('金色のスポンサー枠'),
          subtitle: const Text('企業・店舗名と「広告」を表示します'),
          value: enabled,
          secondary: Icon(Icons.workspace_premium_outlined, color: colors.ink),
          onChanged: readOnly ? null : onChanged,
        ),
        if (enabled) ...[
          TextFormField(
            controller: nameController,
            enabled: !readOnly,
            maxLength: 80,
            onChanged: onNameChanged,
            decoration: const InputDecoration(
              labelText: 'スポンサー名',
              hintText: '企業名・店舗名',
              border: OutlineInputBorder(),
            ),
            validator:
                (value) =>
                    enabled && (value?.trim().isEmpty ?? true)
                        ? 'スポンサー名を入力してください'
                        : null,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
