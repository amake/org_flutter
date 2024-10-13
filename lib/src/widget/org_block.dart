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
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    openListenable.value = !OrgController.of(context).settings.hideBlockStartup;
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final metaStyle =
        defaultStyle.copyWith(color: OrgTheme.dataOf(context).metaColor);
    final hideMarkup = OrgController.of(context).settings.deemphasizeMarkup;
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
              // Remove two linebreaks because we introduce two by splitting the
              // text into two widgets in this Column
              Text(
                removeTrailingLineBreak(
                  removeTrailingLineBreak(widget.block.trailing),
                ),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _body(
                context,
                (_, string) =>
                    removeTrailingLineBreak(deindent(string, totalIndentSize)),
              ),
              reduceOpacity(
                Text(
                  deindent(widget.block.footer, totalIndentSize),
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

  Widget _body(BuildContext context, Transformer transformer) {
    final block = widget.block;
    Widget body;
    if (block is OrgSrcBlock) {
      final code = widget.block.body as OrgPlainText;
      if (supportedSrcLanguage(block.language)) {
        body = buildSrcHighlight(
          context,
          code: transformer(code, code.content),
          languageId: block.language,
        );
      } else {
        body = OrgContentWidget(
          OrgMarkup.just(code.content, OrgStyle.code),
          transformer: transformer,
        );
      }
    } else {
      body = OrgContentWidget(
        block.body,
        transformer: transformer,
      );
    }
    // TODO(aaron): Better distinguish "greater block" from regular block
    return block.body is OrgContent
        ? body
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: body,
          );
  }
}
