import 'package:flutter/material.dart';
import 'package:org_flutter/src/indent.dart';
import 'package:org_flutter/src/span.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_parser/org_parser.dart';

/// An Org Mode planning line
class OrgPlanningLineWidget extends StatelessWidget {
  const OrgPlanningLineWidget(this.planningLine, {super.key});
  final OrgPlanningLine planningLine;

  @override
  Widget build(BuildContext context) {
    return IndentBuilder(
      planningLine.indent,
      builder: (context, totalIndentSize) {
        return FancySpanBuilder(
          builder: (context, spanBuilder) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Text.rich(
              TextSpan(
                children: _spans(context, spanBuilder).toList(growable: false),
              ),
            ),
          ),
        );
      },
    );
  }

  Iterable<InlineSpan> _spans(
      BuildContext context, OrgSpanBuilder builder) sync* {
    yield builder.build(planningLine.keyword);
    yield builder.build(planningLine.body);
    final trailing = removeTrailingLineBreak(planningLine.trailing);
    if (trailing.isNotEmpty) {
      yield builder.highlightedSpan(trailing);
    }
  }
}
