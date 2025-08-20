import 'dart:math';

import 'package:flutter/material.dart';
import 'package:org_flutter/src/controller.dart';
import 'package:org_flutter/src/highlight.dart';
import 'package:org_flutter/src/indent.dart';
import 'package:org_flutter/src/settings.dart';
import 'package:org_flutter/src/span.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_flutter/src/widget/org_content.dart';
import 'package:org_flutter/src/widget/org_theme.dart';
import 'package:org_parser/org_parser.dart';

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
      final searchQuery = OrgController.of(context).searchQuery;
      final isSearchHit = searchQuery != null &&
          searchQuery.isNotEmpty &&
          codeNode.contains(searchQuery);
      if (isSearchHit || !supportedSrcLanguage(block.language)) {
        final defaultStyle = DefaultTextStyle.of(context).style;
        body = FancySpanBuilder(
          builder: (context, spanBuilder) => Text.rich(
              spanBuilder.highlightedSpan(code,
                  style: defaultStyle.copyWith(
                      color: OrgTheme.dataOf(context).codeColor))),
        );
      } else {
        body = buildSrcHighlight(
          context,
          code: code,
          languageId: block.language,
        );
      }
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
