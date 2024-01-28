import 'package:flutter/material.dart';
import 'package:org_flutter/src/controller.dart';

typedef SearchResultKey = GlobalKey<SearchResultState>;

class SearchResult extends StatefulWidget {
  static Widget of(BuildContext context, {required Widget child}) =>
      SearchResult(
        key: OrgController.of(context).generateSearchResultKey(),
        child: child,
      );

  const SearchResult({required this.child, super.key});
  final Widget child;

  @override
  State<SearchResult> createState() => SearchResultState();
}

/// The state object for a search result. Consumers of
/// [OrgControllerData.searchResultKeys] can use [selected] to toggle focus
/// highlighting.
class SearchResultState extends State<SearchResult> {
  bool _selected = false;
  late OrgControllerData _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = OrgController.of(context);
  }

  bool get selected => _selected;

  set selected(bool value) {
    setState(() => _selected = value);
  }

  @override
  void dispose() {
    super.dispose();
    final key = widget.key;
    if (key is SearchResultKey) {
      _controller.removeSearchResultKey(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _selected
        ? DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 0.5,
              ),
            ),
            position: DecorationPosition.foreground,
            child: widget.child,
          )
        : widget.child;
  }
}
