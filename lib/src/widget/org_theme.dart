import 'package:flutter/material.dart';
import 'package:org_flutter/src/theme.dart';

/// The theme for the Org Mode document
class OrgTheme extends InheritedWidget {
  const OrgTheme({
    required super.child,
    required this.light,
    required this.dark,
    super.key,
  });

  static OrgTheme of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OrgTheme>()!;

  /// Throws an exception if OrgTheme is not found in the context.
  static OrgThemeData dataOf(BuildContext context) {
    final theme = of(context);
    final brightness = Theme.of(context).brightness;
    switch (brightness) {
      case Brightness.dark:
        return theme.dark;
      case Brightness.light:
        return theme.light;
    }
  }

  final OrgThemeData light;
  final OrgThemeData dark;

  @override
  bool updateShouldNotify(OrgTheme oldWidget) =>
      light != oldWidget.light || dark != oldWidget.dark;
}
