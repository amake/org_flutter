import 'package:flutter/foundation.dart';
import 'package:org_flutter/src/entity.dart';
import 'package:org_flutter/src/error.dart';
import 'package:org_flutter/src/folding.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_parser/org_parser.dart';

export 'package:org_flutter/src/folding.dart' show OrgVisibilityState;

const _kDefaultReflowText = false;
const _kDefaultDeemphasizeMarkup = false;
const _kDefaultPrettyEntities = true;
const _kDefaultHideBlockStartup = false;
const _kDefaultHideDrawerStartup = true;
const _kDefaultHideStars = false;
const _kDefaultHideEmphasisMarkers = false;
const _kDefaultVisibilityState = OrgVisibilityState.folded;

/// A collection of settings that affect the appearance of the document
class OrgSettings {
  static OrgSettings get defaults => const OrgSettings(
        reflowText: _kDefaultReflowText,
        deemphasizeMarkup: _kDefaultDeemphasizeMarkup,
        startupFolded: _kDefaultVisibilityState,
        prettyEntities: _kDefaultPrettyEntities,
        hideBlockStartup: _kDefaultHideBlockStartup,
        hideDrawerStartup: _kDefaultHideDrawerStartup,
        hideStars: _kDefaultHideStars,
        hideEmphasisMarkers: _kDefaultHideEmphasisMarkers,
        entityReplacements: orgDefaultEntityReplacements,
      );

  /// Equivalent to the old "hideMarkup" setting
  static OrgSettings get hideMarkup => const OrgSettings(
        reflowText: true,
        deemphasizeMarkup: true,
        hideEmphasisMarkers: true,
      );

  /// Initialize a settings object from values contained within the document,
  /// specifically:
  ///
  /// - `#+STARTUP:` keywords
  /// - Local variable list settings for relevant Org Mode variables
  ///
  /// Errors encountered during processing will be reported to [errorHandler].
  factory OrgSettings.fromDocument(
    OrgDocument doc,
    OrgErrorHandler errorHandler,
  ) {
    Map<String, String>? entityReplacements;
    bool? prettyEntities;
    bool? hideEmphasisMarkers;
    bool? hideBlockStartup;
    bool? hideDrawerStartup;
    bool? hideStars;
    OrgVisibilityState? startupFolded;
    var showEverything = false;
    final startupSettings = getStartupSettings(doc);
    for (final setting in startupSettings) {
      switch (setting) {
        case 'hideblocks':
          hideBlockStartup = true;
          break;
        case 'nohideblocks':
          hideBlockStartup = false;
          break;
        case 'hidedrawers':
          hideDrawerStartup = true;
          break;
        case 'nohidedrawers':
          hideDrawerStartup = false;
          break;
        case 'hidestars':
          hideStars = true;
          break;
        case 'showstars':
          hideStars = false;
          break;
        case 'fold':
        case 'overview':
          startupFolded = OrgVisibilityState.folded;
          break;
        case 'content':
        // TODO(aaron): Support these levels properly
        case 'show2levels':
        case 'show3levels':
        case 'show4levels':
        case 'show5levels':
          startupFolded = OrgVisibilityState.contents;
          showEverything = false;
          break;
        case 'nofold':
        case 'showall':
          startupFolded = OrgVisibilityState.subtree;
          showEverything = false;
          break;
        case 'showeverything':
          startupFolded = OrgVisibilityState.subtree;
          showEverything = true;
          break;
      }
    }
    if (showEverything) {
      hideBlockStartup = false;
      hideDrawerStartup = false;
    }
    try {
      final lvars = extractLocalVariables(doc, errorHandler);
      entityReplacements =
          getOrgEntities(orgDefaultEntityReplacements, lvars, errorHandler);
      prettyEntities = getPrettyEntities(lvars);
      hideEmphasisMarkers = getHideEmphasisMarkers(lvars);
      // org-hide-{block,drawer}-startup, org-startup-folded are not respected
      // when set as local variables.
    } catch (e) {
      errorHandler.call(e);
    }
    return OrgSettings(
      startupFolded: startupFolded,
      hideEmphasisMarkers: hideEmphasisMarkers,
      prettyEntities: prettyEntities,
      hideBlockStartup: hideBlockStartup,
      hideDrawerStartup: hideDrawerStartup,
      hideStars: hideStars,
      entityReplacements: entityReplacements,
    );
  }

  const OrgSettings({
    this.reflowText,
    this.deemphasizeMarkup,
    this.startupFolded,
    this.hideEmphasisMarkers,
    this.prettyEntities,
    this.hideBlockStartup,
    this.hideDrawerStartup,
    this.hideStars,
    this.entityReplacements,
  });

  /// Whether to reflow text to remove intra-paragraph line breaks. Does not map
  /// to any actual Org Mode settings. When not present it defaults to `false`
  /// (disabled).
  final bool? reflowText;

  /// Whether to make various markup less noticeable. Does not map to any actual
  /// Org Mode settings. When not present it defaults to `false` (disabled).
  final bool? deemphasizeMarkup;

  /// The initial folding state for sections. Like `org-startup-folded`.
  final OrgVisibilityState? startupFolded;

  /// Whether to prettify entities. By default the `org-hide-emphasis-markers`
  /// local variable value is respected; when not present it defaults to `false`
  /// (disabled).
  final bool? hideEmphasisMarkers;

  /// Whether to prettify entities. By default the `org-pretty-entities` local
  /// variable value is respected; when not present it defaults to `true`
  /// (enabled).
  final bool? prettyEntities;

  /// Whether blocks should start folded. By default the `[no]hideblocks`
  /// #+STARTUP keyword is respected; when not present it defaults to `false`
  /// (disabled).
  final bool? hideBlockStartup;

  /// Whether drawers should start folded. By default the `[no]hidedrawers`
  /// #+STARTUP keyword is respected; when not present it defaults to `true`
  /// (enabled).
  final bool? hideDrawerStartup;

  /// Whether to hide all but one of headline stars. By default the
  /// `hidestars`/`showstars` #+STARTUP keyword is respected; when not present
  /// it defaults to `false` (disabled).
  final bool? hideStars;

  /// A map of entity replacements, e.g. Agrave → À. See
  /// [orgDefaultEntityReplacements].
  final Map<String, String>? entityReplacements;

  @override
  bool operator ==(Object other) =>
      other is OrgSettings &&
      reflowText == other.reflowText &&
      deemphasizeMarkup == other.deemphasizeMarkup &&
      startupFolded == other.startupFolded &&
      hideEmphasisMarkers == other.hideEmphasisMarkers &&
      prettyEntities == other.prettyEntities &&
      hideBlockStartup == other.hideBlockStartup &&
      hideDrawerStartup == other.hideDrawerStartup &&
      hideStars == other.hideStars &&
      mapEquals(entityReplacements, other.entityReplacements);

  @override
  int get hashCode => Object.hash(
        reflowText,
        deemphasizeMarkup,
        startupFolded,
        hideEmphasisMarkers,
        prettyEntities,
        hideBlockStartup,
        hideDrawerStartup,
        hideStars,
        entityReplacements,
      );

  OrgSettings copyWith({
    bool? reflowText,
    bool? deemphasizeMarkup,
    OrgVisibilityState? startupFolded,
    bool? hideEmphasisMarkers,
    bool? prettyEntities,
    bool? hideBlockStartup,
    bool? hideDrawerStartup,
    bool? hideStars,
    bool? inlineImages,
    Map<String, String>? entityReplacements,
  }) =>
      OrgSettings(
        reflowText: reflowText ?? this.reflowText,
        deemphasizeMarkup: deemphasizeMarkup ?? this.deemphasizeMarkup,
        startupFolded: startupFolded ?? this.startupFolded,
        hideEmphasisMarkers: hideEmphasisMarkers ?? this.hideEmphasisMarkers,
        prettyEntities: prettyEntities ?? this.prettyEntities,
        hideBlockStartup: hideBlockStartup ?? this.hideBlockStartup,
        hideDrawerStartup: hideDrawerStartup ?? this.hideDrawerStartup,
        hideStars: hideStars ?? this.hideStars,
        inlineImages: inlineImages ?? this.inlineImages,
        entityReplacements: entityReplacements ?? this.entityReplacements,
      );
}

extension LayeredOrgSettings on List<OrgSettings> {
  bool get reflowText => firstWhere((layer) => layer.reflowText != null,
      orElse: () => OrgSettings.defaults).reflowText!;

  bool get deemphasizeMarkup =>
      firstWhere((layer) => layer.deemphasizeMarkup != null,
          orElse: () => OrgSettings.defaults).deemphasizeMarkup!;

  OrgVisibilityState get startupFolded =>
      firstWhere((layer) => layer.startupFolded != null,
          orElse: () => OrgSettings.defaults).startupFolded!;

  bool get hideEmphasisMarkers =>
      firstWhere((layer) => layer.hideEmphasisMarkers != null,
          orElse: () => OrgSettings.defaults).hideEmphasisMarkers!;

  bool get prettyEntities => firstWhere((layer) => layer.prettyEntities != null,
      orElse: () => OrgSettings.defaults).prettyEntities!;

  bool get hideBlockStartup =>
      firstWhere((layer) => layer.hideBlockStartup != null,
          orElse: () => OrgSettings.defaults).hideBlockStartup!;

  bool get hideDrawerStartup =>
      firstWhere((layer) => layer.hideDrawerStartup != null,
          orElse: () => OrgSettings.defaults).hideDrawerStartup!;

  bool get hideStars => firstWhere((layer) => layer.hideStars != null,
      orElse: () => OrgSettings.defaults).hideStars!;

  Map<String, String> get entityReplacements =>
      firstWhere((layer) => layer.entityReplacements != null,
          orElse: () => OrgSettings.defaults).entityReplacements!;
}
