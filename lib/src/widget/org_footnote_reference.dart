import 'package:flutter/material.dart';
import 'package:org_flutter/src/controller.dart';
import 'package:org_flutter/src/flash.dart';
import 'package:org_flutter/src/span.dart';
import 'package:org_flutter/src/widget/org_theme.dart';
import 'package:org_parser/org_parser.dart';

typedef FootnoteKey = GlobalKey<OrgFootnoteReferenceWidgetState>;

class OrgFootnoteReferenceWidget extends StatefulWidget {
  const OrgFootnoteReferenceWidget(this.reference, {super.key});
  final OrgFootnoteReference reference;

  @override
  State<OrgFootnoteReferenceWidget> createState() =>
      OrgFootnoteReferenceWidgetState();
}

class OrgFootnoteReferenceWidgetState
    extends State<OrgFootnoteReferenceWidget> {
  bool _cookie = true;

  void doHighlight() => setState(() => _cookie = !_cookie);

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final footnoteStyle = defaultStyle.copyWith(
      color: OrgTheme.dataOf(context).footnoteColor,
    );

    return FancySpanBuilder(
      builder: (context, spanBuilder) => InkWell(
        onTap: widget.reference.name == null
            ? null
            : () => OrgController.of(context).jumpToFootnote(widget.reference),
        child: AnimatedTextFlash(
          cookie: _cookie,
          child: Text.rich(
            TextSpan(
              children: [
                spanBuilder.highlightedSpan(widget.reference.leading,
                    style: footnoteStyle),
                if (widget.reference.name != null)
                  spanBuilder.highlightedSpan(widget.reference.name!,
                      style: footnoteStyle),
                if (widget.reference.definition != null)
                  spanBuilder.highlightedSpan(
                      widget.reference.definition!.delimiter,
                      style: footnoteStyle),
                if (widget.reference.definition != null)
                  spanBuilder.build(
                    widget.reference.definition!.value,
                    style: footnoteStyle,
                  ),
                spanBuilder.highlightedSpan(widget.reference.trailing,
                    style: footnoteStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
