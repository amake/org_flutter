import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:org_flutter/src/entity.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_parser/org_parser.dart';

const _kDefaultSearchQuery = '';
const _kDefaultHideMarkup = false;
const _kDefaultVisibilityState = OrgVisibilityState.folded;

const _kTransientStateNodeMapKey = 'node_map';

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

String? _orgVisibilityStateToJson(OrgVisibilityState? value) =>
    value?.toString();

OrgVisibilityState? _orgVisibilityStateFromJson(String? json) => json == null
    ? null
    : OrgVisibilityState.values.singleWhere(
        (value) => value.toString() == json,
      );

class OrgNodeMap {
  factory OrgNodeMap.build({
    required OrgTree root,
    Map<String, dynamic>? json,
  }) {
    OrgVisibilityState _computeVisibility(OrgTree subtree) {
      var result = _kDefaultVisibilityState;
      if (json != null && subtree is OrgSection) {
        final title = subtree.headline.rawTitle;
        final fromJson = _orgVisibilityStateFromJson(json[title] as String?);
        result = fromJson ?? result;
      }
      return result;
    }

    final data = <OrgTree, OrgNode>{};
    _walk(
      root,
      (subtree) => data[subtree] =
          OrgNode(initialVisibility: _computeVisibility(subtree)),
    );
    return OrgNodeMap._(data);
  }

  factory OrgNodeMap.inherit(OrgNodeMap other) {
    final data = other._data.map((tree, node) =>
        MapEntry(tree, OrgNode(initialVisibility: node.visibility.value)));
    return OrgNodeMap._(data);
  }

  OrgNodeMap._(this._data);

  final Map<OrgTree, OrgNode> _data;

  OrgNode? nodeFor(OrgTree tree) => _data[tree];

  Set<OrgVisibilityState> get currentVisibility =>
      _data.values.map((e) => e.visibility.value).toSet();

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    for (final section in _data.keys.whereType<OrgSection>()) {
      final title = section.headline.rawTitle;
      if (title != null) {
        json[title] =
            _orgVisibilityStateToJson(_data[section]?.visibility.value);
      }
    }
    return json;
  }

  void dispose() {
    for (final node in _data.values) {
      node.dispose();
    }
  }

  void setAllVisibilities(OrgVisibilityState newState) {
    for (final node in _data.values) {
      node.visibility.value = newState;
    }
  }

  OrgSection? sectionWithTitle(String title) =>
      _data.keys.whereType<OrgSection?>().firstWhere(
            (section) => section!.headline.rawTitle == title,
            orElse: () => null,
          );
}

class OrgNode {
  OrgNode({required OrgVisibilityState initialVisibility})
      : visibility = ValueNotifier(initialVisibility);
  final ValueNotifier<OrgVisibilityState> visibility;

  void dispose() => visibility.dispose();
}

void _walk(OrgTree tree, Function(OrgTree) visit) {
  visit(tree);
  for (final child in tree.children) {
    _walk(child, visit);
  }
}

typedef OrgStateListener = Function(Map<String, dynamic>);

class OrgController extends StatefulWidget {
  OrgController.defaults(
    OrgControllerData data, {
    required OrgTree root,
    required Widget child,
    Key? key,
  }) : this._(
          child: child,
          root: root,
          inheritedNodeMap: data._nodeMap,
          searchQuery: data.searchQuery,
          hideMarkup: data.hideMarkup,
          key: key,
        );

  const OrgController({
    required Widget child,
    required OrgTree root,
    bool? hideMarkup,
    String? restorationId,
    Key? key,
  }) : this._(
          child: child,
          root: root,
          hideMarkup: hideMarkup,
          restorationId: restorationId,
          key: key,
        );

  const OrgController._({
    required this.child,
    required this.root,
    this.inheritedNodeMap,
    this.searchQuery,
    this.hideMarkup,
    this.entityReplacements = orgDefaultEntityReplacements,
    this.restorationId,
    Key? key,
  }) : super(key: key);

  final OrgTree root;
  final Widget child;
  final OrgNodeMap? inheritedNodeMap;
  final Pattern? searchQuery;
  final bool? hideMarkup;
  final Map<String, String> entityReplacements;
  final String? restorationId;

  static OrgControllerData of(BuildContext context) {
    final data =
        context.dependOnInheritedWidgetOfExactType<OrgControllerData>();
    if (data == null) {
      throw Exception('OrgControllerData was null');
    }
    return data;
  }

  @override
  _OrgControllerState createState() => _OrgControllerState();
}

class _OrgControllerState extends State<OrgController> with RestorationMixin {
  OrgTree get _root => widget.root;
  bool get _inheritNodeMap => widget.inheritedNodeMap != null;

  late OrgNodeMap _nodeMap;
  late Pattern _searchQuery;
  late bool _hideMarkup;
  Map<String, String> get _entityReplacements => widget.entityReplacements;

  @override
  void initState() {
    super.initState();
    if (_inheritNodeMap) {
      _nodeMap = OrgNodeMap.inherit(widget.inheritedNodeMap!);
    }
    _searchQuery = widget.searchQuery ?? _kDefaultSearchQuery;
    _hideMarkup = widget.hideMarkup ?? _kDefaultHideMarkup;
  }

  @override
  String? get restorationId =>
      _deriveRestorationId(widget.restorationId, 'org_controller');

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    if (!_inheritNodeMap) {
      final initialState = bucket?.read<String>(_kTransientStateNodeMapKey);
      final nodeMapJson = initialState == null
          ? null
          : json.decode(initialState) as Map<String, dynamic>;
      _nodeMap = OrgNodeMap.build(root: _root, json: nodeMapJson);
    }
  }

  @override
  void dispose() {
    _nodeMap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrgControllerData(
      root: widget.root,
      nodeMap: _nodeMap,
      searchQuery: _searchQuery,
      search: search,
      hideMarkup: _hideMarkup,
      entityReplacements: _entityReplacements,
      setHideMarkup: _setHideMarkup,
      cycleVisibility: _cycleVisibility,
      cycleVisibilityOf: _cycleVisibilityOf,
      child: widget.child,
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
        final node = _nodeMap.nodeFor(tree)!;
        debugPrint(
            'Changing visibility; from=${node.visibility.value}, to=$newValue');
        node.visibility.value = newValue;
        return anyMatch;
      }

      _visit(_root);
    }
  }

  void _cycleVisibility() {
    final currentStates = _nodeMap.currentVisibility;
    final newState = currentStates.length == 1
        ? _cycleGlobal(currentStates.single)
        : OrgVisibilityState.folded;
    debugPrint('Cycling global visibility; from=$currentStates, to=$newState');
    _nodeMap.setAllVisibilities(newState);
    _notifyState();
  }

  void _cycleVisibilityOf(OrgTree tree) {
    final visibilityListenable = _nodeMap.nodeFor(tree)!.visibility;
    final newVisibility =
        _cycleSubtree(visibilityListenable.value, tree.children.isEmpty);
    final subtreeVisibility = _subtreeState(newVisibility);
    debugPrint(
        'Cycling subtree visibility; from=${visibilityListenable.value}, '
        'to=$newVisibility; subtree=$subtreeVisibility');
    _walk(
      tree,
      (subtree) =>
          _nodeMap.nodeFor(subtree)!.visibility.value = subtreeVisibility,
    );
    // Do this last because otherwise _walk applies subtreeVisibility to this
    // root
    visibilityListenable.value = newVisibility;
    _notifyState();
  }

  void _notifyState() {
    final nodeMapString = json.encode(_nodeMap.toJson());
    bucket?.write<String>(_kTransientStateNodeMapKey, nodeMapString);
  }

  void _setHideMarkup(bool value) => setState(() => _hideMarkup = value);
}

class OrgControllerData extends InheritedWidget {
  const OrgControllerData({
    required Widget child,
    required this.root,
    required OrgNodeMap nodeMap,
    required this.searchQuery,
    required this.search,
    required bool hideMarkup,
    required Map<String, String> entityReplacements,
    required Function(bool) setHideMarkup,
    required this.cycleVisibility,
    required this.cycleVisibilityOf,
    Key? key,
  })  : _nodeMap = nodeMap,
        _hideMarkup = hideMarkup,
        _entityReplacements = entityReplacements,
        _setHideMarkup = setHideMarkup,
        super(key: key, child: child);

  final OrgTree root;
  final OrgNodeMap _nodeMap;
  final Function(Pattern) search;
  final Pattern searchQuery;
  final bool _hideMarkup;
  final Map<String, String> _entityReplacements;
  final Function(bool) _setHideMarkup;
  final void Function() cycleVisibility;
  final void Function(OrgTree) cycleVisibilityOf;

  bool get hideMarkup => _hideMarkup;

  set hideMarkup(bool value) => _setHideMarkup(value);

  OrgNode? nodeFor(OrgTree tree) => _nodeMap.nodeFor(tree);

  OrgSection? sectionWithTitle(String title) =>
      _nodeMap.sectionWithTitle(title);

  String? prettifyEntity(String name) => _entityReplacements[name];

  @override
  bool updateShouldNotify(OrgControllerData oldWidget) =>
      root != oldWidget.root ||
      search != oldWidget.search ||
      searchQuery != oldWidget.searchQuery ||
      hideMarkup != oldWidget.hideMarkup ||
      !mapEquals(_entityReplacements, oldWidget._entityReplacements);
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
}

String? _deriveRestorationId(String? base, String name) =>
    base == null ? null : '$base/$name';
