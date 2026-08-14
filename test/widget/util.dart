import 'package:material_ui/material_ui.dart';

Widget wrap(Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Material(child: child),
  );
}
