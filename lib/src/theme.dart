import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_parser/org_parser.dart';

// These colors found by
// 1. Finding the face used for something in an Org Mode buffer
// 2. Finding the definition of the face or its root ancestor
// 3. Finding the color name for max colors and light/dark background
// 4. Converting color name to hex with
/*
(kill-new
 (mapconcat (lambda (pct)
              (format "%02x" (* 255 pct)))
            (color-name-to-rgb COLORNAME)
            ""))
 */

const _orgLevelColorsLight = [
  Color(0xff0000ff),
  Color(0xffa0522d),
  Color(0xffa020f0),
  Color(0xffb22222),
  Color(0xff228b22),
  Color(0xff008b8b),
  Color(0xff483d8b),
  Color(0xff8b2252),
];
const _orgTodoColorLight = Color(0xffff0000);
const _orgDoneColorLight = Color(0xff228b22);
const _orgPriorityColorLight = Color(0xffa020f0);
const _orgDrawerColorLight = Color(0xff0000ff);
const _orgDateColorLight = Color(0xffa020f0);
const _orgCodeColorLight = Color(0xff7f7f7f);
const _orgLinkColorLight = Color(0xff3a5fcd);
const _orgMetaColorLight = Color(0xffb22222);
const _orgMacroColorLight = Color(0xff8b4513);
const _orgTableColorLight = Color(0xff0000ff);
const _orgKeywordColorLight = Color(0xffa020f0);
const _orgHighlightColorLight = Color(0xffffff00);
const _orgFootnoteColorLight = Color(0xffa020f0);

const _orgLevelColorsDark = [
  Color(0xff87cefa),
  Color(0xffeedd82),
  Color(0xff00ffff),
  Color(0xffff7f24),
  Color(0xff98fb98),
  Color(0xff7fffd4),
  Color(0xffb0c4de),
  Color(0xffffa07a),
];
const _orgTodoColorDark = Color(0xffffc0cb);
const _orgDoneColorDark = Color(0xff98fb98);
const _orgPriorityColorDark = Color(0xff00ffff);
const _orgDrawerColorDark = Color(0xff87cefa);
const _orgDateColorDark = Color(0xff00ffff);
const _orgCodeColorDark = Color(0xffb3b3b3);
const _orgLinkColorDark = Color(0xff00ffff);
const _orgMetaColorDark = Color(0xffff7f24);
const _orgMacroColorDark = Color(0xffdeb887);
const _orgTableColorDark = Color(0xff87cefa);
const _orgKeywordColorDark = Color(0xff00ffff);
const _orgHighlightColorDark = Color(0xff4a708b);
const _orgFootnoteColorDark = Color(0xff00ffff);

const _orgRootPadding = EdgeInsets.all(8);

// Key meanings documented here:
// https://github.com/highlightjs/highlight.js/blob/d72f0817aaab8187711fca7c608f5272ea5147f6/docs/css-classes-reference.rst
const _orgSrcThemeLight = {
  'root': TextStyle(backgroundColor: Colors.transparent),
  'subst': TextStyle(color: Color(0xffa0522d)), // font-lock-variable-name-face
  'comment': TextStyle(color: Color(0xffb22222)), // font-lock-comment-face
  'keyword': TextStyle(color: Color(0xffa020f0)), // font-lock-keyword-face
  'attribute': TextStyle(color: Color(0xffa020f0)), // css-property
  'selector-tag': TextStyle(color: Color(0xff0000ff)), // css-selector
  'meta-keyword': TextStyle(color: Color(0xff483d8b)), // font-lock-builtin-face
  'doctag': TextStyle(color: Color(0xff008b8b)), // font-lock-constant-face
  'name': TextStyle(color: Color(0xff0000ff)), // nxml-element-local-name
  'type': TextStyle(color: Color(0xff228b22)), // font-lock-type-face
  'string': TextStyle(color: Color(0xff8b2252)), // font-lock-string-face
  'number': TextStyle(color: Color(0xff008b8b)), // font-lock-constant-face
  'selector-id': TextStyle(color: Color(0xff0000ff)), // css-selector
  'selector-class': TextStyle(color: Color(0xff0000ff)), // css-selector
  'quote': TextStyle(color: Color(0xff880000)), // markdown-blockquote-face
  'template-tag':
      TextStyle(color: Color(0xff0000ff)), // font-lock-function-name-face
  'deletion': TextStyle(backgroundColor: Color(0xffffeeee)), // diff-removed
  'title': TextStyle(color: Color(0xff0000ff)), // font-lock-function-name-face
  'section': TextStyle(color: Color(0xff0000ff)), // markdown-header-face
  'regexp': TextStyle(color: Color(0xff8b2252)), // font-lock-string-face
  'symbol': TextStyle(color: Color(0xff008b8b)), // font-lock-constant-face
  'variable':
      TextStyle(color: Color(0xffa0522d)), // font-name-variable-name-face
  'template-variable':
      TextStyle(color: Color(0xffa0522d)), // font-name-variable-name-face
  'link': TextStyle(color: Color(0xff8b2252)), // markdown-url-face
  'selector-attr': TextStyle(color: Color(0xff0000ff)), // css-selector
  'selector-pseudo': TextStyle(color: Color(0xff0000ff)), // css-selector
  'literal': TextStyle(color: Color(0xff008b8b)), // font-lock-constant-face
  'built_in': TextStyle(color: Color(0xff483d8b)), // font-lock-builtin-face
  'bullet': TextStyle(color: Color(0xff7f7f7f)), // markdown-list-face
  'code': TextStyle(color: Color(0xff008b8b)), // markdown-pre-face
  'addition': TextStyle(backgroundColor: Color(0xffeeffee)), // diff-added
  'meta': TextStyle(color: Color(0xff008b8b)), // c-annotation-face
  'meta-string': TextStyle(color: Color(0xff8b2252)), // font-lock-string-face
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  'strong': TextStyle(fontWeight: FontWeight.bold),
};

const _orgSrcThemeDark = {
  'root': TextStyle(backgroundColor: Colors.transparent),
  'subst': TextStyle(color: Color(0xffeedd82)), // font-lock-variable-name-face
  'comment': TextStyle(color: Color(0xffff7f24)), // font-lock-comment-face
  'keyword': TextStyle(color: Color(0xff00ffff)), // font-lock-keyword-face
  'attribute': TextStyle(color: Color(0xff00ffff)), // css-property
  'selector-tag': TextStyle(color: Color(0xff87cefa)), // css-selector
  'meta-keyword': TextStyle(color: Color(0xffb0c4de)), // font-lock-builtin-face
  'doctag': TextStyle(color: Color(0xff7fffd4)), // font-lock-constant-face
  'name': TextStyle(color: Color(0xff87cefa)), // nxml-element-local-name
  'type': TextStyle(color: Color(0xff98fb98)), // font-lock-type-face
  'string': TextStyle(color: Color(0xffffa07a)), // font-lock-string-face
  'number': TextStyle(color: Color(0xff7fffd4)), // font-lock-constant-face
  'selector-id': TextStyle(color: Color(0xff87cefa)), // css-selector
  'selector-class': TextStyle(color: Color(0xff87cefa)), // css-selector
  'quote': TextStyle(color: Color(0xffffa07a)), // markdown-blockquote-face
  'template-tag':
      TextStyle(color: Color(0xff87cefa)), // font-lock-function-name-face
  'deletion': TextStyle(backgroundColor: Color(0xff553333)), // diff-removed
  'title': TextStyle(color: Color(0xff87cefa)), // font-lock-function-name-face
  'section': TextStyle(color: Color(0xff87cefa)), // markdown-header-face
  'regexp': TextStyle(color: Color(0xffffa07a)), // font-lock-string-face
  'symbol': TextStyle(color: Color(0xff7fffd4)), // font-lock-constant-face
  'variable':
      TextStyle(color: Color(0xffeedd82)), // font-name-variable-name-face
  'template-variable':
      TextStyle(color: Color(0xffeedd82)), // font-name-variable-name-face
  'link': TextStyle(color: Color(0xffffa07a)), // markdown-url-face
  'selector-attr': TextStyle(color: Color(0xff87cefa)), // css-selector
  'selector-pseudo': TextStyle(color: Color(0xff87cefa)), // css-selector
  'literal': TextStyle(color: Color(0xff7fffd4)), // font-lock-constant-face
  'built_in': TextStyle(color: Color(0xffb0c4de)), // font-lock-builtin-face
  'bullet': TextStyle(color: Color(0xffb3b3b3)), // markdown-list-face
  'code': TextStyle(color: Color(0xff7fffd4)), // markdown-pre-face
  'addition': TextStyle(backgroundColor: Color(0xff335533)), // diff-added
  'meta': TextStyle(color: Color(0xff7fffd4)), // c-annotation-face
  'meta-string': TextStyle(color: Color(0xffffa07a)), // font-lock-string-face
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  'strong': TextStyle(fontWeight: FontWeight.bold),
};

class OrgThemeData {
  OrgThemeData.light()
      : this(
          todoColor: _orgTodoColorLight,
          doneColor: _orgDoneColorLight,
          priorityColor: _orgPriorityColorLight,
          drawerColor: _orgDrawerColorLight,
          dateColor: _orgDateColorLight,
          codeColor: _orgCodeColorLight,
          linkColor: _orgLinkColorLight,
          metaColor: _orgMetaColorLight,
          macroColor: _orgMacroColorLight,
          tableColor: _orgTableColorLight,
          keywordColor: _orgKeywordColorLight,
          highlightColor: _orgHighlightColorLight,
          footnoteColor: _orgFootnoteColorLight,
          levelColors: _orgLevelColorsLight,
          srcTheme: _orgSrcThemeLight,
          rootPadding: _orgRootPadding,
        );

  OrgThemeData.dark()
      : this(
          todoColor: _orgTodoColorDark,
          doneColor: _orgDoneColorDark,
          priorityColor: _orgPriorityColorDark,
          drawerColor: _orgDrawerColorDark,
          dateColor: _orgDateColorDark,
          codeColor: _orgCodeColorDark,
          linkColor: _orgLinkColorDark,
          metaColor: _orgMetaColorDark,
          macroColor: _orgMacroColorDark,
          tableColor: _orgTableColorDark,
          keywordColor: _orgKeywordColorDark,
          highlightColor: _orgHighlightColorDark,
          footnoteColor: _orgFootnoteColorDark,
          levelColors: _orgLevelColorsDark,
          srcTheme: _orgSrcThemeDark,
          rootPadding: _orgRootPadding,
        );

  OrgThemeData({
    this.todoColor,
    this.doneColor,
    this.priorityColor,
    this.drawerColor,
    this.dateColor,
    this.codeColor,
    this.linkColor,
    this.metaColor,
    this.macroColor,
    this.tableColor,
    this.keywordColor,
    this.highlightColor,
    this.footnoteColor,
    this.rootPadding,
    Iterable<Color>? levelColors,
    Map<String, TextStyle>? srcTheme,
  })  : levelColors =
            levelColors == null ? null : List.unmodifiable(levelColors),
        srcTheme = srcTheme == null ? null : Map.unmodifiable(srcTheme);

  final Color? todoColor;
  final Color? doneColor;
  final Color? priorityColor;
  final Color? drawerColor;
  final Color? dateColor;
  final Color? codeColor;
  final Color? linkColor;
  final Color? metaColor;
  final Color? macroColor;
  final Color? tableColor;
  final Color? keywordColor;
  final Color? highlightColor;
  final Color? footnoteColor;
  final List<Color>? levelColors;
  final Map<String, TextStyle>? srcTheme;

  final EdgeInsets? rootPadding;

  Color? levelColor(int level) {
    final levelColors = this.levelColors;
    return levelColors == null ? null : levelColors[level % levelColors.length];
  }

  TextStyle fontStyleForOrgStyle(TextStyle base, OrgStyle style) {
    switch (style) {
      case OrgStyle.bold:
        return base.copyWith(fontWeight: FontWeight.bold);
      case OrgStyle.verbatim: // fallthrough
      case OrgStyle.code:
        return base.copyWith(color: codeColor);
      case OrgStyle.italic:
        return base.copyWith(fontStyle: FontStyle.italic);
      case OrgStyle.strikeThrough:
        return base.copyWith(decoration: TextDecoration.lineThrough);
      case OrgStyle.underline:
        return base.copyWith(decoration: TextDecoration.underline);
    }
  }

  OrgThemeData copyWith(
    Color? todoColor,
    Color? doneColor,
    Color? priorityColor,
    Color? drawerColor,
    Color? dateColor,
    Color? codeColor,
    Color? linkColor,
    Color? metaColor,
    Color? macroColor,
    Color? tableColor,
    Color? keywordColor,
    Color? highlightColor,
    Color? footnoteColor,
    Iterable<Color>? levelColors,
    Map<String, TextStyle>? srcTheme,
    EdgeInsets? rootPadding,
  ) =>
      OrgThemeData(
        todoColor: todoColor ?? this.todoColor,
        doneColor: doneColor ?? this.doneColor,
        priorityColor: priorityColor ?? this.priorityColor,
        drawerColor: drawerColor ?? this.drawerColor,
        dateColor: dateColor ?? this.dateColor,
        codeColor: codeColor ?? this.codeColor,
        linkColor: linkColor ?? this.linkColor,
        metaColor: metaColor ?? this.metaColor,
        macroColor: macroColor ?? this.macroColor,
        tableColor: tableColor ?? this.tableColor,
        keywordColor: keywordColor ?? this.keywordColor,
        highlightColor: highlightColor ?? this.highlightColor,
        footnoteColor: footnoteColor ?? this.footnoteColor,
        levelColors: levelColors ?? this.levelColors,
        srcTheme: srcTheme ?? this.srcTheme,
        rootPadding: rootPadding ?? this.rootPadding,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrgThemeData &&
        todoColor == other.todoColor &&
        doneColor == other.doneColor &&
        priorityColor == other.priorityColor &&
        drawerColor == other.drawerColor &&
        dateColor == other.dateColor &&
        codeColor == other.codeColor &&
        linkColor == other.linkColor &&
        metaColor == other.metaColor &&
        macroColor == other.macroColor &&
        tableColor == other.tableColor &&
        keywordColor == other.keywordColor &&
        highlightColor == other.highlightColor &&
        footnoteColor == other.footnoteColor &&
        listEquals(levelColors, other.levelColors) &&
        mapEquals(srcTheme, other.srcTheme) &&
        rootPadding == other.rootPadding;
  }

  @override
  int get hashCode => Object.hash(
        todoColor,
        doneColor,
        priorityColor,
        drawerColor,
        dateColor,
        codeColor,
        linkColor,
        metaColor,
        macroColor,
        tableColor,
        keywordColor,
        highlightColor,
        footnoteColor,
        levelColors,
        srcTheme,
        rootPadding,
      );

  // ignore: prefer_constructors_over_static_methods
  static OrgThemeData? lerp(OrgThemeData? a, OrgThemeData? b, double t) {
    if (a == null && b == null) {
      return null;
    }
    return OrgThemeData(
      todoColor: Color.lerp(a?.todoColor, b?.todoColor, t),
      doneColor: Color.lerp(a?.doneColor, b?.doneColor, t),
      priorityColor: Color.lerp(a?.priorityColor, b?.priorityColor, t),
      drawerColor: Color.lerp(a?.drawerColor, b?.drawerColor, t),
      dateColor: Color.lerp(a?.dateColor, b?.dateColor, t),
      codeColor: Color.lerp(a?.codeColor, b?.codeColor, t),
      linkColor: Color.lerp(a?.linkColor, b?.linkColor, t),
      metaColor: Color.lerp(a?.metaColor, b?.metaColor, t),
      macroColor: Color.lerp(a?.macroColor, b?.macroColor, t),
      tableColor: Color.lerp(a?.tableColor, b?.tableColor, t),
      keywordColor: Color.lerp(a?.keywordColor, b?.keywordColor, t),
      highlightColor: Color.lerp(a?.highlightColor, b?.highlightColor, t),
      footnoteColor: Color.lerp(a?.footnoteColor, b?.footnoteColor, t),
      levelColors: _lerpColorLists(a?.levelColors, b?.levelColors, t),
      srcTheme: _lerpSrcThemes(a?.srcTheme, b?.srcTheme, t),
      rootPadding: EdgeInsets.lerp(a?.rootPadding, b?.rootPadding, t),
    );
  }

  static Iterable<Color>? _lerpColorLists(
    List<Color>? a,
    List<Color>? b,
    double t,
  ) {
    if (a == null || b == null || a.length != b.length) {
      return t < 0.5 ? a : b;
    }
    return zipMap<Color, Color, Color>(
      a,
      b,
      (ac, bc) => Color.lerp(ac, bc, t)!,
    );
  }

  static Map<String, TextStyle>? _lerpSrcThemes(
    Map<String, TextStyle>? a,
    Map<String, TextStyle>? b,
    double t,
  ) {
    if (a == null ||
        b == null ||
        a.length != b.length ||
        !listEquals(
          a.keys.toList(growable: false),
          b.keys.toList(growable: false),
        )) {
      return t < 0.5 ? a : b;
    }
    return a.map((k, ae) => MapEntry(k, TextStyle.lerp(ae, b[k], t)!));
  }
}
