import 'package:flutter/widgets.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:org_flutter/src/flash.dart';
import 'package:org_flutter/src/span.dart';

typedef RadioTargetKey = GlobalKey<OrgRadioTargetWidgetState>;

class OrgRadioTargetWidget extends StatefulWidget {
  const OrgRadioTargetWidget(this.radioTarget, {super.key});

  final OrgRadioTarget radioTarget;

  @override
  State<OrgRadioTargetWidget> createState() => OrgRadioTargetWidgetState();
}

class OrgRadioTargetWidgetState extends State<OrgRadioTargetWidget> {
  bool _cookie = true;

  void doHighlight() => setState(() => _cookie = !_cookie);

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final targetStyle = defaultStyle.copyWith(
      decoration: TextDecoration.underline,
    );

    return FancySpanBuilder(
      builder: (context, spanBuilder) => AnimatedTextFlash(
        cookie: _cookie,
        child: Text.rich(
          TextSpan(
            children: [
              spanBuilder.highlightedSpan(
                widget.radioTarget.leading,
                style: targetStyle,
              ),
              spanBuilder.highlightedSpan(
                widget.radioTarget.body,
                style: targetStyle.copyWith(
                  color: OrgTheme.dataOf(context).linkColor,
                ),
              ),
              spanBuilder.highlightedSpan(
                widget.radioTarget.trailing,
                style: targetStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
