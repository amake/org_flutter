import 'package:flutter/material.dart';
import 'package:flutter_tex_js/flutter_tex_js.dart';
import 'package:org_parser/org_parser.dart';

/// An Org Mode LaTeX inline span
class OrgLatexInlineWidget extends StatelessWidget {
  const OrgLatexInlineWidget(this.latex, {super.key});

  final OrgLatexInline latex;

  @override
  Widget build(BuildContext context) {
    return TexImage(
      latex.content,
      displayMode: false,
      error: (context, error) {
        debugPrint(error.toString());
        return Text([
          latex.leadingDecoration,
          latex.content,
          latex.trailingDecoration,
        ].join(''));
      },
    );
  }
}
