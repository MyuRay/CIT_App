import '../../core/constants/home_feature_intro.dart';
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
  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeModeNotifier.isDarkMode(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '便利な機能・カスタマイズ',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.92,
              children: [
                for (final id in kProfileShortcutCatalog)
                  _ProfileShortcutTile(
                    id: id,
                    subtitle: _subtitleFor(id, isDark),
                    iconColor: _iconColor(context, id),
                    icon: _iconFor(id, isDark),
                    emphasized: ref.watch(
                      profileShortcutEmphasizedProvider(id),
                    ),
                    onTap:
                        () => ProfileShortcutLauncher.open(
                          context,
                          ref,
                          id,
                          openThemeDialog: widget.onThemeDialog,
                          openFontSizeDialog: widget.onFontSizeDialog,
                          openCalendarDialog: widget.onCalendarDialog,
                        ),
                  ),
                _ProfileShortcutTile(
                  label: '使い方ガイド',
                  icon: Icons.play_circle_outline,
                  iconColor: AppColors.accent(context, Colors.indigo),
                  emphasized: false,
                  onTap: () {
                    final replay = ref.read(
                      tabTutorialReplaySignalProvider.notifier,
                    );
                    final navigator = Navigator.of(context);
                    if (navigator.canPop()) navigator.pop();
                    replay.state++;
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(
                Icons.lightbulb_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Tipsを表示'),
              subtitle: const Text('ホームの吹き出しに使い方のヒントを表示します'),
              value: ref.watch(homeTipsEnabledProvider),
              onChanged: (enabled) async {
                try {
                  await ref
                      .read(settingsProvider.notifier)
                      .setHomeTipsEnabled(enabled);
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tipsの表示設定を保存できませんでした')),
                  );
                }
              },
            ),
            TextButton.icon(
              onPressed: () => showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
                title: const Text('Tips一覧'), scrollable: true,
                content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [for (final tip in kHomeTipIds) Padding(padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text('• ' + homeFeatureIntroMessage(tip).replaceAll('{menu}', '☰')))]),
                actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('閉じる'))],
              )),
              icon: const Icon(Icons.list_alt), label: const Text('Tips一覧を見る'),
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
      ProfileShortcutId.myCafeteria => AppColors.accent(context, Colors.pink),
      ProfileShortcutId.assignments => AppColors.accent(context, Colors.indigo),
      ProfileShortcutId.contact => AppColors.accent(context, Colors.blue),
      ProfileShortcutId.theme => AppColors.accent(context, Colors.deepPurple),
      ProfileShortcutId.fontSize => AppColors.accent(context, Colors.orange),
      ProfileShortcutId.calendar => AppColors.accent(context, Colors.teal),
      ProfileShortcutId.classroomMap => AppColors.accent(context, Colors.green),
      ProfileShortcutId.attendance => AppColors.accent(
        context,
        Colors.blueGrey,
      ),
    };
  }
}

class _ProfileShortcutTile extends StatelessWidget {
  const _ProfileShortcutTile({
    this.id,
    this.label,
    required this.icon,
    required this.iconColor,
    required this.emphasized,
    this.subtitle,
    this.onTap,
  });
  final ProfileShortcutId? id;
  final String? label;
  final IconData icon;
  final Color iconColor;
  final bool emphasized;
  final String? subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ShortcutIconBadge(
                    icon: icon,
                    iconColor: iconColor,
                    size: 40,
                    iconSize: 22,
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Text(
                      label ?? id!.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 9,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (emphasized)
              const Positioned(
                top: 4,
                right: 4,
                child: ProfileHighlightBadge(),
              ),
          ],
        ),
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
