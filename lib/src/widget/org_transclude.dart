import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:org_flutter/src/indent.dart';
import 'package:org_flutter/src/span.dart';
import 'package:org_flutter/src/util/util.dart';

class OrgTranscludeWidget extends StatefulWidget {
  final OrgMeta meta;

  const OrgTranscludeWidget(this.meta, {super.key});

  @override
  State<OrgTranscludeWidget> createState() => _OrgTranscludeWidgetState();
}

class _OrgTranscludeWidgetState extends State<OrgTranscludeWidget>
    with OpenCloseable {
  @override
  bool get defaultOpen => false;

  @override
  Widget build(BuildContext context) {
    final loader = OrgEvents.of(context).loadTransclusion;
    if (loader == null || widget.meta.find<OrgLink>((_) => true) == null) {
      return OrgMetaWidget(widget.meta);
    }

    final trailing = removeTrailingLineBreak(widget.meta.trailing);

    return Column(
      children: [
        IndentBuilder(
          widget.meta.indent,
          builder: (context, _) {
            final deemphasize =
                OrgSettings.of(context).settings.deemphasizeMarkup;
            Widget body = InheritedOrgSettings.merge(
              const OrgSettings(strictSubSuperscripts: true),
              child: FancySpanBuilder(
                builder: (context, spanBuilder) => Text.rich(
                  TextSpan(
                    children: _spans(context, spanBuilder)
                        .whereType<InlineSpan>()
                        .toList(growable: false),
                  ),
                  softWrap: !deemphasize,
                ),
              ),
            );
            if (deemphasize) {
              body = reduceOpacity(SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: body,
              ));
            }
            return body;
          },
        ),
        ValueListenableBuilder(
          valueListenable: openListenable,
          builder: (context, open, child) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 100),
              transitionBuilder: (child, animation) =>
                  SizeTransition(sizeFactor: animation, child: child),
              child: open ? child : const SizedBox.shrink(),
            );
          },
          child: Container(
            padding: EdgeInsets.only(
                left: OrgTheme.dataOf(context).rootPadding?.left ?? 8),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  // TODO(aaron): Figure out what color this should really be
                  color: DefaultTextStyle.of(context).style.color!,
                  width: 1,
                ),
              ),
            ),
            child: loader(widget.meta),
          ),
        ),
        if (trailing.isNotEmpty) Text(removeTrailingLineBreak(trailing))
      ],
    );
  }

  Iterable<InlineSpan?> _spans(
      BuildContext context, OrgSpanBuilder builder) sync* {
    final style = DefaultTextStyle.of(context).style;
    yield builder.highlightedSpan(
      widget.meta.key,
      style: style.copyWith(color: OrgTheme.dataOf(context).transcludeColor),
      recognizer: TapGestureRecognizer()
        ..onTap = () => openListenable.value = !openListenable.value,
    );

    final valueStyle =
        style.copyWith(color: OrgTheme.dataOf(context).metaColor);
    yield builder.build(widget.meta.value!, style: valueStyle);
  }
}
