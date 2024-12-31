import 'package:flutter/material.dart';
import 'package:org_flutter/src/indent.dart';
import 'package:org_flutter/src/span.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_flutter/src/widget/org_theme.dart';
import 'package:org_parser/org_parser.dart';

/// An Org Mode property
class OrgPropertyWidget extends StatelessWidget {
  const OrgPropertyWidget(this.property, {super.key});
  final OrgProperty property;

  @override
  Widget build(BuildContext context) {
    return IndentBuilder(
      property.indent,
      builder: (context, _) {
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
    yield builder.highlightedSpan(
      property.key,
      style: DefaultTextStyle.of(context)
          .style
          .copyWith(color: OrgTheme.dataOf(context).keywordColor),
    );
    yield builder.build(property.value);
    final trailing = removeTrailingLineBreak(property.trailing);
    if (trailing.isNotEmpty) {
      yield builder.highlightedSpan(trailing);
    }
  }
}
