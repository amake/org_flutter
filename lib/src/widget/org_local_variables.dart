import 'package:flutter/material.dart';
import 'package:org_flutter/src/span.dart';
import 'package:org_flutter/src/widget/org_theme.dart';
import 'package:org_parser/org_parser.dart';

/// An Org Local Variables block
class OrgLocalVariablesWidget extends StatelessWidget {
  const OrgLocalVariablesWidget(this.variables, {super.key});
  final OrgLocalVariables variables;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final metaStyle =
        defaultStyle.copyWith(color: OrgTheme.dataOf(context).metaColor);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: FancySpanBuilder(
        builder: (context, spanBuilder) => Text.rich(
          TextSpan(children: [
            spanBuilder.highlightedSpan(variables.start, style: metaStyle),
            for (final entry in variables.entries)
              spanBuilder.highlightedSpan(
                entry.prefix + entry.content + entry.suffix,
                style: metaStyle,
              ),
            spanBuilder.highlightedSpan(variables.end, style: metaStyle),
          ]),
        ),
      ),
    );
  }
}
