import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:org_flutter/src/util.dart';
import 'package:org_parser/org_parser.dart';

// These colors found by
// 1. Finding the face used for something in an org-mode buffer
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
          levelColors: _orgLevelColorsLight,
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
          levelColors: _orgLevelColorsDark,
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
    Iterable<Color> levelColors,
  }) : levelColors =
            levelColors == null ? null : List.unmodifiable(levelColors);

  final Color todoColor;
  final Color doneColor;
  final Color priorityColor;
  final Color drawerColor;
  final Color dateColor;
  final Color codeColor;
  final Color linkColor;
  final Color metaColor;
  final Color macroColor;
  final Color tableColor;
  final Color keywordColor;
  final Color highlightColor;
  final List<Color> levelColors;

  Color levelColor(int level) =>
      levelColors == null ? null : levelColors[level % levelColors.length];

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
    throw Exception('Unknown style: $style');
  }

  OrgThemeData copyWith(
    Color todoColor,
    Color doneColor,
    Color priorityColor,
    Color drawerColor,
    Color dateColor,
    Color codeColor,
    Color linkColor,
    Color metaColor,
    Color macroColor,
    Color tableColor,
    Color keywordColor,
    Color highlightColor,
    Iterable<Color> levelColors,
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
        levelColors: levelColors ?? this.levelColors,
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
        listEquals(levelColors, other.levelColors);
  }

  @override
  int get hashCode => hashValues(
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
        levelColors,
      );

  // ignore: prefer_constructors_over_static_methods
  static OrgThemeData lerp(OrgThemeData a, OrgThemeData b, double t) {
    assert(t != null);
    if (a == null && b == null) {
      return null;
    }
    if (a == null) {
      return OrgThemeData(
        todoColor: Color.lerp(null, b.todoColor, t),
        doneColor: Color.lerp(null, b.doneColor, t),
        priorityColor: Color.lerp(null, b.priorityColor, t),
        drawerColor: Color.lerp(null, b.drawerColor, t),
        dateColor: Color.lerp(null, b.dateColor, t),
        codeColor: Color.lerp(null, b.codeColor, t),
        linkColor: Color.lerp(null, b.linkColor, t),
        metaColor: Color.lerp(null, b.metaColor, t),
        macroColor: Color.lerp(null, b.macroColor, t),
        tableColor: Color.lerp(null, b.tableColor, t),
        keywordColor: Color.lerp(null, b.keywordColor, t),
        highlightColor: Color.lerp(null, b.highlightColor, t),
        levelColors: b.levelColors?.map((c) => Color.lerp(null, c, t)),
      );
    }
    if (b == null) {
      return OrgThemeData(
        todoColor: Color.lerp(a.todoColor, null, t),
        doneColor: Color.lerp(a.doneColor, null, t),
        priorityColor: Color.lerp(a.priorityColor, null, t),
        drawerColor: Color.lerp(a.drawerColor, null, t),
        dateColor: Color.lerp(a.dateColor, null, t),
        codeColor: Color.lerp(a.codeColor, null, t),
        linkColor: Color.lerp(a.linkColor, null, t),
        metaColor: Color.lerp(a.metaColor, null, t),
        macroColor: Color.lerp(a.macroColor, null, t),
        tableColor: Color.lerp(a.tableColor, null, t),
        keywordColor: Color.lerp(a.keywordColor, null, t),
        highlightColor: Color.lerp(a.highlightColor, null, t),
        levelColors: a.levelColors?.map((c) => Color.lerp(c, null, t)),
      );
    }
    return OrgThemeData(
      todoColor: Color.lerp(a.todoColor, b.todoColor, t),
      doneColor: Color.lerp(a.doneColor, b.doneColor, t),
      priorityColor: Color.lerp(a.priorityColor, b.priorityColor, t),
      drawerColor: Color.lerp(a.drawerColor, b.drawerColor, t),
      dateColor: Color.lerp(a.dateColor, b.dateColor, t),
      codeColor: Color.lerp(a.codeColor, b.codeColor, t),
      linkColor: Color.lerp(a.linkColor, b.linkColor, t),
      metaColor: Color.lerp(a.metaColor, b.metaColor, t),
      macroColor: Color.lerp(a.macroColor, b.macroColor, t),
      tableColor: Color.lerp(a.tableColor, b.tableColor, t),
      keywordColor: Color.lerp(a.keywordColor, b.keywordColor, t),
      highlightColor: Color.lerp(a.highlightColor, b.highlightColor, t),
      levelColors: _lerpColorLists(a.levelColors, b.levelColors, t),
    );
  }

  static Iterable<Color> _lerpColorLists(
    List<Color> a,
    List<Color> b,
    double t,
  ) {
    if (a == null || b == null || a.length != b.length) {
      return t < 0.5 ? a : b;
    }
    return zipMap<Color, Color, Color>(a, b, (ac, bc) => Color.lerp(ac, bc, t));
  }
}
