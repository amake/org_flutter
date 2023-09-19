import 'package:flutter/widgets.dart';
import 'package:flutter_highlighting/flutter_highlighting.dart';
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
