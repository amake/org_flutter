import 'package:flutter/material.dart';
import 'package:org_flutter/src/controller.dart';
import 'package:org_flutter/src/indent.dart';
import 'package:org_flutter/src/settings.dart';
import 'package:org_flutter/src/span.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_flutter/src/widget/org_theme.dart';
import 'package:org_parser/org_parser.dart';

/// An Org Mode meta line
class OrgMetaWidget extends StatelessWidget {
  const OrgMetaWidget(this.meta, {super.key});
  final OrgMeta meta;

  @override
  Widget build(BuildContext context) {
    final hideMarkup = OrgController.of(context).settings.deemphasizeMarkup;
    final body = DefaultTextStyle.merge(
      style: TextStyle(color: OrgTheme.dataOf(context).metaColor),
      child: IndentBuilder(
        meta.indent,
        builder: (context, _) {
          return FancySpanBuilder(
            builder: (context, spanBuilder) => Text.rich(
              TextSpan(
                children: _spans(context, spanBuilder).toList(growable: false),
              ),
              softWrap: !hideMarkup,
              overflow: hideMarkup ? TextOverflow.fade : null,
            ),
          );
        },
      ),
    );
    return reduceOpacity(body, enabled: hideMarkup);
  }

  Iterable<InlineSpan> _spans(
      BuildContext context, OrgSpanBuilder builder) sync* {
    yield builder.highlightedSpan(meta.keyword);
    final trailing = removeTrailingLineBreak(meta.trailing);
    if (trailing.isNotEmpty) {
      yield builder.highlightedSpan(trailing);
    }
  }
}
