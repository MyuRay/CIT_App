import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// アプリ全体で使用するフォントファミリー（Noto Sans JP）。
class AppFonts {
  AppFonts._();

  static String? get family => GoogleFonts.notoSansJp().fontFamily;

  static TextTheme textTheme(TextTheme base) {
    return GoogleFonts.notoSansJpTextTheme(base);
  }
}

class AppTheme {
  static const Color _seedColor = Color(0xFF1976D2);

  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
    );
    final textTheme = AppFonts.textTheme(base.textTheme).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
    final primaryTextTheme = AppFonts.textTheme(base.primaryTextTheme);

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: primaryTextTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(textStyle: textTheme.labelLarge),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(textStyle: textTheme.labelLarge),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: textTheme.labelLarge),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(color: colorScheme.error),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedLabelStyle: textTheme.labelSmall,
        unselectedLabelStyle: textTheme.labelSmall,
        backgroundColor: colorScheme.surface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        selectedLabelTextStyle: textTheme.labelSmall,
        unselectedLabelTextStyle: textTheme.labelSmall,
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
      ),
      dialogTheme: DialogThemeData(
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: colorScheme.onInverseSurface,
        closeIconColor: colorScheme.onInverseSurface,
      ),
      chipTheme: ChipThemeData(
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium,
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium,
        leadingAndTrailingTextStyle: textTheme.bodyMedium,
      ),
      popupMenuTheme: PopupMenuThemeData(textStyle: textTheme.bodyMedium),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        extendedTextStyle: textTheme.labelLarge,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      drawerTheme: DrawerThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: isDark ? 2 : 1,
      ),
      badgeTheme: BadgeThemeData(textStyle: textTheme.labelSmall),
      expansionTileTheme: ExpansionTileThemeData(
        textColor: colorScheme.onSurface,
        collapsedTextColor: colorScheme.onSurface,
      ),
    );
  }
}
