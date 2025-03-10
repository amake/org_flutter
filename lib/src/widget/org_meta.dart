import 'package:flutter/material.dart';
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

const _kExportedKeywords = {
  ..._kDocInfoKeywords,
  '#+CAPTION:',
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
        OrgSettings.of(context).settings.deemphasizeMarkup;
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
        if (!_isExportedKeyword) {
          body = InheritedOrgSettings.merge(
            OrgSettings(strictSubSuperscripts: true),
            child: body,
          );
        }
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

  bool get _isExportedKeyword =>
      _kExportedKeywords.contains(widget.meta.key.toUpperCase());

  TextStyle? _keywordStyle(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    return _isDocInfoKeyword
        ? style.copyWith(color: OrgTheme.dataOf(context).codeColor)
        : style.copyWith(color: OrgTheme.dataOf(context).metaColor);
  }

  TextStyle? _valueStyle(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    return _isDocInfoKeyword
        ? style.copyWith(
            color: OrgTheme.dataOf(context).infoColor,
            fontWeight: widget.meta.key.toUpperCase() == '#+TITLE:'
                ? FontWeight.bold
                : null,
          )
        : style.copyWith(color: OrgTheme.dataOf(context).metaColor);
  }

  Iterable<InlineSpan> _spans(
      BuildContext context, OrgSpanBuilder builder) sync* {
    yield builder.highlightedSpan(widget.meta.key,
        style: _keywordStyle(context));
    if (widget.meta.value != null) {
      yield builder.build(widget.meta.value!, style: _valueStyle(context));
    }
    final trailing = removeTrailingLineBreak(widget.meta.trailing);
    if (trailing.isNotEmpty) {
      yield builder.highlightedSpan(trailing, style: _valueStyle(context));
    }
  }
}
