import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:org_flutter/src/error.dart';
import 'package:org_flutter/src/folding.dart';
import 'package:org_flutter/src/search.dart';
import 'package:org_flutter/src/settings.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_parser/org_parser.dart';

const _kDefaultSearchQuery = '';

const _kTransientStateNodeMapKey = 'node_map';

// We shouldn't have to specify <State> but not doing so sometimes results in a
// crash here:
// https://github.com/dart-lang/sdk/blob/d252bb11a342f011485b9c9fe7c56a246e92b12b/pkg/front_end/lib/src/fasta/kernel/body_builder.dart#L6614
typedef FootnoteKey = GlobalKey<State>;

/// A collection of temporary data about an Org Mode document used for display
/// purposes.
class OrgDataNodeMap {
  factory OrgDataNodeMap.build({
    required OrgTree root,
    required OrgVisibilityState defaultState,
    Map<String, dynamic>? json,
  }) {
    OrgVisibilityState computeVisibility(OrgTree subtree) {
      var result = defaultState;
      if (json != null && subtree is OrgSection) {
        final title = subtree.headline.rawTitle;
        final fromJson =
            OrgVisibilityStateJson.fromJson(json[title] as String?);
        result = fromJson ?? result;
      }
      return result;
    }

    final data = <String, OrgDataNode>{};
    root.visitSections((subtree) {
      data[subtree.id] =
          OrgDataNode(initialVisibility: computeVisibility(subtree));
      return true;
    });
    return OrgDataNodeMap._(data);
  }

  factory OrgDataNodeMap.inherit(OrgDataNodeMap other) {
    final data = other._data.map((id, node) =>
        MapEntry(id, OrgDataNode(initialVisibility: node.visibility.value)));
    return OrgDataNodeMap._(data);
  }

  OrgDataNodeMap._(this._data);

  final Map<String, OrgDataNode> _data;

  OrgDataNode nodeFor(OrgTree tree) => _data.putIfAbsent(
        tree.id,
        // Trees added to the document after init will need ad hoc data nodes.
        // Ex: an OrgPgpBlock replaced with an OrgDecryptedContent tree
        // containing an OrgSection
        () => OrgDataNode(initialVisibility: OrgVisibilityState.folded),
      );

  Set<OrgVisibilityState> get currentVisibility =>
      _data.values.map((e) => e.visibility.value).toSet();

  Map<String, dynamic> toJson(OrgTree root) {
    final json = <String, dynamic>{};
    root.visitSections((subtree) {
      final node = _data[subtree.id];
      if (node != null) {
        final title = subtree.headline.rawTitle;
        if (title != null) {
          json[title] = node.visibility.value.toJson();
        }
      }
      return true;
    });
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
}

class OrgDataNode {
  OrgDataNode({required OrgVisibilityState initialVisibility})
      : visibility = ValueNotifier(initialVisibility);
  final ValueNotifier<OrgVisibilityState> visibility;

  void dispose() => visibility.dispose();
}

typedef OrgStateListener = void Function(Map<String, dynamic>);

/// Control behavior of an Org Mode document widget. Not needed if you are using
/// the Org widget.
///
/// Place this in your widget hierarchy and fetch with [OrgController.of].
class OrgController extends StatefulWidget {
  /// Initialize the controller with existing data. Mostly useful for displaying
  /// a subsection of a parent document in a "narrowed" view; in such cases you
  /// should supply the [data] and [root] from the parent OrgController.
  OrgController.defaults(
    OrgControllerData data, {
    OrgSettings? settings,
    Pattern? searchQuery,
    required OrgTree root,
    required Widget child,
    Key? key,
  }) : this._(
          child: child,
          root: root,
          inheritedNodeMap: data._nodeMap,
          searchQuery: searchQuery ?? data.searchQuery,
          settings: settings ?? data._callerSettings,
          embeddedSettings: data._embeddedSettings,
          key: key,
        );

  const OrgController({
    required Widget child,
    required OrgTree root,
    Pattern? searchQuery,
    bool? interpretEmbeddedSettings,
    OrgSettings? settings,
    OrgErrorHandler? errorHandler,
    String? restorationId,
    Key? key,
  }) : this._(
          child: child,
          root: root,
          searchQuery: searchQuery,
          interpretEmbeddedSettings: interpretEmbeddedSettings,
          settings: settings,
          errorHandler: errorHandler,
          restorationId: restorationId,
          key: key,
        );

  const OrgController._({
    required this.child,
    required this.root,
    required this.settings,
    this.inheritedNodeMap,
    this.searchQuery,
    this.interpretEmbeddedSettings,
    this.embeddedSettings,
    this.errorHandler,
    this.restorationId,
    super.key,
  });

  /// The Org Mode document or section this controller will control
  final OrgTree root;

  /// The child widget
  final Widget child;

  /// Temporary data about the nodes in [root]
  final OrgDataNodeMap? inheritedNodeMap;

  /// A query for full-text search of the document
  final Pattern? searchQuery;

  /// Read settings included in the document itself
  final bool? interpretEmbeddedSettings;

  /// Settings controlling how the document is displayed
  final OrgSettings? settings;

  final OrgSettings? embeddedSettings;

  /// A callback for handling errors. Values are expected to be of type
  /// [OrgError].
  final OrgErrorHandler? errorHandler;

  /// An ID for temporary state restoration. Supply a unique ID to ensure that
  /// temporary state such as scroll position is preserved as appropriate.
  final String? restorationId;

  static OrgControllerData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OrgControllerData>()!;

  @override
  State<OrgController> createState() => _OrgControllerState();
}

class _OrgControllerState extends State<OrgController> with RestorationMixin {
  OrgTree get _root => widget.root;
  bool get _inheritNodeMap => widget.inheritedNodeMap != null;
  List<OrgSettings> get _settings => [
        if (widget.settings != null) widget.settings!,
        if (_embeddedSettings != null) _embeddedSettings!
      ];

  late OrgDataNodeMap _nodeMap;
  Pattern? _searchQuery;
  OrgSettings? _embeddedSettings;

  @override
  void initState() {
    super.initState();
    if (_inheritNodeMap) {
      _nodeMap = OrgDataNodeMap.inherit(widget.inheritedNodeMap!);
    }
    final root = _root;
    _embeddedSettings = widget.embeddedSettings;
    if (widget.interpretEmbeddedSettings == true && root is OrgDocument) {
      _embeddedSettings ??= OrgSettings.fromDocument(root, _errorHandler);
    }
    _searchQuery = widget.searchQuery;
  }

  @override
  void didUpdateWidget(covariant OrgController oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.searchQuery.sameAs(oldWidget.searchQuery)) {
      _search(widget.searchQuery ?? _kDefaultSearchQuery);
    }
  }

  OrgErrorHandler get _errorHandler =>
      widget.errorHandler ?? _defaultErrorHandler;

  void _defaultErrorHandler(dynamic e) {
    debugPrint(e.toString());
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
      _nodeMap = OrgDataNodeMap.build(
        root: _root,
        defaultState: _settings.startupFolded,
        json: nodeMapJson,
      );
      if (initialState == null) {
        _updateVisibilityForQuery(_searchQuery);
      }
    }
  }

  final ValueNotifier<List<SearchResultKey>> _searchResultKeys =
      ValueNotifier([]);

  final ValueNotifier<Map<String, FootnoteKey>> _footnoteKeys =
      ValueNotifier({});

  @override
  void dispose() {
    _nodeMap.dispose();
    _searchResultKeys.dispose();
    _footnoteKeys.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrgControllerData(
      root: widget.root,
      nodeMap: _nodeMap,
      searchQuery: _searchQuery,
      searchResultKeys: _searchResultKeys,
      footnoteKeys: _footnoteKeys,
      embeddedSettings: _embeddedSettings,
      callerSettings: widget.settings,
      cycleVisibility: _cycleVisibility,
      cycleVisibilityOf: _cycleVisibilityOf,
      restorationId: widget.restorationId,
      ensureVisible: _ensureVisible,
      child: widget.child,
    );
  }

  /// Set the search query. Section visibility will be updated so that sections
  /// with hits are expanded and sections without will be collapsed.
  void _search(Pattern query) {
    if (!_searchQuery.sameAs(query)) {
      setState(() {
        _searchQuery = query;
        _updateVisibilityForQuery(query);
        _searchResultKeys.value = [];
      });
      debugPrint('Querying: $query');
    }
  }

  void _updateVisibilityForQuery(Pattern? query) {
    if (!query.isEmpty) {
      // Traverse tree from leaves to root in order to
      // a) prevent unnecessarily checking the same vertices twice
      // b) ensure correct visibility result
      bool visit(OrgTree tree) {
        final childrenMatch = tree.sections.fold<bool>(false, (acc, section) {
          final match = visit(section);
          return acc || match;
        });
        final anyMatch =
            childrenMatch || tree.contains(query!, includeChildren: false);
        final newValue =
            anyMatch ? OrgVisibilityState.children : OrgVisibilityState.folded;
        final node = _nodeMap.nodeFor(tree);
        debugPrint(
            'Changing visibility; from=${node.visibility.value}, to=$newValue');
        node.visibility.value = newValue;
        return anyMatch;
      }

      visit(_root);
    }
  }

  void _cycleVisibility() {
    final currentStates = _nodeMap.currentVisibility;
    final newState = currentStates.length == 1
        ? currentStates.single.cycleGlobal
        : OrgVisibilityState.folded;
    debugPrint('Cycling global visibility; from=$currentStates, to=$newState');
    _nodeMap.setAllVisibilities(newState);
    _notifyState();
  }

  void _cycleVisibilityOf(OrgTree tree) {
    final visibilityListenable = _nodeMap.nodeFor(tree).visibility;
    final newVisibility =
        visibilityListenable.value.cycleSubtree(tree.sections.isEmpty);
    final subtreeVisibility = newVisibility.subtreeState;
    debugPrint(
        'Cycling subtree visibility; from=${visibilityListenable.value}, '
        'to=$newVisibility; subtree=$subtreeVisibility');
    tree.visitSections((subtree) {
      _nodeMap.nodeFor(subtree).visibility.value = subtreeVisibility;
      return true;
    });
    // Do this last because otherwise visitSections applies subtreeVisibility to
    // this root
    visibilityListenable.value = newVisibility;
    _notifyState();
  }

  void _ensureVisible(OrgPath path) {
    for (final section in path.whereType<OrgTree>()) {
      final visibilityListenable = _nodeMap.nodeFor(section);
      visibilityListenable.visibility.value = OrgVisibilityState.children;
    }
  }

  void _notifyState() {
    final nodeMapString = json.encode(_nodeMap.toJson(_root));
    bucket?.write<String>(_kTransientStateNodeMapKey, nodeMapString);
  }
}

class OrgControllerData extends InheritedWidget {
  OrgControllerData({
    required super.child,
    required this.root,
    required OrgDataNodeMap nodeMap,
    required this.searchQuery,
    required this.searchResultKeys,
    required this.footnoteKeys,
    required this.cycleVisibility,
    required this.cycleVisibilityOf,
    required this.ensureVisible,
    required OrgSettings? callerSettings,
    required OrgSettings? embeddedSettings,
    String? restorationId,
    super.key,
  })  : _nodeMap = nodeMap,
        _restorationId = restorationId,
        _callerSettings = callerSettings,
        _embeddedSettings = embeddedSettings,
        settings = [
          if (callerSettings != null) callerSettings,
          if (embeddedSettings != null) embeddedSettings
        ];

  /// The Org Mode document or section this controller will control
  final OrgTree root;

  final OrgDataNodeMap _nodeMap;

  /// A query for full-text search of the document
  final Pattern? searchQuery;

  final OrgSettings? _callerSettings;
  final OrgSettings? _embeddedSettings;

  final List<OrgSettings> settings;

  /// Keys representing individual search result spans in the document. It will
  /// only be populated after the widget build phase, so consumers will likely
  /// want to use e.g. a [ValueListenableBuilder] to consume it.
  ///
  /// Note that keys will not necessarily be in "document" order. Consumers
  /// should sort by any relevant metric as necessary.
  final ValueNotifier<List<SearchResultKey>> searchResultKeys;

  /// Keys representing footnote references in the document. It will only be
  /// populated after the widget build phase.
  final ValueNotifier<Map<String, FootnoteKey>> footnoteKeys;

  /// Cycle the visibility of the entire document
  // TODO(aaron): Should this be a declarative API?
  final void Function() cycleVisibility;

  /// Cycle the visibility of the specified subtree
  final void Function(OrgTree) cycleVisibilityOf;

  /// Adjust visibility of sections so that the specified path is visible
  final void Function(OrgPath) ensureVisible;

  final String? _restorationId;

  /// Find the temporary data node for the given subtree
  OrgDataNode nodeFor(OrgTree tree) => _nodeMap.nodeFor(tree);

  /// Find the section with the specified title
  OrgSection? _sectionSearch(bool Function(OrgSection) predicate) {
    OrgSection? result;
    root.visitSections((section) {
      if (predicate(section)) {
        result = section;
        return false;
      }
      return true;
    });
    return result;
  }

  /// Find the section with the specified title
  OrgSection? sectionWithTitle(String title) =>
      _sectionSearch((section) => section.headline.rawTitle == title);

  /// Find the section with the specified ID
  OrgSection? sectionWithId(String id) =>
      _sectionSearch((section) => section.ids.contains(id));

  /// Find the section with the specified custom ID
  OrgSection? sectionWithCustomId(String customId) =>
      _sectionSearch((section) => section.customIds.contains(customId));

  /// Find the section corresponding to [target], which may be one of
  ///
  /// - A section title link fragment like `*Foo bar`
  /// - A CUSTOM_ID link fragment like `#foo-bar`
  /// - An ID link like `id:abcd1234`
  ///
  /// The specified section may not exist in this tree, in which case the result
  /// will be null.
  ///
  /// If [target] is none of the above three types, an [Exception] will be
  /// thrown.
  OrgSection? sectionForTarget(String target) {
    if (isOrgLocalSectionUrl(target)) {
      return sectionWithTitle(parseOrgLocalSectionUrl(target));
    } else if (isOrgIdUrl(target)) {
      return sectionWithId(parseOrgIdUrl(target));
    } else if (isOrgCustomIdUrl(target)) {
      return sectionWithCustomId(parseOrgCustomIdUrl(target));
    } else {
      throw Exception(
          'Unknown target type: $target (was not a title or an ID)');
    }
  }

  /// Get the prettify-symbols-mode replacement with the given [name]. The
  /// result is obtained from [OrgController.entityReplacements]. Returns null
  /// if prettification is disabled.
  String? prettifyEntity(String name) =>
      settings.prettyEntities ? settings.entityReplacements[name] : null;

  String? restorationIdFor(String name) =>
      _deriveRestorationId(_restorationId, name);

  SearchResultKey generateSearchResultKey({String? label}) {
    final key = SearchResultKey(debugLabel: '$searchQuery($label)');
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      searchResultKeys.value = [
        // Filter out unmounted keys to prevent rebuilds from adding to the list
        // forever
        ...searchResultKeys.value
            .where((key) => key.currentContext?.mounted == true),
        key,
      ];
    });
    return key;
  }

  FootnoteKey generateFootnoteKey(String id, {String? label}) {
    final key = FootnoteKey(debugLabel: label);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      footnoteKeys.value = Map.of(footnoteKeys.value)
        ..removeWhere((_, v) => v.currentContext?.mounted != true)
        ..[id] = key;
    });
    return key;
  }

  @override
  bool updateShouldNotify(OrgControllerData oldWidget) =>
      root != oldWidget.root ||
      searchQuery != oldWidget.searchQuery ||
      // Don't check searchResultKeys because rebuilding this widget will cause
      // new keys to be made which leads to an infinite loop
      !listEquals(settings, oldWidget.settings);
}

String? _deriveRestorationId(String? base, String name) =>
    base == null ? null : '$base/$name';
