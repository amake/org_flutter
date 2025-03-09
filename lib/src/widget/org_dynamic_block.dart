import 'dart:math';

import 'package:flutter/material.dart';
import 'package:org_flutter/src/indent.dart';
import 'package:org_flutter/src/settings.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_flutter/src/widget/org_content.dart';
import 'package:org_flutter/src/widget/org_theme.dart';
import 'package:org_parser/org_parser.dart';

/// An Org Mode dynamic block
class OrgDynamicBlockWidget extends StatefulWidget {
  const OrgDynamicBlockWidget(this.block, {super.key});
  final OrgDynamicBlock block;

  @override
  State<OrgDynamicBlockWidget> createState() => _OrgDynamicBlockWidgetState();
}

class _OrgDynamicBlockWidgetState extends State<OrgDynamicBlockWidget>
    with OpenCloseable<OrgDynamicBlockWidget> {
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
    // This feels a bit costly, but it's the easiest way to handle scenarios
    // where the body is indented *less* than the block delimiters.
    indentSize = min(indentSize, detectIndent(block.body.toMarkup()));
    return OrgContentWidget(
      block.body,
      transformer: (elem, content) {
        final location = locationOf(elem, block.body.children);
        var formattedContent = hardDeindent(content, indentSize);
        if (location == TokenLocation.end || location == TokenLocation.only) {
          formattedContent = removeTrailingLineBreak(formattedContent);
        }
        return formattedContent;
      },
    );
  }
}
