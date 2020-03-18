import 'package:flutter/widgets.dart';
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

class OrgController extends InheritedWidget {
  OrgController({
    @required Widget child,
    @required this.root,
    Key key,
  })  : _nodeMap = _buildNodeMap(root),
        assert(root != null),
        super(key: key, child: child);

  final OrgTree root;
  final Map<OrgTree, OrgNode> _nodeMap;
  final ValueNotifier<Pattern> searchQuery = ValueNotifier('');

  static OrgController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OrgController>();

  OrgNode nodeFor(OrgTree tree) => _nodeMap[tree];

  OrgSection sectionWithTitle(String title) =>
      _nodeMap.keys.whereType<OrgSection>().firstWhere(
            (section) => section.headline.rawTitle == title,
            orElse: () => null,
          );

  void cycleVisibility() {
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

  void cycleVisibilityOf(OrgTree tree) {
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

  void search(Pattern query) {
    searchQuery.value = query;
    debugPrint('Querying: $query');
    if (!emptyPattern(query)) {
      _nodeMap.forEach((tree, node) {
        final newValue = tree.contains(query)
            ? OrgVisibilityState.children
            : OrgVisibilityState.folded;
        debugPrint(
            'Changing visibility; from=${node.visibility.value}, to=$newValue');
        node.visibility.value = newValue;
      });
    }
  }

  @override
  bool updateShouldNotify(OrgController oldWidget) => root != oldWidget.root;

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
