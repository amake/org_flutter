import 'package:flutter/material.dart';
import 'package:org_flutter/src/span.dart';
import 'package:org_parser/org_parser.dart';

/// An Org PGP block
class OrgPgpBlockWidget extends StatelessWidget {
  const OrgPgpBlockWidget(this.block, {super.key});
  final OrgPgpBlock block;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: FancySpanBuilder(
        builder: (context, spanBuilder) => Text.rich(
          TextSpan(children: [
            spanBuilder.highlightedSpan(block.indent),
            spanBuilder.highlightedSpan(block.header),
            spanBuilder.highlightedSpan(block.body),
            spanBuilder.highlightedSpan(block.footer),
            spanBuilder.highlightedSpan(block.trailing),
          ]),
        ),
      ),
    );
  }
}
