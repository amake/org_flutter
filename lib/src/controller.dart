import 'package:flutter/widgets.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_parser/org_parser.dart';

const _kDefaultSearchQuery = '';
const _kDefaultHideMarkup = false;

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

Map<OrgTree, OrgNode> _copyNodeMap(Map<OrgTree, OrgNode> nodeMap) =>
    nodeMap.map((tree, node) =>
        MapEntry(tree, OrgNode(initialVisibility: node.visibility.value)));

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
  }) : this._(
          child: child,
          root: root,
          inheritedNodeMap: data._nodeMap,
          searchQuery: data.searchQuery,
          hideMarkup: data.hideMarkup,
          key: key,
        );

  const OrgController({
    @required Widget child,
    @required OrgTree root,
    bool hideMarkup,
  }) : this._(
          child: child,
          root: root,
          hideMarkup: hideMarkup,
        );

  const OrgController._({
    @required this.child,
    @required this.root,
    this.inheritedNodeMap,
    this.searchQuery,
    this.hideMarkup,
    Key key,
  })  : assert(child != null),
        assert(root != null),
        super(key: key);

  final OrgTree root;
  final Widget child;
  final Map<OrgTree, OrgNode> inheritedNodeMap;
  final Pattern searchQuery;
  final bool hideMarkup;

  static OrgControllerData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OrgControllerData>();

  @override
  _OrgControllerState createState() => _OrgControllerState();
}

class _OrgControllerState extends State<OrgController> {
  OrgTree get _root => widget.root;
  Map<OrgTree, OrgNode> _nodeMap;
  Pattern _searchQuery;
  bool _hideMarkup;

  @override
  void initState() {
    super.initState();
    _nodeMap = widget.inheritedNodeMap != null
        ? _copyNodeMap(widget.inheritedNodeMap)
        : _buildNodeMap(widget.root);
    _searchQuery = widget.searchQuery ?? _kDefaultSearchQuery;
    _hideMarkup = widget.hideMarkup ?? _kDefaultHideMarkup;
  }

  @override
  void dispose() {
    for (final node in _nodeMap.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrgControllerData(
      child: widget.child,
      root: widget.root,
      nodeMap: _nodeMap,
      searchQuery: _searchQuery,
      search: search,
      hideMarkup: _hideMarkup,
      setHideMarkup: _setHideMarkup,
      cycleVisibility: _cycleVisibility,
      cycleVisibilityOf: _cycleVisibilityOf,
    );
  }

  void search(Pattern query) {
    if (!patternEquals(_searchQuery, query)) {
      setState(() {
        _searchQuery = query;
        _updateVisibilityForQuery(query);
      });
      debugPrint('Querying: $query');
    }
  }

  void _updateVisibilityForQuery(Pattern query) {
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
        final node = _nodeMap[tree];
        debugPrint(
            'Changing visibility; from=${node.visibility.value}, to=$newValue');
        node.visibility.value = newValue;
        return anyMatch;
      }

      _visit(_root);
    }
  }

  void _cycleVisibility() {
    final currentStates =
        _nodeMap.values.map((e) => e.visibility.value).toSet();
    final newState = currentStates.length == 1
        ? _cycleGlobal(currentStates.single)
        : OrgVisibilityState.folded;
    debugPrint('Cycling global visibility; from=$currentStates, to=$newState');
    for (final node in _nodeMap.values) {
      node.visibility.value = newState;
    }
  }

  void _cycleVisibilityOf(OrgTree tree) {
    final visibilityListenable = _nodeMap[tree].visibility;
    final newVisibility =
        _cycleSubtree(visibilityListenable.value, tree.children.isEmpty);
    final subtreeVisibility = _subtreeState(newVisibility);
    debugPrint(
        'Cycling subtree visibility; from=${visibilityListenable.value}, '
        'to=$newVisibility; subtree=$subtreeVisibility');
    _walk(
      tree,
      (subtree) => _nodeMap[subtree].visibility.value = subtreeVisibility,
    );
    // Do this last because otherwise _walk applies subtreeVisibility to this
    // root
    visibilityListenable.value = newVisibility;
  }

  void _setHideMarkup(bool value) => setState(() => _hideMarkup = value);
}

class OrgControllerData extends InheritedWidget {
  const OrgControllerData({
    @required Widget child,
    @required this.root,
    @required Map<OrgTree, OrgNode> nodeMap,
    @required this.searchQuery,
    @required this.search,
    @required bool hideMarkup,
    @required Function(bool) setHideMarkup,
    @required this.cycleVisibility,
    @required this.cycleVisibilityOf,
    Key key,
  })  : assert(root != null),
        assert(nodeMap != null),
        assert(searchQuery != null),
        assert(search != null),
        assert(hideMarkup != null),
        assert(cycleVisibility != null),
        assert(cycleVisibilityOf != null),
        _nodeMap = nodeMap,
        _hideMarkup = hideMarkup,
        _setHideMarkup = setHideMarkup,
        super(key: key, child: child);

  final OrgTree root;
  final Map<OrgTree, OrgNode> _nodeMap;
  final Function(Pattern) search;
  final Pattern searchQuery;
  final bool _hideMarkup;
  final Function(bool) _setHideMarkup;
  final void Function() cycleVisibility;
  final void Function(OrgTree) cycleVisibilityOf;

  bool get hideMarkup => _hideMarkup;

  set hideMarkup(bool value) => _setHideMarkup(value);

  OrgNode nodeFor(OrgTree tree) => _nodeMap[tree];

  OrgSection sectionWithTitle(String title) =>
      _nodeMap.keys.whereType<OrgSection>().firstWhere(
            (section) => section.headline.rawTitle == title,
            orElse: () => null,
          );

  @override
  bool updateShouldNotify(OrgControllerData oldWidget) =>
      root != oldWidget.root ||
      search != oldWidget.search ||
      searchQuery != oldWidget.searchQuery ||
      hideMarkup != oldWidget.hideMarkup;
}

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
