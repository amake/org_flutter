import 'package:flutter/material.dart';
import 'package:org_flutter/src/widget/org_content.dart';
import 'package:org_parser/org_parser.dart';

const _kSubSuperScriptScale = 0.7;

/// An Org superscript
class OrgSuperscriptWidget extends StatelessWidget {
  const OrgSuperscriptWidget(this.superscript, {super.key});

  final OrgSuperscript superscript;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    return DefaultTextStyle(
      style: style.copyWith(
        fontSize: style.fontSize! * _kSubSuperScriptScale,
      ),
      child: Transform.translate(
        offset: Offset(0, style.fontSize! * -0.5),
        child: OrgContentWidget(superscript.body),
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
    return DefaultTextStyle(
      style: style.copyWith(
        fontSize: style.fontSize! * _kSubSuperScriptScale,
      ),
      child: Transform.translate(
        offset: Offset(0, style.fontSize! * 0.3),
        child: OrgContentWidget(subscript.body),
      ),
    );
  }
}
