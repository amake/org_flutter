import 'package:flutter/material.dart';
import 'package:org_flutter/src/span.dart';
import 'package:org_parser/org_parser.dart';

const _kSubSuperScriptScale = 0.7;

/// An Org superscript
class OrgSuperscriptWidget extends StatelessWidget {
  const OrgSuperscriptWidget(this.superscript, {super.key});

  final OrgSuperscript superscript;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    final body =
        superscript.body.startsWith('{') && superscript.body.endsWith('}')
            ? superscript.body.substring(1, superscript.body.length - 1)
            : superscript.body;
    return FancySpanBuilder(
      builder: (context, spanBuilder) => Transform.translate(
        offset: Offset(0, style.fontSize! * -0.5),
        child: Text.rich(
          spanBuilder.highlightedSpan(
            body,
            style: style.copyWith(
              fontSize: style.fontSize! * _kSubSuperScriptScale,
            ),
          ),
        ),
      ),
    );
  }
}

/// An Org subscript
class OrgSubscriptWidget extends StatelessWidget {
  const OrgSubscriptWidget(this.subscript, {super.key});

  final OrgSubscript subscript;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    final body = subscript.body.startsWith('{') && subscript.body.endsWith('}')
        ? subscript.body.substring(1, subscript.body.length - 1)
        : subscript.body;
    return FancySpanBuilder(
      builder: (context, spanBuilder) => Transform.translate(
        offset: Offset(0, style.fontSize! * 0.3),
        child: Text.rich(
          spanBuilder.highlightedSpan(
            body,
            style: style.copyWith(
              fontSize: style.fontSize! * _kSubSuperScriptScale,
            ),
          ),
        ),
      ),
    );
  }
}
