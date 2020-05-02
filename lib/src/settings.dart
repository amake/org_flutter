import 'package:flutter/widgets.dart';
import 'package:org_flutter/src/controller.dart';

class OrgSettings extends StatelessWidget {
  const OrgSettings({@required this.child, Key key})
      : assert(child != null),
        super(key: key);

  static OrgSettingsData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OrgSettingsData>();

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = OrgController.of(context);
    if (controller == null) {
      return OrgSettingsData(child: child);
    } else {
      return ValueListenableBuilder<Pattern>(
        valueListenable: controller.searchQuery,
        builder: (context, searchQuery, _child) {
          return OrgSettingsData(
            searchQuery: searchQuery,
            child: child,
          );
        },
      );
    }
  }
}

class OrgSettingsData extends InheritedWidget {
  const OrgSettingsData({
    @required Widget child,
    this.searchQuery,
    Key key,
  }) : super(key: key, child: child);

  final Pattern searchQuery;

  @override
  bool updateShouldNotify(OrgSettingsData oldWidget) =>
      searchQuery != oldWidget.searchQuery;
}
