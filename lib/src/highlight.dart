import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:highlighting/highlighting.dart';
import 'package:highlighting/languages/all.dart';
import 'package:org_flutter/src/widgets.dart';

bool supportedSrcLanguage(String? language) =>
    allLanguages.containsKey(language) ||
    allLanguages.containsKey(language?.toLowerCase());

Widget buildSrcHighlight(
  BuildContext context, {
  required String code,
  required String? languageId,
}) =>
    HighlightView(
      code,
      theme: OrgTheme.dataOf(context).srcTheme ?? {},
      languageId: languageId,
      textStyle: DefaultTextStyle.of(context).style,
    );

// Below copied from:
// https://github.com/akvelon/dart-highlighting/blob/25bc512c66d9eead9012dd129d0a12e77393b828/flutter_highlighting/lib/flutter_highlighting.dart
//
// with the following changes:
//
// - Replace `RichText` with `Text.rich`; see
//   https://github.com/akvelon/dart-highlighting/pull/71
// - Fix lints

/// Highlight Flutter Widget
class HighlightView extends StatelessWidget {
  /// The original code to be highlighted
  final String source;

  /// Highlight language
  ///
  /// It is recommended to give it a value for performance
  ///
  /// [All available languages](https://github.com/akvelon/dart-highlighting/tree/main/highlighting/lib/languages)
  final String? languageId;

  /// Highlight theme
  ///
  /// [All available themes](https://github.com/akvelon/dart-highlighting/tree/main/flutter_highlighting/lib/themes)
  final Map<String, TextStyle> theme;

  /// Padding
  final EdgeInsetsGeometry? padding;

  /// Text styles
  ///
  /// Specify text styles such as font family and font size
  final TextStyle? textStyle;

  HighlightView(
    String input, {
    this.languageId,
    this.theme = const {},
    this.padding,
    this.textStyle,
    int tabSize = 8, // TODO: https://github.com/flutter/flutter/issues/50087
    super.key,
  }) : source = input.replaceAll('\t', ' ' * tabSize);

  List<TextSpan> _convert(List<Node> nodes) {
    List<TextSpan> spans = [];
    var currentSpans = spans;
    List<List<TextSpan>> stack = [];

    traverse(Node node) {
      if (node.value != null) {
        currentSpans.add(node.className == null
            ? TextSpan(text: node.value)
            : TextSpan(text: node.value, style: theme[node.className]));
      } else {
        List<TextSpan> tmp = [];
        currentSpans.add(TextSpan(children: tmp, style: theme[node.className]));
        stack.add(currentSpans);
        currentSpans = tmp;

        for (var n in node.children) {
          traverse(n);
          if (n == node.children.last) {
            currentSpans = stack.isEmpty ? spans : stack.removeLast();
          }
        }
      }
    }

    for (var node in nodes) {
      traverse(node);
    }

    return spans;
  }

  static const _rootKey = 'root';
  static const _defaultFontColor = Color(0xff000000);
  static const _defaultBackgroundColor = Color(0xffffffff);

  // TODO: dart:io is not available at web platform currently
  // See: https://github.com/flutter/flutter/issues/39998
  // So we just use monospace here for now
  static const _defaultFontFamily = 'monospace';

  @override
  Widget build(BuildContext context) {
    var style = TextStyle(
      fontFamily: _defaultFontFamily,
      color: theme[_rootKey]?.color ?? _defaultFontColor,
    );
    if (textStyle != null) {
      style = style.merge(textStyle);
    }

    return Container(
      color: theme[_rootKey]?.backgroundColor ?? _defaultBackgroundColor,
      padding: padding,
      child: Text.rich(
        TextSpan(
          style: style,
          children: _convert(
            // ignore: invalid_use_of_internal_member
            highlight.highlight(languageId ?? '', source, true).nodes ?? [],
          ),
        ),
      ),
    );
  }
}
