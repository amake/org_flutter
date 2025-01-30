import 'package:flutter/material.dart';
import 'package:org_flutter/src/indent.dart';
import 'package:org_flutter/src/settings.dart';
import 'package:org_flutter/src/span.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_parser/org_parser.dart';

/// An Org Mode paragraph
class OrgParagraphWidget extends StatelessWidget {
  const OrgParagraphWidget(this.paragraph, {super.key});
  final OrgParagraph paragraph;

  @override
  Widget build(BuildContext context) {
    final reflow = OrgSettings.of(context).settings.reflowText;
    return IndentBuilder(
      paragraph.indent,
      builder: (context, totalIndentSize) {
        return FancySpanBuilder(
          builder: (context, spanBuilder) => Text.rich(TextSpan(children: [
            spanBuilder.build(
              paragraph.body,
              transformer: (elem, content) {
                final location = locationOf(elem, paragraph.body.children);
                var formattedContent = deindent(content, totalIndentSize);
                if (reflow) {
                  formattedContent = reflowText(formattedContent, location);
                }
                if (location == TokenLocation.end ||
                    location == TokenLocation.only &&
                        paragraph.trailing.isEmpty) {
                  formattedContent = removeTrailingLineBreak(formattedContent);
                }
                return formattedContent;
              },
            ),
            if (paragraph.trailing.isNotEmpty) _trailingSpan(),
          ])),
        );
      },
    );
  }

  TextSpan _trailingSpan() {
    var trailing = removeTrailingLineBreak(paragraph.trailing);
    // A trailing linebreak results in a line with the same height as
    // the previous line. This is bad when the previous line is
    // artificially tall due to a WidgetSpan (especially an image). To
    // avoid this we add a zero-width space to the end if the text has
    // a single, trailing linebreak.
    //
    // See: https://github.com/flutter/flutter/issues/156268
    //
    // TODO(aaron): Limit to when the previous element is a link?
    if (trailing.indexOf('\n') == trailing.length - 1) {
      trailing = '$trailing\u200b';
    }
    return TextSpan(text: trailing);
  }
}
