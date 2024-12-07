import 'package:flutter/material.dart';
import 'package:org_flutter/src/controller.dart';
import 'package:org_flutter/src/settings.dart';
import 'package:org_flutter/src/span.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_flutter/src/widget/org_theme.dart';
import 'package:org_parser/org_parser.dart';

/// An Org comment
class OrgCommentWidget extends StatelessWidget {
  const OrgCommentWidget(this.comment, {super.key});
  final OrgComment comment;

  @override
  Widget build(BuildContext context) {
    final hideMarkup = OrgController.of(context).settings.deemphasizeMarkup;
    final body = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: FancySpanBuilder(
        builder: (context, spanBuilder) {
          final metaStyle = DefaultTextStyle.of(context)
              .style
              .copyWith(color: OrgTheme.dataOf(context).metaColor);
          return Text.rich(
            TextSpan(children: [
              spanBuilder.highlightedSpan(comment.indent, style: metaStyle),
              spanBuilder.highlightedSpan(comment.start, style: metaStyle),
              spanBuilder.highlightedSpan(
                comment.content,
                style: metaStyle,
              ),
              spanBuilder.highlightedSpan(
                removeTrailingLineBreak(comment.trailing),
                style: metaStyle,
              ),
            ]),
          );
        },
      ),
    );
    return reduceOpacity(body, enabled: hideMarkup);
  }
}
