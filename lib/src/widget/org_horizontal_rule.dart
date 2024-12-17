import 'package:flutter/material.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_parser/org_parser.dart';

class OrgHorizontalRuleWidget extends StatelessWidget {
  const OrgHorizontalRuleWidget(this.hr, {super.key});
  final OrgHorizontalRule hr;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final trailing = removeTrailingLineBreak(hr.trailing);
    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            child: Container(
              color: defaultStyle.color ?? Colors.black,
              width: double.infinity,
              height: 1,
            ),
            alignment: PlaceholderAlignment.middle,
          ),
          if (trailing.isNotEmpty) TextSpan(text: trailing),
        ],
      ),
    );
  }
}
