import 'dart:math';

import 'package:flutter/material.dart';
import 'package:org_flutter/src/flash.dart';
import 'package:org_flutter/src/highlight.dart';
import 'package:org_flutter/src/indent.dart';
import 'package:org_flutter/src/locator.dart';
import 'package:org_flutter/src/settings.dart';
import 'package:org_flutter/src/span.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_flutter/src/widgets.dart';
import 'package:org_parser/org_parser.dart';

typedef CoderefKey = GlobalKey<OrgCoderefWidgetState>;

/// An Org Mode block
class OrgBlockWidget extends StatefulWidget {
  const OrgBlockWidget(this.block, {super.key});
  final OrgBlock block;

  @override
  State<OrgBlockWidget> createState() => _OrgBlockWidgetState();
}

class _OrgBlockWidgetState extends State<OrgBlockWidget>
    with OpenCloseable<OrgBlockWidget> {
  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inited) {
      openListenable.value = !OrgSettings.of(context).settings.hideBlockStartup;
      _inited = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final metaStyle =
        defaultStyle.copyWith(color: OrgTheme.dataOf(context).metaColor);
    final hideMarkup = OrgSettings.of(context).settings.deemphasizeMarkup;
    // Remove a line break because we introduce one by splitting the text into
    // two widgets in this Column
    final trailing = removeTrailingLineBreak(widget.block.trailing);
    return IndentBuilder(
      widget.block.indent,
      builder: (context, totalIndentSize) {
        return ValueListenableBuilder<bool>(
          valueListenable: openListenable,
          builder: (context, open, child) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _header(context, metaStyle, open: open, hideMarkup: hideMarkup),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 100),
                transitionBuilder: (child, animation) =>
                    SizeTransition(sizeFactor: animation, child: child),
                child: open ? child : const SizedBox.shrink(),
              ),
              if (trailing.isNotEmpty)
                // Remove another line break because the existence of even an
                // empty string here takes up a line.
                Text(removeTrailingLineBreak(trailing)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _body(context, totalIndentSize),
              reduceOpacity(
                Text(
                  hardDeindent(widget.block.footer, totalIndentSize),
                  style: metaStyle,
                ),
                enabled: hideMarkup,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header(
    BuildContext context,
    TextStyle metaStyle, {
    required bool hideMarkup,
    required bool open,
  }) {
    var text = widget.block.header.trimRight();
    if (!hideMarkup && !open) {
      text += '...';
    }
    Widget header = Text(
      text,
      style: metaStyle,
      softWrap: !hideMarkup,
      overflow: hideMarkup ? TextOverflow.fade : null,
    );
    if (hideMarkup && !open) {
      header = Row(
        children: [
          Flexible(
            child: header,
          ),
          if (hideMarkup && !open) Text('...', style: metaStyle)
        ],
      );
    }
    header = reduceOpacity(header, enabled: hideMarkup);
    return InkWell(
      onTap: () => openListenable.value = !openListenable.value,
      child: header,
    );
  }

  Widget _body(BuildContext context, int indentSize) {
    final block = widget.block;
    Widget body;
    if (block is OrgSrcBlock) {
      final codeNode = block.body as OrgPlainText;
      final code =
          removeTrailingLineBreak(softDeindent(codeNode.content, indentSize));
      final refPattern = block.coderefPattern();
      final defaultStyle = DefaultTextStyle.of(context).style;
      body = FancySpanBuilder(
        builder: (context, spanBuilder) {
          InlineSpan span;
          if (!supportedSrcLanguage(block.language)) {
            final codeStyle = defaultStyle.copyWith(
              color: OrgTheme.dataOf(context).codeColor,
            );
            span = TextSpan(
              children: _tokenizeText(code, refPattern).map((t) {
                return t.coderef == null
                    ? spanBuilder.highlightedSpan(t.text, style: codeStyle)
                    : WidgetSpan(
                        child: OrgCoderefWidget(
                          t.text,
                          spanBuilder,
                          style: codeStyle,
                          key: OrgLocator.of(context)
                              ?.generateCoderefKey(t.coderef!),
                        ),
                      );
              }).toList(growable: false),
            );
          } else {
            span = buildSrcHighlightSpan(
              context,
              code: code,
              languageId: block.language,
              spanFactory: ({String? text, TextStyle? style}) {
                if (text == null) return const TextSpan();

                final refMatch = refPattern.firstMatch(text);
                if (refMatch == null) {
                  return spanBuilder.highlightedSpan(text, style: style);
                }
                final refKey = refMatch.namedGroup('name')!;
                return WidgetSpan(
                  child: OrgCoderefWidget(
                    text,
                    spanBuilder,
                    style: style,
                    key: OrgLocator.of(context)?.generateCoderefKey(refKey),
                  ),
                );
              },
            );
          }
          return Text.rich(span);
        },
      );
    } else if (block.body is OrgPlainText) {
      final contentNode = block.body as OrgPlainText;
      final content = removeTrailingLineBreak(
          softDeindent(contentNode.content, indentSize));
      body = FancySpanBuilder(
        builder: (context, spanBuilder) =>
            Text.rich(spanBuilder.highlightedSpan(content)),
      );
    } else {
      // This feels a bit costly, but it's the easiest way to handle scenarios
      // where the body is indented *less* than the block delimiters.
      indentSize = min(indentSize, detectIndent(block.body.toMarkup()));
      body = OrgContentWidget(
        block.body,
        transformer: (elem, content) {
          final location = locationOf(elem, block.body.children!);
          var formattedContent = hardDeindent(content, indentSize);
          if (location == TokenLocation.end || location == TokenLocation.only) {
            formattedContent = removeTrailingLineBreak(formattedContent);
          }
          return formattedContent;
        },
      );
    }
    if (block.type == 'example' || block.type == 'export') {
      body = DefaultTextStyle(
        style: DefaultTextStyle.of(context).style.copyWith(
              color: OrgTheme.dataOf(context).codeColor,
            ),
        child: body,
      );
    } else if (block.type == 'verse') {
      body = InheritedOrgSettings.merge(
        OrgSettings(reflowText: false),
        child: body,
      );
    }
    return block.body is OrgContent
        ? body
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: body,
          );
  }
}

Iterable<({String text, String? coderef})> _tokenizeText(
  String text,
  RegExp pattern,
) sync* {
  var lastEnd = 0;
  for (final match in pattern.allMatches(text)) {
    if (match.start > lastEnd) {
      yield (text: text.substring(lastEnd, match.start), coderef: null);
    }
    yield (text: match.group(0)!, coderef: match.namedGroup('name'));
    lastEnd = match.end;
  }
  if (lastEnd < text.length) {
    yield (text: text.substring(lastEnd), coderef: null);
  }
}

class OrgCoderefWidget extends StatefulWidget {
  const OrgCoderefWidget(this.text, this.spanBuilder, {this.style, super.key});

  final String text;
  final OrgSpanBuilder spanBuilder;
  final TextStyle? style;

  @override
  State<OrgCoderefWidget> createState() => OrgCoderefWidgetState();
}

class OrgCoderefWidgetState extends State<OrgCoderefWidget> {
  bool _cookie = true;

  void doHighlight() => setState(() => _cookie = !_cookie);

  @override
  Widget build(BuildContext context) {
    return AnimatedTextFlash(
      cookie: _cookie,
      child: Text.rich(
        widget.spanBuilder.highlightedSpan(widget.text, style: widget.style),
      ),
    );
  }
}
