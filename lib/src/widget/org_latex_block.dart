import 'package:material_ui/material_ui.dart';
import 'package:org_flutter/src/events.dart';
import 'package:org_flutter/src/span.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_flutter/src/widget/org_theme.dart';
import 'package:org_parser/org_parser.dart';

/// An Org Mode LaTeX block. Rendering is delegated to
/// [OrgEvents.loadLatexBlock]; without it the LaTeX source is shown.
class OrgLatexBlockWidget extends StatelessWidget {
  const OrgLatexBlockWidget(this.block, {super.key});

  final OrgLatexBlock block;

  @override
  Widget build(BuildContext context) {
    // Remove a line break because we introduce one by splitting the text into
    // two widgets in this Column
    final trailing = removeTrailingLineBreak(block.trailing);
    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints.tightFor(width: double.infinity),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child:
                OrgEvents.of(context).loadLatexBlock?.call(block) ??
                _source(context),
          ),
        ),
        if (trailing.isNotEmpty)
          // Remove another line break because the existence of even an empty
          // string here takes up a line.
          Text(removeTrailingLineBreak(trailing)),
      ],
    );
  }

  // The unrendered source, styled like other code-ish blocks (e.g. fixed-width
  // areas)
  Widget _source(BuildContext context) {
    return DefaultTextStyle.merge(
      style: OrgTheme.dataOf(context)
          .fontStyleForOrgStyle(const TextStyle(), OrgStyle.code),
      child: FancySpanBuilder(
        builder: (context, spanBuilder) => Text.rich(
          spanBuilder.highlightedSpan(
            '${block.begin}${block.content}${block.end}',
          ),
        ),
      ),
    );
  }
}
