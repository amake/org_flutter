import 'package:flutter/material.dart';
import 'package:org_flutter/src/controller.dart';
import 'package:org_flutter/src/locatable.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_parser/org_parser.dart';

export 'package:org_flutter/src/locatable.dart';

/// A class facilitating locating elements within the document. It is optional;
/// when not supplied, touching e.g. a footnote reference to jump to the
/// footnote will do nothing.
class OrgLocator extends StatefulWidget {
  static OrgLocatorData? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OrgLocatorData>();

  const OrgLocator({required this.child, super.key});

  final Widget child;

  @override
  State<OrgLocator> createState() => _OrgLocatorState();
}

class _OrgLocatorState extends State<OrgLocator> {
  final ValueNotifier<Map<String, FootnoteKey>> _footnoteKeys =
      SafeValueNotifier({});

  final ValueNotifier<Map<String, RadioTargetKey>> _radioTargetKeys =
      SafeValueNotifier({});

  final ValueNotifier<Map<String, LinkTargetKey>> _linkTargetKeys =
      SafeValueNotifier({});

  final ValueNotifier<Map<String, NameKey>> _nameKeys = SafeValueNotifier({});

  OrgControllerData get _controller => OrgController.of(context);

  @override
  void dispose() {
    _footnoteKeys.dispose();
    _radioTargetKeys.dispose();
    _linkTargetKeys.dispose();
    _nameKeys.dispose();
    super.dispose();
  }

  Future<bool> _jumpToFootnote(OrgFootnoteReference reference) async {
    final result = _controller.root.find<OrgFootnoteReference>((ref) =>
        ref.name == reference.name &&
        ref.isDefinition != reference.isDefinition);
    if (result == null) return false;

    final key = _footnoteKeys.value[result.node.id];
    if (await _makeVisible(key)) {
      key!.currentState?.doHighlight();
      return true;
    }

    // Target widget is probably not currently visible, so make it visible and
    // then listen for its key to become available.
    _controller.ensureVisible(result.path);
    _footnoteKeys.listenOnce(() async {
      final key = _footnoteKeys.value[result.node.id];
      if (await _makeVisible(key)) {
        key!.currentState?.doHighlight();
      }
    });

    return true;
  }

  Future<bool> _jumpToRadioTarget(OrgRadioLink radioLink) async {
    final id = radioLink.content.toLowerCase();
    final result = _controller.root
        .find<OrgRadioTarget>((target) => target.body.toLowerCase() == id);
    if (result == null) return false;

    final key = _radioTargetKeys.value[id];
    if (await _makeVisible(key)) {
      key!.currentState?.doHighlight();
      return true;
    }

    // Target widget is probably not currently visible, so make it visible and
    // then listen for its key to become available.
    _controller.ensureVisible(result.path);
    _radioTargetKeys.listenOnce(() async {
      final key = _radioTargetKeys.value[id];
      if (await _makeVisible(key)) {
        key!.currentState?.doHighlight();
      }
    });

    return true;
  }

  Future<bool> _jumpToLinkTarget(String body) async {
    final keyId = body.toLowerCase();
    final result = _controller.root
        .find<OrgLinkTarget>((target) => target.body.toLowerCase() == keyId);
    if (result == null) return false;

    final key = _linkTargetKeys.value[keyId];
    if (await _makeVisible(key)) {
      key!.currentState?.doHighlight();
      return true;
    }

    // Target widget is probably not currently visible, so make it visible and
    // then listen for its key to become available.
    _controller.ensureVisible(result.path);
    _linkTargetKeys.listenOnce(() async {
      final key = _linkTargetKeys.value[keyId];
      if (await _makeVisible(key)) {
        key!.currentState?.doHighlight();
      }
    });

    return true;
  }

  Future<bool> _jumpToName(String name) async {
    final keyId = name.toLowerCase();
    final result = _controller.root.find<OrgMeta>((target) =>
        target.keyword.toUpperCase() == '#+NAME:' &&
        target.trailing.trim().toLowerCase() == keyId);
    if (result == null) return false;

    final key = _nameKeys.value[keyId];
    if (await _makeVisible(key)) {
      key!.currentState?.doHighlight();
      return true;
    }

    // Target widget is probably not currently visible, so make it visible and
    // then listen for its key to become available.
    _controller.ensureVisible(result.path);
    _nameKeys.listenOnce(() async {
      final key = _nameKeys.value[keyId];
      if (await _makeVisible(key)) {
        key!.currentState?.doHighlight();
      }
    });

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return OrgLocatorData(
      footnoteKeys: _footnoteKeys,
      jumpToFootnote: _jumpToFootnote,
      radioTargetKeys: _radioTargetKeys,
      jumpToRadioTarget: _jumpToRadioTarget,
      linkTargetKeys: _linkTargetKeys,
      jumpToLinkTarget: _jumpToLinkTarget,
      nameKeys: _nameKeys,
      jumpToName: _jumpToName,
      child: widget.child,
    );
  }
}

class OrgLocatorData extends InheritedWidget {
  const OrgLocatorData({
    required super.child,
    required this.footnoteKeys,
    required this.jumpToFootnote,
    required this.radioTargetKeys,
    required this.jumpToRadioTarget,
    required this.linkTargetKeys,
    required this.jumpToLinkTarget,
    required this.nameKeys,
    required this.jumpToName,
    super.key,
  });

  /// Keys representing footnote references in the document. It will only be
  /// populated after the widget build phase.
  final ValueNotifier<Map<String, FootnoteKey>> footnoteKeys;

  FootnoteKey generateFootnoteKey(String id, {String? label}) {
    final key = FootnoteKey(debugLabel: label);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      footnoteKeys.value = Map.of(footnoteKeys.value)
        ..removeWhere((_, v) => v.currentContext?.mounted != true)
        ..[id] = key;
    });
    return key;
  }

  /// Jump to the specified footnote. If successful, will return true.
  final Future<bool> Function(OrgFootnoteReference) jumpToFootnote;

  /// Keys representing radio targets in the document. It will only be
  /// populated after the widget build phase.
  final ValueNotifier<Map<String, RadioTargetKey>> radioTargetKeys;

  RadioTargetKey generateRadioTargetKey(String id, {String? label}) {
    final key = RadioTargetKey(debugLabel: label);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      radioTargetKeys.value = Map.of(radioTargetKeys.value)
        ..removeWhere((_, v) => v.currentContext?.mounted != true)
        ..[id] = key;
    });
    return key;
  }

  /// Jump to the specified radio target. If successful, will return true.
  final Future<bool> Function(OrgRadioLink) jumpToRadioTarget;

  /// Keys representing link targets in the document. It will only be
  /// populated after the widget build phase.
  final ValueNotifier<Map<String, LinkTargetKey>> linkTargetKeys;

  LinkTargetKey generateLinkTargetKey(String id, {String? label}) {
    final key = LinkTargetKey(debugLabel: label);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      linkTargetKeys.value = Map.of(linkTargetKeys.value)
        ..removeWhere((_, v) => v.currentContext?.mounted != true)
        ..[id] = key;
    });
    return key;
  }

  /// Jump to the dedicated target with the specified name. If successful, will
  /// return true.
  final Future<bool> Function(String) jumpToLinkTarget;

  /// Keys representing named objectes in the document. It will only be
  /// populated after the widget build phase.
  final ValueNotifier<Map<String, NameKey>> nameKeys;

  NameKey generateNameKey(String id, {String? label}) {
    final key = NameKey(debugLabel: label);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      nameKeys.value = Map.of(nameKeys.value)
        ..removeWhere((_, v) => v.currentContext?.mounted != true)
        ..[id] = key;
    });
    return key;
  }

  /// Jump to the element with the specified name. If successful, will return
  /// true.
  final Future<bool> Function(String) jumpToName;

  @override
  bool updateShouldNotify(OrgLocatorData oldWidget) => false;
}

Future<bool> _makeVisible(GlobalKey? key) async {
  final context = key?.currentContext;
  if (context == null || !context.mounted) return false;

  // Delay by enough to make sure any opening animations have finished
  await Future.delayed(const Duration(milliseconds: 100), () async {
    if (!context.mounted) return;
    await Scrollable.ensureVisible(
      context,
      alignment: 0.5,
      duration: const Duration(milliseconds: 100),
    );
  });

  return true;
}
