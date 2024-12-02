import 'package:flutter/material.dart';
import 'package:org_flutter/src/controller.dart';
import 'package:org_flutter/src/span.dart';
import 'package:org_flutter/src/widget/org_theme.dart';
import 'package:org_parser/org_parser.dart';

class OrgFootnoteReferenceWidget extends StatelessWidget {
  const OrgFootnoteReferenceWidget(this.reference, {super.key});
  final OrgFootnoteReference reference;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final footnoteStyle = defaultStyle.copyWith(
      color: OrgTheme.dataOf(context).footnoteColor,
    );

    return FancySpanBuilder(
      builder: (context, spanBuilder) => InkWell(
        onTap: reference.name == null
            ? null
            : () => OrgController.of(context).jumpToFootnote(reference),
        child: Text.rich(
          TextSpan(
            children: [
              spanBuilder.highlightedSpan(reference.leading,
                  style: footnoteStyle),
              if (reference.name != null)
                spanBuilder.highlightedSpan(reference.name!,
                    style: footnoteStyle),
              if (reference.definition != null)
                spanBuilder.highlightedSpan(reference.definition!.delimiter,
                    style: footnoteStyle),
              if (reference.definition != null)
                spanBuilder.build(
                  reference.definition!.value,
                  style: footnoteStyle,
                ),
              spanBuilder.highlightedSpan(reference.trailing,
                  style: footnoteStyle),
            ],
          ),
        ),
      ),
    );
  }
}
