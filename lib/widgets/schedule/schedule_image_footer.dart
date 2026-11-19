import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Branding included in saved and shared timetable images.
class ScheduleImageFooter extends StatelessWidget {
  const ScheduleImageFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: SizedBox(
          height: 20,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    'assets/icons/app_launcher_icon.png',
                    width: 20,
                    height: 20,
                    semanticLabel: 'CIT App',
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'CIT App-千葉工大向け大学生活支援アプリ-',
                  maxLines: 1,
                  softWrap: false,
                  // 保存画像の署名は文字拡大時も一定の大きさで表示する。
                  textScaler: TextScaler.noScaling,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    height: 1.2,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 10),
                _StoreMark(
                  icon: FontAwesomeIcons.appStore,
                  label: 'App Store',
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                _StoreMark(
                  icon: FontAwesomeIcons.googlePlay,
                  label: 'Google Play',
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreMark extends StatelessWidget {
  const _StoreMark({
    required this.icon,
    required this.label,
    required this.color,
  });

  final FaIconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      image: true,
      excludeSemantics: true,
      child: FaIcon(icon, size: 16, color: color),
    );
  }
}
