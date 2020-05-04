import 'package:flutter/widgets.dart';
import 'package:org_flutter/src/controller.dart';

const Pattern kDefaultSearchQuery = '';
const bool kDefaultHideMarkup = false;

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
      return OrgSettingsData(
        child: child,
        searchQuery: kDefaultSearchQuery,
        hideMarkup: kDefaultHideMarkup,
      );
    } else {
      return ValueListenableBuilder<Pattern>(
        valueListenable: controller.searchQuery,
        builder: (context, searchQuery, _child) {
          return ValueListenableBuilder<bool>(
            valueListenable: controller.hideMarkup,
            builder: (context, hideMarkup, _child) {
              return OrgSettingsData(
                searchQuery: searchQuery,
                hideMarkup: hideMarkup,
                child: child,
              );
            },
          );
        },
      );
    }
  }
}

class OrgSettingsData extends InheritedWidget {
  const OrgSettingsData({
    @required Widget child,
    @required this.searchQuery,
    @required this.hideMarkup,
    Key key,
  })  : assert(searchQuery != null),
        assert(hideMarkup != null),
        super(key: key, child: child);

  final Pattern searchQuery;
  final bool hideMarkup;

  @override
  bool updateShouldNotify(OrgSettingsData oldWidget) =>
      searchQuery != oldWidget.searchQuery ||
      hideMarkup != oldWidget.hideMarkup;
}
