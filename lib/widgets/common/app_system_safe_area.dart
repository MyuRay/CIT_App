import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keeps every route and overlay clear of the system navigation controls.
///
/// Place this above the router/Navigator so dialogs and bottom sheets share the
/// same bounds. Top insets remain available to each screen's AppBar/SafeArea.
class AppSystemSafeArea extends StatelessWidget {
  const AppSystemSafeArea({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.colorScheme.surface;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            theme.brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
        systemNavigationBarContrastEnforced: true,
      ),
      child: ColoredBox(
        color: backgroundColor,
        // SafeArea consumes padding once, including side navigation bars in
        // landscape. Use padding rather than viewPadding so keyboard insets
        // remain the responsibility of Scaffolds and input sheets below us.
        child: SafeArea(top: false, child: child),
      ),
    );
  }
}
