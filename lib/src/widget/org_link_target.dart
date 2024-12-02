import 'package:flutter/widgets.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:org_flutter/src/flash.dart';
import 'package:org_flutter/src/span.dart';

typedef LinkTargetKey = GlobalKey<OrgLinkTargetWidgetState>;

class OrgLinkTargetWidget extends StatefulWidget {
  const OrgLinkTargetWidget(this.radioTarget, {super.key});

  final OrgLinkTarget radioTarget;

  @override
  State<OrgLinkTargetWidget> createState() => OrgLinkTargetWidgetState();
}

class OrgLinkTargetWidgetState extends State<OrgLinkTargetWidget> {
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
              spanBuilder.highlightedSpan(widget.radioTarget.leading,
                  style: targetStyle),
              spanBuilder.highlightedSpan(widget.radioTarget.body,
                  style: targetStyle),
              spanBuilder.highlightedSpan(widget.radioTarget.trailing,
                  style: targetStyle),
            ],
          ),
        ),
      ),
    );
  }
}
