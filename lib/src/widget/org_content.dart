import 'package:flutter/material.dart';
import 'package:org_flutter/src/span.dart';
import 'package:org_parser/org_parser.dart';

/// Generic Org Mode content
class OrgContentWidget extends StatelessWidget {
  const OrgContentWidget(
    this.content, {
    this.transformer,
    this.textAlign,
    super.key,
  });
  final OrgNode content;
  final Transformer? transformer;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return FancySpanBuilder(
      builder: (context, spanBuilder) => Text.rich(
        spanBuilder.build(
          content,
          transformer: transformer ?? identityTransformer,
        ),
        textAlign: textAlign,
      ),
    );
  }
}
