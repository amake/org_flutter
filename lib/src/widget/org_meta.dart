import 'package:flutter/material.dart';
import 'package:org_flutter/src/controller.dart';
import 'package:org_flutter/src/flash.dart';
import 'package:org_flutter/src/indent.dart';
import 'package:org_flutter/src/settings.dart';
import 'package:org_flutter/src/span.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_flutter/src/widget/org_theme.dart';
import 'package:org_parser/org_parser.dart';

typedef NameKey = GlobalKey<OrgMetaWidgetState>;

const _kDocInfoKeywords = {
  '#+TITLE:',
  '#+SUBTITLE:',
  '#+AUTHOR:',
  '#+EMAIL:',
  '#+DATE:'
};

/// An Org Mode meta line
class OrgMetaWidget extends StatefulWidget {
  const OrgMetaWidget(this.meta, {super.key});
  final OrgMeta meta;

  @override
  State<OrgMetaWidget> createState() => OrgMetaWidgetState();
}

class OrgMetaWidgetState extends State<OrgMetaWidget> {
  bool _cookie = true;

  void doHighlight() => setState(() => _cookie = !_cookie);

  @override
  Widget build(BuildContext context) {
    final deemphasize = !_isDocInfoKeyword &&
        OrgController.of(context).settings.deemphasizeMarkup;
    return IndentBuilder(
      widget.meta.indent,
      builder: (context, _) {
        Widget body = FancySpanBuilder(
          builder: (context, spanBuilder) => AnimatedTextFlash(
            cookie: _cookie,
            child: Text.rich(
              TextSpan(
                children: _spans(context, spanBuilder).toList(growable: false),
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
    );
  }

  bool get _isDocInfoKeyword =>
      _kDocInfoKeywords.contains(widget.meta.key.toUpperCase());

  TextStyle? _keywordStyle(BuildContext context) => _isDocInfoKeyword
      ? TextStyle(color: OrgTheme.dataOf(context).codeColor)
      : TextStyle(color: OrgTheme.dataOf(context).metaColor);

  TextStyle? _valueStyle(BuildContext context) => _isDocInfoKeyword
      ? TextStyle(
          color: OrgTheme.dataOf(context).infoColor,
          fontWeight: widget.meta.key.toUpperCase() == '#+TITLE:'
              ? FontWeight.bold
              : null,
        )
      : TextStyle(color: OrgTheme.dataOf(context).metaColor);

  Iterable<InlineSpan> _spans(
      BuildContext context, OrgSpanBuilder builder) sync* {
    yield builder.highlightedSpan(widget.meta.key,
        style: _keywordStyle(context));
    if (widget.meta.value != null) {
      yield builder.build(widget.meta.value!);
    }
    final trailing = removeTrailingLineBreak(widget.meta.trailing);
    if (trailing.isNotEmpty) {
      yield builder.highlightedSpan(trailing, style: _valueStyle(context));
    }
  }
}
