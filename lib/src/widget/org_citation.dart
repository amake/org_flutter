import 'package:flutter/material.dart';
import 'package:org_flutter/src/events.dart';
import 'package:org_flutter/src/span.dart';
import 'package:org_flutter/src/widget/org_theme.dart';
import 'package:org_parser/org_parser.dart';

class OrgCitationWidget extends StatelessWidget {
  const OrgCitationWidget(this.citation, {super.key});
  final OrgCitation citation;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final citationStyle = defaultStyle.copyWith(
      color: OrgTheme.dataOf(context).citationColor,
    );

    return FancySpanBuilder(
      builder: (context, spanBuilder) => InkWell(
        onTap: () => _onTap(context),
        child: Text.rich(
          TextSpan(
            children: [
              spanBuilder.highlightedSpan(citation.leading,
                  style: citationStyle),
              if (citation.style != null)
                spanBuilder.highlightedSpan(citation.style!.leading,
                    style: citationStyle),
              if (citation.style != null)
                spanBuilder.highlightedSpan(citation.style!.value,
                    style: citationStyle),
              spanBuilder.highlightedSpan(citation.delimiter,
                  style: citationStyle),
              spanBuilder.highlightedSpan(citation.body, style: citationStyle),
              spanBuilder.highlightedSpan(citation.trailing,
                  style: citationStyle),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context) =>
      OrgEvents.of(context).onCitationTap?.call(citation);
}
