import 'package:material_ui/material_ui.dart';
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
    final blockTextStyle = orgTheme.blockTextStyle;
    final blockStyle = defaultStyle
        .merge(blockTextStyle)
        .copyWith(color: orgTheme.codeColor);
    // The language keeps metaColor while inheriting the block's other styles.
    final languageStyle = defaultStyle
        .merge(blockTextStyle)
        .copyWith(color: orgTheme.metaColor);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: block.leading, style: blockStyle),
          TextSpan(text: block.language, style: languageStyle),
          if (block.arguments != null)
            TextSpan(text: block.arguments, style: blockStyle),
          TextSpan(text: '{', style: blockStyle),
          if (supportedSrcLanguage(block.language))
            buildSrcHighlightSpan(
              context,
              code: trimPrefSuff(block.body, '{', '}'),
              languageId: block.language,
            )
          else
            TextSpan(
              text: trimPrefSuff(block.body, '{', '}'),
              style: blockStyle,
            ),
          TextSpan(text: '}', style: blockStyle),
        ],
      ),
    );
  }
}
