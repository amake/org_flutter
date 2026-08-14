import 'package:material_ui/material_ui.dart';

Widget wrap(Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    // TODO(aaron): Remove this once flutter_slidable is updated to use material_ui
    // https://github.com/letsar/flutter_slidable/issues/548
    child: Localizations(
      delegates: GlobalMaterialLocalizations.delegates,
      locale: Locale('en', 'US'),
      child: Material(child: child),
    ),
  );
}
