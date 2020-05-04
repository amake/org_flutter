import 'package:flutter/widgets.dart';
import 'package:org_flutter/src/settings.dart';
import 'package:org_flutter/src/util.dart';
import 'package:org_parser/org_parser.dart';

enum OrgVisibilityState {
  /// Just the root headline; equivalent to global "overview" state
  folded,

  /// All headlines of all levels
  contents,

  /// All immediate children (subtrees folded)
  children,

  /// Everything
  subtree,
}

class OrgNode {
  OrgNode({OrgVisibilityState initialVisibility})
      : visibility = ValueNotifier(initialVisibility);
  final ValueNotifier<OrgVisibilityState> visibility;

  void dispose() => visibility.dispose();
}

Map<OrgTree, OrgNode> _buildNodeMap(OrgTree tree) {
  final map = <OrgTree, OrgNode>{};
  _walk(
    tree,
    (subtree) =>
        map[subtree] = OrgNode(initialVisibility: OrgVisibilityState.folded),
  );
  return map;
}

void _walk(OrgTree tree, Function(OrgTree) visit) {
  visit(tree);
  for (final child in tree.children) {
    _walk(child, visit);
  }
}

class OrgController extends StatefulWidget {
  OrgController.defaults(
    OrgControllerData data, {
    @required OrgTree root,
    @required Widget child,
    Key key,
  }) : this(
          child: child,
          root: root,
          initialSearchQuery: data.searchQuery.value,
          initiallyHideMarkup: data.hideMarkup.value,
          key: key,
        );

  const OrgController({
    @required this.child,
    @required this.root,
    this.initialSearchQuery,
    this.initiallyHideMarkup,
    Key key,
  })  : assert(child != null),
        assert(root != null),
        super(key: key);

  final OrgTree root;
  final Widget child;
  final Pattern initialSearchQuery;
  final bool initiallyHideMarkup;

  static OrgControllerData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OrgControllerData>();

  @override
  _OrgControllerState createState() => _OrgControllerState();
}

class _OrgControllerState extends State<OrgController> {
  Map<OrgTree, OrgNode> _nodeMap;
  ValueNotifier<Pattern> _searchQuery;
  ValueNotifier<bool> _hideMarkup;

  @override
  void initState() {
    super.initState();
    _nodeMap = _buildNodeMap(widget.root);
    _searchQuery =
        ValueNotifier(widget.initialSearchQuery ?? kDefaultSearchQuery);
    _hideMarkup =
        ValueNotifier(widget.initiallyHideMarkup ?? kDefaultHideMarkup);
  }

  @override
  void dispose() {
    for (final node in _nodeMap.values) {
      node.dispose();
    }
    _searchQuery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrgControllerData(
      child: widget.child,
      root: widget.root,
      nodeMap: _nodeMap,
      searchQuery: _searchQuery,
      hideMarkup: _hideMarkup,
    );
  }
}

class OrgControllerData extends InheritedWidget {
  OrgControllerData({
    @required Widget child,
    @required this.root,
    @required this.nodeMap,
    @required this.searchQuery,
    @required this.hideMarkup,
    Key key,
  })  : assert(root != null),
        assert(nodeMap != null),
        assert(searchQuery != null),
        assert(hideMarkup != null),
        super(key: key, child: child) {
    searchQuery.addListener(_updateVisibilityForQuery);
  }

  final OrgTree root;
  final Map<OrgTree, OrgNode> nodeMap;
  final ValueNotifier<Pattern> searchQuery;
  final ValueNotifier<bool> hideMarkup;

  OrgNode nodeFor(OrgTree tree) => nodeMap[tree];

  OrgSection sectionWithTitle(String title) =>
      nodeMap.keys.whereType<OrgSection>().firstWhere(
            (section) => section.headline.rawTitle == title,
            orElse: () => null,
          );

  void cycleVisibility() {
    final currentStates = nodeMap.values.map((e) => e.visibility.value).toSet();
    final newState = currentStates.length == 1
        ? _cycleGlobal(currentStates.single)
        : OrgVisibilityState.folded;
    debugPrint('Cycling global visibility; from=$currentStates, to=$newState');
    for (final node in nodeMap.values) {
      node.visibility.value = newState;
    }
  }

  void cycleVisibilityOf(OrgTree tree) {
    final visibilityListenable = nodeFor(tree).visibility;
    final newVisibility =
        _cycleSubtree(visibilityListenable.value, tree.children.isEmpty);
    final subtreeVisibility = _subtreeState(newVisibility);
    debugPrint(
        'Cycling subtree visibility; from=${visibilityListenable.value}, '
        'to=$newVisibility; subtree=$subtreeVisibility');
    _walk(
      tree,
      (subtree) => nodeFor(subtree).visibility.value = subtreeVisibility,
    );
    // Do this last because otherwise _walk applies subtreeVisibility to this
    // root
    visibilityListenable.value = newVisibility;
  }

  void search(Pattern query) {
    if (!patternEquals(searchQuery.value, query)) {
      searchQuery.value = query;
      debugPrint('Querying: $query');
    }
  }

  void _updateVisibilityForQuery() {
    final query = searchQuery.value;
    if (!emptyPattern(query)) {
      // Traverse tree from leaves to root in order to
      // a) prevent unnecessarily checking the same vertices twice
      // b) ensure correct visibility result
      bool _visit(OrgTree tree) {
        final childrenMatch = tree.children.fold<bool>(false, (acc, child) {
          final match = _visit(child);
          return acc || match;
        });
        final anyMatch =
            childrenMatch || tree.contains(query, includeChildren: false);
        final newValue =
            anyMatch ? OrgVisibilityState.children : OrgVisibilityState.folded;
        final node = nodeFor(tree);
        debugPrint(
            'Changing visibility; from=${node.visibility.value}, to=$newValue');
        node.visibility.value = newValue;
        return anyMatch;
      }

      _visit(root);
    }
  }

  @override
  bool updateShouldNotify(OrgControllerData oldWidget) =>
      root != oldWidget.root;

  OrgVisibilityState _cycleGlobal(OrgVisibilityState state) {
    switch (state) {
      case OrgVisibilityState.folded:
        return OrgVisibilityState.contents;
      case OrgVisibilityState.contents:
        return OrgVisibilityState.subtree;
      case OrgVisibilityState.subtree:
      case OrgVisibilityState.children:
        return OrgVisibilityState.folded;
    }
    throw Exception('Unknown state: $state');
  }

  OrgVisibilityState _cycleSubtree(OrgVisibilityState state, bool empty) {
    switch (state) {
      case OrgVisibilityState.folded:
        return OrgVisibilityState.children;
      case OrgVisibilityState.contents:
        return empty ? OrgVisibilityState.subtree : OrgVisibilityState.folded;
      case OrgVisibilityState.children:
        return empty ? OrgVisibilityState.folded : OrgVisibilityState.subtree;
      case OrgVisibilityState.subtree:
        return OrgVisibilityState.folded;
    }
    throw Exception('Unknown state: $state');
  }

  OrgVisibilityState _subtreeState(OrgVisibilityState state) {
    switch (state) {
      case OrgVisibilityState.folded: // fallthrough
      case OrgVisibilityState.contents: // fallthrough
      case OrgVisibilityState.children:
        return OrgVisibilityState.folded;
      case OrgVisibilityState.subtree:
        return OrgVisibilityState.subtree;
    }
    throw Exception('Unknown state: $state');
  }
}
