import 'package:flutter/material.dart';
import 'package:org_flutter/src/events.dart';
import 'package:org_flutter/src/indent.dart';
import 'package:org_flutter/src/settings.dart';
import 'package:org_flutter/src/span.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_parser/org_parser.dart';

/// An Org Mode list
class OrgListWidget extends StatelessWidget {
  const OrgListWidget(this.list, {super.key});
  final OrgList list;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _children.toList(growable: false),
    );
  }

  Iterable<Widget> get _children sync* {
    for (final item in list.items) {
      yield _OrgListItemWidget(item);
    }
    final trailing = removeTrailingLineBreak(list.trailing);
    if (trailing.isNotEmpty) {
      yield Text(trailing);
    }
  }
}

/// An Org Mode list item
class _OrgListItemWidget extends StatelessWidget {
  const _OrgListItemWidget(this.item);
  final OrgListItem item;

  @override
  Widget build(BuildContext context) {
    return IndentBuilder(
      '${item.indent}${item.bullet}',
      builder: (context, totalIndentSize) => InkWell(
        onTap: _hasCheckbox
            ? () => OrgEvents.of(context).onListItemTap?.call(item)
            : null,
        child: FancySpanBuilder(
          builder: (context, spanBuilder) => Text.rich(
            TextSpan(
              children: _spans(context, spanBuilder, totalIndentSize)
                  .toList(growable: false),
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasCheckbox => item.checkbox != null;

  Iterable<InlineSpan> _spans(
    BuildContext context,
    OrgSpanBuilder builder,
    int totalIndentSize,
  ) sync* {
    final item = this.item;
    if (item is OrgListOrderedItem && item.counterSet != null) {
      yield builder.highlightedSpan(
        '${item.counterSet} ',
        style: DefaultTextStyle.of(context)
            .style
            .copyWith(fontWeight: FontWeight.bold),
      );
    }
    if (item.checkbox != null) {
      yield builder.highlightedSpan(
        '${item.checkbox} ',
        style: DefaultTextStyle.of(context)
            .style
            .copyWith(fontWeight: FontWeight.bold),
      );
    }
    if (item is OrgListUnorderedItem && item.tag != null) {
      final style = DefaultTextStyle.of(context)
          .style
          .copyWith(fontWeight: FontWeight.bold);
      yield TextSpan(children: [
        builder.build(item.tag!.value, style: style),
        builder.highlightedSpan(item.tag!.delimiter, style: style),
      ]);
    }
    if (item.body != null) {
      final reflow = OrgSettings.of(context).settings.reflowText;
      yield builder.build(item.body!, transformer: (elem, content) {
        final location = locationOf(elem, item.body!.children);
        var formattedContent = hardDeindent(content, totalIndentSize);
        if (reflow) {
          formattedContent = reflowText(formattedContent, location);
        }
        if (location == TokenLocation.end || location == TokenLocation.only) {
          final last = removeTrailingLineBreak(formattedContent);
          // A trailing linebreak results in a line with the same height as
          // the previous line. This is bad when the previous line is
          // artificially tall due to a WidgetSpan (especially an image). To
          // avoid this we add a zero-width space to the end if the text has
          // a single, trailing linebreak.
          //
          // See: https://github.com/flutter/flutter/issues/156268
          //
          // TODO(aaron): Limit to when the previous element is a link?
          return last.indexOf('\n') == last.length - 1 ? '$last\u200b' : last;
        } else {
          return formattedContent;
        }
      });
    }
  }
}
