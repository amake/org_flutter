import 'package:flutter/material.dart';
import 'package:org_flutter/src/highlight.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_flutter/src/widget/org_theme.dart';
import 'package:org_parser/org_parser.dart';

/// An Org Mode inline source block
class OrgInlineSrcBlockWidget extends StatelessWidget {
  const OrgInlineSrcBlockWidget(this.block, {super.key});

  final OrgInlineSrcBlock block;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final orgTheme = OrgTheme.dataOf(context);
    final codeStyle = defaultStyle.copyWith(color: orgTheme.codeColor);
    final metaStyle = defaultStyle.copyWith(color: orgTheme.metaColor);
    return Text.rich(TextSpan(children: [
      TextSpan(text: block.leading, style: codeStyle),
      TextSpan(text: block.language, style: metaStyle),
      if (block.arguments != null)
        TextSpan(text: block.arguments, style: codeStyle),
      TextSpan(text: '{', style: codeStyle),
      if (supportedSrcLanguage(block.language))
        WidgetSpan(
          child: buildSrcHighlight(
            context,
            code: trimPrefSuff(block.body, '{', '}'),
            languageId: block.language,
          ),
        )
      else
        TextSpan(text: trimPrefSuff(block.body, '{', '}'), style: codeStyle),
      TextSpan(text: '}', style: codeStyle),
    ]));
  }
}
