import 'package:flutter/material.dart';
import 'package:org_flutter/src/span.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_parser/org_parser.dart';

class OrgFootnoteWidget extends StatelessWidget {
  const OrgFootnoteWidget(this.footnote, {super.key});
  final OrgFootnote footnote;

  @override
  Widget build(BuildContext context) {
    return FancySpanBuilder(
      builder: (context, spanBuilder) => Text.rich(
        TextSpan(
          children: [
            spanBuilder.build(footnote.marker),
            spanBuilder.build(footnote.content),
            spanBuilder
                .highlightedSpan(removeTrailingLineBreak(footnote.trailing)),
          ],
        ),
      ),
    );
  }
}
