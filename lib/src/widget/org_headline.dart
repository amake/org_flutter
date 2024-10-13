import 'package:flutter/material.dart';
import 'package:org_flutter/src/controller.dart';
import 'package:org_flutter/src/settings.dart';
import 'package:org_flutter/src/span.dart';
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
    final color = theme.levelColor(headline.level - 1);
    return DefaultTextStyle.merge(
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        height: 1.8,
      ),
      child: FancySpanBuilder(
        builder: (context, spanBuilder) {
          final body = Text.rich(
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
                        return text.trimRight();
                      } else {
                        return text;
                      }
                    },
                  ),
                if (!open && headline.tags == null) const TextSpan(text: '...'),
              ],
            ),
          );
          if (headline.tags == null) {
            return body;
          } else {
            return LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                              spanBuilder.highlightedSpan(headline
                                      .tags!.leading +
                                  headline.tags!.values.join('\u200b:\u200b') +
                                  headline.tags!.trailing),
                              overflow: open ? null : TextOverflow.fade,
                              softWrap: open ? true : false,
                            ),
                          ),
                          if (!open) const Text('...'),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          }
        },
      ),
    );
  }

  Iterable<TextSpan> _starsSpans(BuildContext context) sync* {
    final hideStars = OrgController.of(context).settings.hideStars;
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

  TextStyle? _starStyle(BuildContext context) => highlighted == true
      ? DefaultTextStyle.of(context)
          .style
          .copyWith(backgroundColor: OrgTheme.dataOf(context).highlightColor)
      : null;
}
