import 'package:flutter/widgets.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:org_flutter/src/span.dart';

class OrgLinkTargetWidget extends StatelessWidget {
  const OrgLinkTargetWidget(this.radioTarget, {super.key});

  final OrgLinkTarget radioTarget;

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
            spanBuilder.highlightedSpan(radioTarget.leading,
                style: targetStyle),
            spanBuilder.highlightedSpan(radioTarget.body, style: targetStyle),
            spanBuilder.highlightedSpan(radioTarget.trailing,
                style: targetStyle),
          ],
        ),
      ),
    );
  }
}
