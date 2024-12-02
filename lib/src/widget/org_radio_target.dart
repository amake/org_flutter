import 'package:flutter/widgets.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:org_flutter/src/span.dart';

class OrgRadioTargetWidget extends StatelessWidget {
  const OrgRadioTargetWidget(this.radioTarget, {super.key});

  final OrgRadioTarget radioTarget;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final targetStyle = defaultStyle.copyWith(
      decoration: TextDecoration.underline,
    );

    return FancySpanBuilder(
      builder: (context, spanBuilder) => Text.rich(
        TextSpan(
          children: [
            spanBuilder.highlightedSpan(
              radioTarget.leading,
              style: targetStyle,
            ),
            spanBuilder.highlightedSpan(
              radioTarget.body,
              style: targetStyle.copyWith(
                color: OrgTheme.dataOf(context).linkColor,
              ),
            ),
            spanBuilder.highlightedSpan(
              radioTarget.trailing,
              style: targetStyle,
            ),
          ],
        ),
      ),
    );
  }
}
