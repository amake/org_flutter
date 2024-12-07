import 'package:flutter/material.dart';
import 'package:flutter_tex_js/flutter_tex_js.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_parser/org_parser.dart';

/// An Org Mode LaTeX block
class OrgLatexBlockWidget extends StatelessWidget {
  const OrgLatexBlockWidget(this.block, {super.key});

  final OrgLatexBlock block;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints.tightFor(width: double.infinity),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: TexImage(
              _content,
              displayMode: true,
              error: (context, error) {
                debugPrint(error.toString());
                return Text(block.toMarkup());
              },
            ),
          ),
        ),
        // Remove two linebreaks because we introduce two by splitting the
        // text into two widgets in this Column
        Text(removeTrailingLineBreak(removeTrailingLineBreak(block.trailing))),
      ],
    );
  }

  String get _content {
    if (flutterTexJsSupportedEnvironments.contains(block.environment)) {
      return '${block.begin}${block.content}${block.end}';
    } else {
      return block.content;
    }
  }
}
