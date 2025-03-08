import 'package:flutter/material.dart';
import 'package:org_flutter/src/settings.dart';
import 'package:org_flutter/src/span.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_flutter/src/widget/org_theme.dart';
import 'package:org_parser/org_parser.dart';

/// An Org Mode section headline
class OrgHeadlineWidget extends StatelessWidget {
  const OrgHeadlineWidget(
    this.headline, {
    required this.open,
    this.highlighted,
    super.key,
  });
  final OrgHeadline headline;
  final bool open;
  final bool? highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = OrgTheme.dataOf(context);
    final color = headline.tags?.values.contains('ARCHIVE') == true
        // TODO(aaron): Separate archive color from code color
        ? theme.codeColor
        : theme.levelColor(headline.level - 1);
    return DefaultTextStyle.merge(
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        height: 1.8,
      ),
      child: FancySpanBuilder(builder: (context, spanBuilder) {
        final allowFancyLayout = OrgSettings.of(context).settings.reflowText;
        final haveTags = headline.tags != null;
        final simpleLayout = !haveTags || !allowFancyLayout;
        // We don't need to check whether the section has content, because that
        // is already encoded in [open].
        final needEllipsis = !open;
        final tagsInBody = simpleLayout && haveTags;
        final ellipsisInBody = simpleLayout && needEllipsis;
        final textDirection = _textDirection(context);
        final body = _Body(
          headline,
          spanBuilder,
          highlighted: highlighted,
          includeTags: tagsInBody,
          includeEllipsis: ellipsisInBody,
          textDirection: textDirection,
        );
        if (simpleLayout) {
          return body;
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: textDirection,
              children: [
                Expanded(child: body),
                const SizedBox(width: 16),
                ConstrainedBox(
                  constraints:
                      BoxConstraints(maxWidth: constraints.maxWidth / 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text.rich(
                          _tags(headline, spanBuilder),
                          overflow: open ? null : TextOverflow.fade,
                          softWrap: open ? true : false,
                        ),
                      ),
                      if (needEllipsis) const Text('...'),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }

  TextDirection? _textDirection(BuildContext context) =>
      OrgSettings.of(context).settings.textDirection ??
      headline.detectTextDirection();
}

class _Body extends StatelessWidget {
  const _Body(
    this.headline,
    this.spanBuilder, {
    required this.includeTags,
    required this.includeEllipsis,
    required this.highlighted,
    required this.textDirection,
  });

  final OrgHeadline headline;
  final OrgSpanBuilder spanBuilder;
  final bool includeTags;
  final bool includeEllipsis;
  final bool? highlighted;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final theme = OrgTheme.dataOf(context);
      return Text.rich(
        TextSpan(
          children: [
            ..._starsSpans(context),
            if (headline.keyword != null)
              spanBuilder.highlightedSpan(
                  headline.keyword!.value + headline.keyword!.trailing,
                  style: DefaultTextStyle.of(context).style.copyWith(
                      color: headline.keyword!.done
                          ? theme.doneColor
                          : theme.todoColor)),
            if (headline.priority != null)
              spanBuilder.highlightedSpan(
                  headline.priority!.leading +
                      headline.priority!.value +
                      headline.priority!.trailing,
                  style: DefaultTextStyle.of(context)
                      .style
                      .copyWith(color: theme.priorityColor)),
            if (headline.title != null)
              spanBuilder.build(
                headline.title!,
                transformer: (elem, text) {
                  if (identical(elem, headline.title!.children.last)) {
                    if (!includeTags) return text.trimRight();
                    if (_willOverflowWidth(context, constraints)) {
                      return '${text.trimRight()} ';
                    }
                  }
                  return text;
                },
              ),
            if (includeTags) _tags(headline, spanBuilder),
            if (includeEllipsis) const TextSpan(text: '...'),
          ],
        ),
        textDirection: textDirection,
      );
    });
  }

  bool _willOverflowWidth(BuildContext context, BoxConstraints constraints) {
    final idealBounds = _renderedBounds(
      context,
      const BoxConstraints(),
      RichText(
        text: TextSpan(
          text: headline.toMarkup(),
          style: DefaultTextStyle.of(context).style,
        ),
      ),
    );
    return idealBounds.width > constraints.maxWidth;
  }

  Iterable<TextSpan> _starsSpans(BuildContext context) sync* {
    final hideStars = OrgSettings.of(context).settings.hideStars;
    final style = _starStyle(context);
    if (hideStars) {
      yield TextSpan(
        // Real org-mode uses stars painted with the background color to make
        // them invisible; this is only really visible when highlighted in dark
        // mode. Since we don't have a good way to know the actual background
        // color here, we just use spaces instead.
        text: ' ' * (headline.stars.value.length - 1),
        style: style,
      );
      yield TextSpan(text: '*', style: style);
    } else {
      yield TextSpan(text: headline.stars.value, style: style);
    }
    yield TextSpan(text: headline.stars.trailing);
  }

  TextStyle? _starStyle(BuildContext context) {
    // Stars are always the level color, even if the headline is ARCHIVEd.
    var style = DefaultTextStyle.of(context).style.copyWith(
          color: OrgTheme.dataOf(context).levelColor(headline.level - 1),
        );
    if (highlighted == true) {
      style = style.copyWith(
          backgroundColor: OrgTheme.dataOf(context).highlightColor);
    }
    return style;
  }
}

InlineSpan _tags(OrgHeadline headline, OrgSpanBuilder spanBuilder) =>
    spanBuilder.highlightedSpan(headline.tags!.leading +
        headline.tags!.values.join('\u200b:\u200b') +
        headline.tags!.trailing);

Rect _renderedBounds(
  BuildContext context,
  BoxConstraints constraints,
  RichText text,
) {
  final renderObject = text.createRenderObject(context);
  renderObject.layout(constraints);
  final boxes = renderObject.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.text.toPlainText().length),
  );
  return boxes.fold(Rect.zero, (acc, val) => acc.expandToInclude(val.toRect()));
}
