import 'package:flutter/material.dart';
import 'package:org_flutter/src/controller.dart';
import 'package:org_flutter/src/indent.dart';
import 'package:org_flutter/src/settings.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_flutter/src/widget/org_content.dart';
import 'package:org_parser/org_parser.dart';

/// An Org Mode paragraph
class OrgParagraphWidget extends StatelessWidget {
  const OrgParagraphWidget(this.paragraph, {super.key});
  final OrgParagraph paragraph;

  @override
  Widget build(BuildContext context) {
    final reflow = OrgController.of(context).settings.reflowText;
    return IndentBuilder(
      paragraph.indent,
      builder: (context, totalIndentSize) {
        return OrgContentWidget(
          paragraph.body,
          transformer: (elem, content) {
            final isLast = identical(elem, paragraph.body.children.last);
            var formattedContent = deindent(content, totalIndentSize);
            if (reflow) {
              formattedContent = reflowText(formattedContent, end: isLast);
            }
            if (isLast) {
              final last = removeTrailingLineBreak(formattedContent);
              // A trailing linebreak results in a line with the same height as
              // the previous line. This is bad when the previous line is
              // artificially tall due to a WidgetSpan (especially an image). To
              // avoid this we add a zero-width space to the end if the text has
              // a single, trailing linebreak.
              //
              // See: https://github.com/flutter/flutter/issues/156268
              //
              // TODO(aaron): Limit to when the previous element is a link?
              return last.indexOf('\n') == last.length - 1
                  ? '$last\u200b'
                  : last;
            } else {
              return formattedContent;
            }
          },
        );
      },
    );
  }
}
