import 'package:flutter/material.dart';

import '../../models/bulletin/bulletin_model.dart';
import 'bulletin_feed_card.dart';

/// Shows every category at once so none is hidden behind a horizontal scroll.
class BulletinCategoryGrid extends StatelessWidget {
  const BulletinCategoryGrid({
    super.key,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final String? selectedCategoryId;
  final ValueChanged<String?> onSelected;

  static const _columns = 4;

  /// Tile labels must fit a quarter of a phone width.
  static const _shortNames = {'club': 'サークル'};

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      BulletinCategoryTile(
        key: const ValueKey('bulletin-category-all'),
        label: 'すべて',
        semanticLabel: 'すべてのカテゴリ',
        icon: Icons.grid_view_rounded,
        selected: selectedCategoryId == null,
        onTap: () => onSelected(null),
      ),
      for (final category in BulletinCategories.all)
        BulletinCategoryTile(
          key: ValueKey('bulletin-category-${category.id}'),
          label: _shortNames[category.id] ?? category.name,
          semanticLabel: category.name,
          icon: bulletinCategoryIcon(category.icon),
          selected: selectedCategoryId == category.id,
          onTap: () => onSelected(category.id),
        ),
    ];
    final rows = <Widget>[];
    for (var start = 0; start < tiles.length; start += _columns) {
      if (start != 0) rows.add(const SizedBox(height: 8));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var column = 0; column < _columns; column++) ...[
                if (column != 0) const SizedBox(width: 8),
                Expanded(
                  child:
                      start + column < tiles.length
                          ? tiles[start + column]
                          : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        // Uniform, bounded labels keep the grid compact at large text sizes;
        // full names remain available to screen readers.
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: Column(mainAxisSize: MainAxisSize.min, children: rows),
        ),
      ),
    );
  }
}

class BulletinCategoryTile extends StatelessWidget {
  const BulletinCategoryTile({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = selected ? colors.onPrimary : colors.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: selected ? colors.primary : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: foreground),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
