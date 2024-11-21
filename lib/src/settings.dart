import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:org_flutter/src/entity.dart';
import 'package:org_flutter/src/error.dart';
import 'package:org_flutter/src/folding.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_parser/org_parser.dart';

export 'package:org_flutter/src/folding.dart' show OrgVisibilityState;

const _kDefaultReflowText = false;
const _kDefaultDeemphasizeMarkup = false;
const _kDefaultPrettyEntities = true;
const _kDefaultSubSuperscripts = true;
const _kDefaultStrictSubSuperscripts = false;
const _kDefaultHideBlockStartup = false;
const _kDefaultHideDrawerStartup = true;
const _kDefaultHideStars = false;
const _kDefaultHideEmphasisMarkers = false;
const _kDefaultInlineImages = true;
const _kDefaultVisibilityState = OrgVisibilityState.folded;

/// A collection of settings that affect the appearance of the document
class OrgSettings {
  static OrgSettings get defaults => OrgSettings(
        reflowText: _kDefaultReflowText,
        deemphasizeMarkup: _kDefaultDeemphasizeMarkup,
        startupFolded: _kDefaultVisibilityState,
        prettyEntities: _kDefaultPrettyEntities,
        subSuperscripts: _kDefaultSubSuperscripts,
        strictSubSuperscripts: _kDefaultStrictSubSuperscripts,
        hideBlockStartup: _kDefaultHideBlockStartup,
        hideDrawerStartup: _kDefaultHideDrawerStartup,
        hideStars: _kDefaultHideStars,
        inlineImages: _kDefaultInlineImages,
        hideEmphasisMarkers: _kDefaultHideEmphasisMarkers,
        entityReplacements: orgDefaultEntityReplacements,
        todoSettings: [defaultTodoStates],
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
  /// - `#+TODO:` (and related) keywords
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
    bool? inlineImages;
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
        case 'entitiespretty':
          prettyEntities = true;
          break;
        case 'entitiesplain':
          prettyEntities = false;
          break;
        case 'inlineimages':
          inlineImages = true;
          break;
        case 'noinlineimages':
          inlineImages = false;
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
    TextDirection? textDirection;
    bool? subSuperscripts;
    bool? strictSubSuperscripts;
    try {
      final lvars = extractLocalVariables(doc, errorHandler);
      entityReplacements =
          getOrgEntities(orgDefaultEntityReplacements, lvars, errorHandler);
      prettyEntities ??= getPrettyEntities(lvars);
      hideEmphasisMarkers = getHideEmphasisMarkers(lvars);
      textDirection = getTextDirection(lvars);
      subSuperscripts = getSubSuperscripts(lvars);
      strictSubSuperscripts = getStrictSubSuperscripts(lvars);
      // org-hide-{block,drawer}-startup, org-startup-folded are not respected
      // when set as local variables.
    } catch (e) {
      errorHandler.call(e);
    }

    final extractedTodoStates = extractTodoSettings(doc);
    final todoSettings = extractedTodoStates.isNotEmpty
        ? extractedTodoStates
        : [defaultTodoStates];

    final locale = extractLocale(doc);

    return OrgSettings(
      startupFolded: startupFolded,
      hideEmphasisMarkers: hideEmphasisMarkers,
      prettyEntities: prettyEntities,
      subSuperscripts: subSuperscripts,
      strictSubSuperscripts: strictSubSuperscripts,
      hideBlockStartup: hideBlockStartup,
      hideDrawerStartup: hideDrawerStartup,
      hideStars: hideStars,
      inlineImages: inlineImages,
      entityReplacements: entityReplacements,
      todoSettings: todoSettings,
      locale: locale,
      textDirection: textDirection,
    );
  }

  const OrgSettings({
    this.reflowText,
    this.deemphasizeMarkup,
    this.startupFolded,
    this.hideEmphasisMarkers,
    this.prettyEntities,
    this.subSuperscripts,
    this.strictSubSuperscripts,
    this.hideBlockStartup,
    this.hideDrawerStartup,
    this.hideStars,
    this.inlineImages,
    this.entityReplacements,
    this.todoSettings,
    this.locale,
    this.textDirection,
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

  /// Whether to prettify entities. By default the
  /// `entitiesplain`/`entitiespretty` #+STARTUP keywords and
  /// `org-pretty-entities` local variable value is respected; when not present
  /// it defaults to `true` (enabled).
  final bool? prettyEntities;

  /// Whether to render subscripts and superscripts. By default the
  /// `org-pretty-entities-include-sub-superscripts` local variable value is
  /// respected; when not present it defaults to `true` (enabled). However in
  /// order to take effect [prettyEntities] must also be enabled.
  final bool? subSuperscripts;

  /// Whether to require braces (`{` and `}`) surrounding subscripts and
  /// superscripts. By default the `org-use-sub-superscripts` local variable
  /// value is respected; when not present it defaults to `false`, meaning
  /// braces are not required. Note that [prettyEntities] and [subSuperscripts]
  /// must both be enabled for this to have an effect.
  final bool? strictSubSuperscripts;

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

  /// Whether to show inline images. By default the `[no]inlineimages` #+STARTUP
  /// keyword is respected; when not present it defaults to `true` (enabled).
  ///
  /// Note however that org_flutter does not handle loading images directly;
  /// when this is enabled, the [Org.loadImage] callback will be invoked for the
  /// caller to handle.
  final bool? inlineImages;

  /// A map of entity replacements, e.g. Agrave → À. See
  /// [orgDefaultEntityReplacements].
  final Map<String, String>? entityReplacements;

  /// The TODO states as defined by `#+TODO:` and related keywords. Defaults to
  /// [defaultTodoStates], i.e. `#+TODO: TODO | DONE`.
  final List<OrgTodoStates>? todoSettings;

  /// The locale of the document. Set by `#+LANGUAGE:`.
  final Locale? locale;

  /// The text direction of the document. Set by `bidi-paragraph-direction`.
  final TextDirection? textDirection;

  @override
  bool operator ==(Object other) =>
      other is OrgSettings &&
      reflowText == other.reflowText &&
      deemphasizeMarkup == other.deemphasizeMarkup &&
      startupFolded == other.startupFolded &&
      hideEmphasisMarkers == other.hideEmphasisMarkers &&
      prettyEntities == other.prettyEntities &&
      subSuperscripts == other.subSuperscripts &&
      strictSubSuperscripts == other.strictSubSuperscripts &&
      hideBlockStartup == other.hideBlockStartup &&
      hideDrawerStartup == other.hideDrawerStartup &&
      hideStars == other.hideStars &&
      inlineImages == other.inlineImages &&
      mapEquals(entityReplacements, other.entityReplacements) &&
      listEquals(todoSettings, other.todoSettings) &&
      locale == other.locale &&
      textDirection == other.textDirection;

  @override
  int get hashCode => Object.hash(
        reflowText,
        deemphasizeMarkup,
        startupFolded,
        hideEmphasisMarkers,
        prettyEntities,
        subSuperscripts,
        strictSubSuperscripts,
        hideBlockStartup,
        hideDrawerStartup,
        hideStars,
        inlineImages,
        entityReplacements == null
            ? null
            : Object.hashAll(entityReplacements!.keys),
        entityReplacements == null
            ? null
            : Object.hashAll(entityReplacements!.values),
        todoSettings == null ? null : Object.hashAll(todoSettings!),
        locale,
        textDirection,
      );

  OrgSettings copyWith({
    bool? reflowText,
    bool? deemphasizeMarkup,
    OrgVisibilityState? startupFolded,
    bool? hideEmphasisMarkers,
    bool? prettyEntities,
    bool? subSuperscripts,
    bool? strictSubSuperscripts,
    bool? hideBlockStartup,
    bool? hideDrawerStartup,
    bool? hideStars,
    bool? inlineImages,
    Map<String, String>? entityReplacements,
    List<OrgTodoStates>? todoSettings,
    Locale? locale,
    TextDirection? textDirection,
  }) =>
      OrgSettings(
        reflowText: reflowText ?? this.reflowText,
        deemphasizeMarkup: deemphasizeMarkup ?? this.deemphasizeMarkup,
        startupFolded: startupFolded ?? this.startupFolded,
        hideEmphasisMarkers: hideEmphasisMarkers ?? this.hideEmphasisMarkers,
        prettyEntities: prettyEntities ?? this.prettyEntities,
        subSuperscripts: subSuperscripts ?? this.subSuperscripts,
        strictSubSuperscripts:
            strictSubSuperscripts ?? this.strictSubSuperscripts,
        hideBlockStartup: hideBlockStartup ?? this.hideBlockStartup,
        hideDrawerStartup: hideDrawerStartup ?? this.hideDrawerStartup,
        hideStars: hideStars ?? this.hideStars,
        inlineImages: inlineImages ?? this.inlineImages,
        entityReplacements: entityReplacements ?? this.entityReplacements,
        todoSettings: todoSettings ?? this.todoSettings,
        locale: locale ?? this.locale,
        textDirection: textDirection ?? this.textDirection,
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

  bool get subSuperscripts =>
      firstWhere((layer) => layer.subSuperscripts != null,
          orElse: () => OrgSettings.defaults).subSuperscripts!;

  bool get strictSubSuperscripts =>
      firstWhere((layer) => layer.strictSubSuperscripts != null,
          orElse: () => OrgSettings.defaults).strictSubSuperscripts!;

  bool get hideBlockStartup =>
      firstWhere((layer) => layer.hideBlockStartup != null,
          orElse: () => OrgSettings.defaults).hideBlockStartup!;

  bool get hideDrawerStartup =>
      firstWhere((layer) => layer.hideDrawerStartup != null,
          orElse: () => OrgSettings.defaults).hideDrawerStartup!;

  bool get hideStars => firstWhere((layer) => layer.hideStars != null,
      orElse: () => OrgSettings.defaults).hideStars!;

  bool get inlineImages => firstWhere((layer) => layer.inlineImages != null,
      orElse: () => OrgSettings.defaults).inlineImages!;

  Map<String, String> get entityReplacements =>
      firstWhere((layer) => layer.entityReplacements != null,
          orElse: () => OrgSettings.defaults).entityReplacements!;

  List<OrgTodoStates> get todoSettings =>
      firstWhere((layer) => layer.todoSettings != null,
          orElse: () => OrgSettings.defaults).todoSettings!;

  Locale? get locale => firstWhere((layer) => layer.locale != null,
      orElse: () => OrgSettings.defaults).locale;

  TextDirection? get textDirection =>
      firstWhere((layer) => layer.textDirection != null,
          orElse: () => OrgSettings.defaults).textDirection;
}
