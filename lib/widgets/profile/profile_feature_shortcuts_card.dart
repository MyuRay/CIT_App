import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/settings_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user/profile_shortcut.dart';
import '../../services/profile/profile_shortcut_launcher.dart';
import 'profile_highlight_badge.dart';

class ProfileFeatureShortcutsCard extends ConsumerStatefulWidget {
  const ProfileFeatureShortcutsCard({
    super.key,
    required this.themeModeNotifier,
    required this.themeMode,
    required this.appFontSize,
    required this.calendarWeekStart,
    required this.onThemeDialog,
    required this.onFontSizeDialog,
    required this.onCalendarDialog,
  });

  final ThemeModeNotifier themeModeNotifier;
  final ThemeMode themeMode;
  final AppFontSizeOption appFontSize;
  final CalendarWeekStart calendarWeekStart;
  final VoidCallback onThemeDialog;
  final VoidCallback onFontSizeDialog;
  final VoidCallback onCalendarDialog;

  @override
  ConsumerState<ProfileFeatureShortcutsCard> createState() =>
      _ProfileFeatureShortcutsCardState();
}

class _ProfileFeatureShortcutsCardState
    extends ConsumerState<ProfileFeatureShortcutsCard> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final visibleIds = ref.watch(profileShortcutVisibleIdsProvider);
    final visibleSet = visibleIds.toSet();
    final isDark = widget.themeModeNotifier.isDarkMode(context);

    final gridIds = _editing ? kProfileShortcutCatalog : visibleIds;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'よく使う機能',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _editing = !_editing),
                  child: Text(_editing ? '完了' : '編集'),
                ),
              ],
            ),
            if (_editing)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'タップして表示・非表示を切り替えます',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (!_editing && visibleIds.isEmpty)
              const _ProfileShortcutsEmptyState()
            else
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.92,
                children: [
                  for (final id in gridIds)
                    _ProfileShortcutTile(
                      id: id,
                      wigglePhase: id.index * 0.21,
                      subtitle: _subtitleFor(id, isDark),
                      iconColor: _iconColor(context, id),
                      icon: _iconFor(id, isDark),
                      editing: _editing,
                      emphasized:
                          ref.watch(profileShortcutEmphasizedProvider(id)),
                      visible: visibleSet.contains(id),
                      onToggle:
                          _editing
                              ? () async {
                                try {
                                  await ref.read(toggleProfileShortcutProvider)(
                                    id,
                                  );
                                } catch (_) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('保存できませんでした'),
                                    ),
                                  );
                                }
                              }
                              : null,
                      onTap:
                          _editing
                              ? null
                              : () => ProfileShortcutLauncher.open(
                                context,
                                ref,
                                id,
                                openThemeDialog: widget.onThemeDialog,
                                openFontSizeDialog: widget.onFontSizeDialog,
                                openCalendarDialog: widget.onCalendarDialog,
                              ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String? _subtitleFor(ProfileShortcutId id, bool isDark) {
    return switch (id) {
      ProfileShortcutId.theme =>
        widget.themeModeNotifier.currentThemeDisplayName,
      ProfileShortcutId.fontSize => widget.appFontSize.displayName,
      ProfileShortcutId.calendar => widget.calendarWeekStart.displayName,
      _ => null,
    };
  }

  IconData _iconFor(ProfileShortcutId id, bool isDark) {
    return switch (id) {
      ProfileShortcutId.myCafeteria => Icons.restaurant,
      ProfileShortcutId.assignments => Icons.assignment_outlined,
      ProfileShortcutId.contact => Icons.help_center_outlined,
      ProfileShortcutId.theme => isDark ? Icons.dark_mode : Icons.light_mode,
      ProfileShortcutId.fontSize => Icons.format_size,
      ProfileShortcutId.calendar => Icons.calendar_month,
      ProfileShortcutId.classroomMap => Icons.map_outlined,
      ProfileShortcutId.attendance => Icons.fact_check_outlined,
    };
  }

  Color _iconColor(BuildContext context, ProfileShortcutId id) {
    return switch (id) {
      ProfileShortcutId.myCafeteria =>
        AppColors.accent(context, Colors.pink),
      ProfileShortcutId.assignments =>
        AppColors.accent(context, Colors.indigo),
      ProfileShortcutId.contact => AppColors.accent(context, Colors.blue),
      ProfileShortcutId.theme =>
        AppColors.accent(context, Colors.deepPurple),
      ProfileShortcutId.fontSize =>
        AppColors.accent(context, Colors.orange),
      ProfileShortcutId.calendar => AppColors.accent(context, Colors.teal),
      ProfileShortcutId.classroomMap =>
        AppColors.accent(context, Colors.green),
      ProfileShortcutId.attendance =>
        AppColors.accent(context, Colors.blueGrey),
    };
  }
}

class _ProfileShortcutTile extends StatefulWidget {
  const _ProfileShortcutTile({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.editing,
    required this.emphasized,
    required this.visible,
    required this.wigglePhase,
    this.subtitle,
    this.onTap,
    this.onToggle,
  });

  final ProfileShortcutId id;
  final IconData icon;
  final Color iconColor;
  final String? subtitle;
  final bool editing;
  final bool emphasized;
  final bool visible;
  final double wigglePhase;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;

  @override
  State<_ProfileShortcutTile> createState() => _ProfileShortcutTileState();
}

class _ProfileShortcutTileState extends State<_ProfileShortcutTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wiggleController;

  @override
  void initState() {
    super.initState();
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _syncWiggleAnimation();
  }

  bool get _shouldWiggle => widget.editing && widget.visible;

  void _syncWiggleAnimation() {
    if (_shouldWiggle) {
      if (!_wiggleController.isAnimating) {
        _wiggleController.value = widget.wigglePhase % 1.0;
        _wiggleController.repeat(reverse: true);
      }
    } else {
      _wiggleController
        ..stop()
        ..value = 0;
    }
  }

  @override
  void didUpdateWidget(covariant _ProfileShortcutTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editing != widget.editing ||
        oldWidget.visible != widget.visible) {
      _syncWiggleAnimation();
    }
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showEmphasis = widget.emphasized && !widget.editing;
    final borderColor =
        widget.editing
            ? (widget.visible ? scheme.primary : scheme.outlineVariant)
            : scheme.outlineVariant;
    final borderWidth = widget.editing && widget.visible ? 1.5 : 1.0;
    final opacity = widget.editing && !widget.visible ? 0.45 : 1.0;

    final tile = Opacity(
      opacity: opacity,
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: borderColor,
            width: borderWidth,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.editing ? widget.onToggle : widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox.expand(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    8,
                    widget.editing ? 14 : 10,
                    8,
                    8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ShortcutIconBadge(
                        icon: widget.icon,
                        iconColor: widget.iconColor,
                        size: 40,
                        iconSize: 22,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.id.label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontSize: 9,
                                height: 1.1,
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.editing)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(
                      widget.visible
                          ? Icons.check_circle
                          : Icons.add_circle_outline,
                      size: 18,
                      color:
                          widget.visible
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                    ),
                  )
                else if (showEmphasis)
                  const Positioned(
                    top: 4,
                    right: 4,
                    child: ProfileHighlightBadge(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!_shouldWiggle) return tile;

    return AnimatedBuilder(
      animation: _wiggleController,
      builder: (context, child) {
        final t = _wiggleController.value * 2 * math.pi;
        final angle = math.sin(t + widget.wigglePhase) * 0.014;
        return Transform.rotate(angle: angle, child: child);
      },
      child: tile,
    );
  }
}

class _ProfileShortcutsEmptyState extends StatelessWidget {
  const _ProfileShortcutsEmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.grid_view_rounded,
            size: 36,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            '表示中の機能がありません',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '右上の「編集」から、表示する機能を選べます。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ShortcutIconBadge extends StatelessWidget {
  const _ShortcutIconBadge({
    required this.icon,
    required this.iconColor,
    required this.size,
    required this.iconSize,
  });

  final IconData icon;
  final Color iconColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(icon, size: iconSize, color: iconColor),
    );
  }
}
