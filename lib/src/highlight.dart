import 'package:flutter/widgets.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:highlight/languages/all.dart';
import 'package:org_flutter/src/widgets.dart';

bool supportedSrcLanguage(String language) =>
    allLanguages.containsKey(language) ||
    allLanguages.containsKey(language.toLowerCase());

Widget buildSrcHighlight(
  BuildContext context, {
  @required String code,
  @required String language,
}) =>
    HighlightView(
      code,
      theme: OrgTheme.dataOf(context).srcTheme,
      language: language,
      textStyle: DefaultTextStyle.of(context).style,
    );
