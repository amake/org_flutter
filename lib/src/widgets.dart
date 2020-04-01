import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:org_flutter/src/controller.dart';
import 'package:org_flutter/src/span.dart';
import 'package:org_flutter/src/theme.dart';
import 'package:org_flutter/src/util.dart';
import 'package:org_parser/org_parser.dart';

class OrgDocumentWidget extends StatelessWidget {
  const OrgDocumentWidget(
    this.document, {
    Key key,
  }) : super(key: key);

  final OrgDocument document;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (document.content != null) OrgContentWidget(document.content),
        ...document.children.map((section) => OrgSectionWidget(section)),
      ],
    );
  }
}

class OrgRootWidget extends StatelessWidget {
  const OrgRootWidget({
    this.child,
    this.style,
    this.lightTheme,
    this.darkTheme,
    this.onLinkTap,
    this.onLocalSectionLinkTap,
    this.onSectionLongPress,
    Key key,
  }) : super(key: key);

  final Widget child;
  final TextStyle style;
  final OrgThemeData lightTheme;
  final OrgThemeData darkTheme;
  final Function(String) onLinkTap;
  final Function(OrgSection) onLocalSectionLinkTap;
  final Function(OrgSection) onSectionLongPress;

  @override
  Widget build(BuildContext context) {
    final body = OrgTheme(
      light: lightTheme ?? OrgThemeData.light(),
      dark: darkTheme ?? OrgThemeData.dark(),
      child: OrgEvents(
        child: child,
        onLinkTap: onLinkTap,
        onSectionLongPress: onSectionLongPress,
        onLocalSectionLinkTap: onLocalSectionLinkTap,
      ),
    );
    return style == null
        ? body
        : DefaultTextStyle.merge(
            style: style,
            child: body,
          );
  }
}

class OrgTheme extends InheritedWidget {
  const OrgTheme({
    @required Widget child,
    this.light,
    this.dark,
    Key key,
  }) : super(key: key, child: child);

  static OrgTheme of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OrgTheme>();

  static OrgThemeData dataOf(BuildContext context) {
    final theme = of(context);
    final brightness = MediaQuery.of(context).platformBrightness;
    switch (brightness) {
      case Brightness.dark:
        return theme.dark;
      case Brightness.light:
        return theme.light;
    }
    throw Exception('Unknown platform brightness: $brightness');
  }

  final OrgThemeData light;
  final OrgThemeData dark;

  @override
  bool updateShouldNotify(OrgTheme oldWidget) =>
      light != oldWidget.light || dark != oldWidget.dark;
}

class OrgEvents extends InheritedWidget {
  const OrgEvents({
    @required Widget child,
    this.onLinkTap,
    this.onLocalSectionLinkTap,
    this.onSectionLongPress,
    Key key,
  }) : super(key: key, child: child);

  final Function(String) onLinkTap;
  final Function(OrgSection) onLocalSectionLinkTap;
  final Function(OrgSection) onSectionLongPress;

  static OrgEvents of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OrgEvents>();

  void dispatchLinkTap(BuildContext context, String url) {
    if (!_handleLocalSectionLink(context, url)) {
      onLinkTap(url);
    }
  }

  bool _handleLocalSectionLink(BuildContext context, String url) {
    if (isOrgLocalSectionUrl(url)) {
      final sectionTitle = parseOrgLocalSectionUrl(url);
      final section = OrgController.of(context).sectionWithTitle(sectionTitle);
      if (section == null) {
        debugPrint('Failed to find local section with title "$sectionTitle"');
      } else {
        onLocalSectionLinkTap(section);
      }
      return true;
    }
    return false;
  }

  @override
  bool updateShouldNotify(OrgEvents oldWidget) =>
      onLinkTap != oldWidget.onLinkTap ||
      onSectionLongPress != oldWidget.onSectionLongPress;
}

class OrgSectionWidget extends StatelessWidget {
  const OrgSectionWidget(this.section, {this.initiallyOpen, Key key})
      : super(key: key);
  final OrgSection section;
  final bool initiallyOpen;

  // Whether the section is open "enough" to not show the trailing ellipsis
  bool _openEnough(OrgVisibilityState visibility) {
    switch (visibility) {
      case OrgVisibilityState.folded:
        return section.isEmpty;
      case OrgVisibilityState.contents:
        return section.content == null;
      case OrgVisibilityState.children:
      case OrgVisibilityState.subtree:
        return true;
    }
    throw Exception('Unknown visibility: $visibility');
  }

  @override
  Widget build(BuildContext context) {
    final visibilityListenable =
        OrgController.of(context).nodeFor(section)?.visibility;
    if (visibilityListenable == null) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<OrgVisibilityState>(
      valueListenable: visibilityListenable,
      builder: (context, visibility, child) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            child: OrgHeadlineWidget(
              section.headline,
              open: _openEnough(visibility),
            ),
            onTap: () => OrgController.of(context).cycleVisibilityOf(section),
            onLongPress: () =>
                OrgEvents.of(context)?.onSectionLongPress(section),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 100),
            transitionBuilder: (child, animation) =>
                SizeTransition(child: child, sizeFactor: animation),
            child: Column(
              key: ValueKey(visibility),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (section.content != null &&
                    (visibility == OrgVisibilityState.children ||
                        visibility == OrgVisibilityState.subtree))
                  OrgContentWidget(section.content),
                if (visibility != OrgVisibilityState.folded)
                  ...section.children.map((child) => OrgSectionWidget(child)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrgContentWidget extends StatelessWidget {
  const OrgContentWidget(
    this.content, {
    this.transformer,
    Key key,
  }) : super(key: key);
  final OrgContentElement content;
  final Transformer transformer;

  @override
  Widget build(BuildContext context) {
    return HighlightBuilder(
      builder: (context, spanBuilder) => Text.rich(
        spanBuilder.build(
          content,
          transformer: transformer ?? identityTransformer,
        ),
      ),
    );
  }
}

class OrgHeadlineWidget extends StatelessWidget {
  const OrgHeadlineWidget(this.headline, {@required this.open, Key key})
      : assert(open != null),
        super(key: key);
  final OrgHeadline headline;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final theme = OrgTheme.dataOf(context);
    final color = theme.levelColor(headline.level);
    return DefaultTextStyle.merge(
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        height: 1.8,
      ),
      child: HighlightBuilder(
        builder: (context, spanBuilder) => Text.rich(
          TextSpan(
            children: [
              spanBuilder.highlightedSpan('${headline.stars} '),
              if (headline.keyword != null)
                spanBuilder.highlightedSpan('${headline.keyword} ',
                    style: DefaultTextStyle.of(context).style.copyWith(
                        color: headline.keyword == 'DONE'
                            ? theme.doneColor
                            : theme.todoColor)),
              if (headline.priority != null)
                spanBuilder.highlightedSpan('${headline.priority} '),
              if (headline.title != null)
                spanBuilder.build(
                  headline.title,
                ),
              if (headline.tags.isNotEmpty)
                spanBuilder.highlightedSpan(':${headline.tags.join(':')}:'),
              if (!open) const TextSpan(text: '...'),
            ],
          ),
        ),
      ),
    );
  }
}

class IdentityTextScale extends StatelessWidget {
  const IdentityTextScale({@required this.child, Key key})
      : assert(child != null),
        super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1),
      child: child,
    );
  }
}

class OrgBlockWidget extends StatelessWidget {
  const OrgBlockWidget(this.block, {Key key})
      : assert(block != null),
        super(key: key);
  final OrgBlock block;

  @override
  Widget build(BuildContext context) {
    final openListenable = ValueNotifier<bool>(true);
    final defaultStyle = DefaultTextStyle.of(context).style;
    final metaStyle =
        defaultStyle.copyWith(color: OrgTheme.dataOf(context).metaColor);
    return IndentBuilder(
      block.indent,
      builder: (context, indent, totalIndentSize) {
        final deindentPattern = RegExp(
          '^ {0,$totalIndentSize}',
          multiLine: true,
        );
        return Row(
          children: <Widget>[
            Text(indent),
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: openListenable,
                builder: (context, open, child) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    InkWell(
                      child: Text(
                        block.header.trimRight() + (open ? '' : '...'),
                        style: metaStyle,
                      ),
                      onTap: () => openListenable.value = !openListenable.value,
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 100),
                      transitionBuilder: (child, animation) =>
                          SizeTransition(child: child, sizeFactor: animation),
                      child: open ? child : const SizedBox.shrink(),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SingleChildScrollView(
                      child: OrgContentWidget(
                        block.body,
                        transformer: (_, string) {
                          return removeTrailingLineBreak(
                              string.replaceAll(deindentPattern, ''));
                        },
                      ),
                      scrollDirection: Axis.horizontal,
                      physics: const AlwaysScrollableScrollPhysics(),
                    ),
                    Text(
                      block.footer.replaceAll(deindentPattern, ''),
                      style: metaStyle,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class OrgMetaWidget extends StatelessWidget {
  const OrgMetaWidget(this.meta, {Key key})
      : assert(meta != null),
        super(key: key);
  final OrgMeta meta;

  @override
  Widget build(BuildContext context) {
    return IndentBuilder(
      meta.indent,
      builder: (context, indent, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(indent),
            HighlightBuilder(
              builder: (context, spanBuilder) => Text.rich(
                TextSpan(
                  children:
                      _spans(context, spanBuilder).toList(growable: false),
                ),
                style: DefaultTextStyle.of(context)
                    .style
                    .copyWith(color: OrgTheme.dataOf(context).metaColor),
              ),
            ),
          ],
        );
      },
    );
  }

  Iterable<InlineSpan> _spans(BuildContext context, SpanBuilder builder) sync* {
    yield builder.highlightedSpan(meta.keyword);
    final trailing = removeTrailingLineBreak(meta.trailing);
    if (trailing.isNotEmpty) {
      yield builder.highlightedSpan(trailing);
    }
  }
}

class OrgTableWidget extends StatelessWidget {
  const OrgTableWidget(this.table, {Key key})
      : assert(table != null),
        super(key: key);
  final OrgTable table;

  @override
  Widget build(BuildContext context) {
    final tableColor = OrgTheme.dataOf(context).tableColor;
    final borderSide = BorderSide(color: tableColor);
    return DefaultTextStyle.merge(
      style: TextStyle(color: tableColor),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Row(
          children: <Widget>[
            Text(table.indent),
            Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              border: TableBorder(
                verticalInside: borderSide,
                left: borderSide,
                right: table.rectangular ? borderSide : BorderSide.none,
              ),
              children: _tableRows(borderSide).toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }

  Iterable<TableRow> _tableRows(BorderSide borderSide) sync* {
    for (var i = 0; i < table.rows.length; i++) {
      final row = table.rows[i];
      final nextRow = i + 1 < table.rows.length ? table.rows[i + 1] : null;
      if (row is OrgTableCellRow) {
        // Peek at next row, add bottom border if it's a divider
        final decoration = nextRow is OrgTableDividerRow
            ? BoxDecoration(border: Border(bottom: borderSide))
            : null;
        yield TableRow(
          decoration: decoration,
          children: [
            for (var j = 0; j < table.columnCount; j++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: j < row.cellCount
                    ? OrgContentWidget(row.cells[j])
                    : const SizedBox.shrink(),
              ),
          ],
        );
      }
    }
  }
}

class OrgFixedWidthAreaWidget extends StatelessWidget {
  const OrgFixedWidthAreaWidget(this.fixedWidthArea, {Key key})
      : assert(fixedWidthArea != null),
        super(key: key);
  final OrgFixedWidthArea fixedWidthArea;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: TextStyle(color: OrgTheme.dataOf(context).codeColor),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Text(fixedWidthArea.content),
      ),
    );
  }
}

class HighlightBuilder extends StatelessWidget {
  const HighlightBuilder({@required this.builder, Key key})
      : assert(builder != null),
        super(key: key);
  final Widget Function(BuildContext, SpanBuilder) builder;

  @override
  Widget build(BuildContext context) {
    return RecognizerManager(
      builder: (context, registerRecognizer) {
        final queryListenable = OrgController.of(context)?.searchQuery;
        if (queryListenable == null) {
          return builder(
            context,
            SpanBuilder(context, recognizerHandler: registerRecognizer),
          );
        } else {
          return ValueListenableBuilder<Pattern>(
            valueListenable: queryListenable,
            builder: (context, query, child) => builder(
              context,
              SpanBuilder(
                context,
                recognizerHandler: registerRecognizer,
                highlight: query,
              ),
            ),
          );
        }
      },
    );
  }
}

class RecognizerManager extends StatefulWidget {
  const RecognizerManager({this.builder, Key key}) : super(key: key);

  final Widget Function(BuildContext, RecognizerHandler) builder;

  @override
  _RecognizerManagerState createState() => _RecognizerManagerState();
}

class _RecognizerManagerState extends State<RecognizerManager> {
  final _recognizers = <GestureRecognizer>[];

  @override
  void dispose() {
    for (final item in _recognizers) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _recognizers.add);
  }
}

class OrgListWidget extends StatelessWidget {
  const OrgListWidget(this.list, {Key key})
      : assert(list != null),
        super(key: key);
  final OrgList list;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start, // CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final item in list.items) OrgListItemWidget(item),
      ],
    );
  }
}

class OrgListItemWidget extends StatelessWidget {
  const OrgListItemWidget(this.item, {Key key})
      : assert(item != null),
        super(key: key);
  final OrgListItem item;

  @override
  Widget build(BuildContext context) {
    return IndentBuilder(
      '${item.indent}${item.bullet}',
      builder: (context, indent, _) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(indent),
          Expanded(
            child: HighlightBuilder(
              builder: (context, spanBuilder) => Text.rich(
                TextSpan(
                  children:
                      _spans(context, spanBuilder).toList(growable: false),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Iterable<InlineSpan> _spans(
    BuildContext context,
    SpanBuilder builder,
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
      yield builder.highlightedSpan(
        item.tag,
        style: DefaultTextStyle.of(context)
            .style
            .copyWith(fontWeight: FontWeight.bold),
      );
    }
    if (item.body != null) {
      yield builder.build(item.body, transformer: (elem, content) {
        if (elem is OrgPlainText) {
          return removeTrailingLineBreak(reflowText(content));
        } else {
          return content;
        }
      });
    }
  }
}

class ListContext extends InheritedWidget {
  const ListContext(this.indentSize, {Widget child, Key key})
      : super(child: child, key: key);

  final int indentSize;

  @override
  bool updateShouldNotify(ListContext oldWidget) =>
      indentSize != oldWidget.indentSize;

  static ListContext of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ListContext>();
}

// TODO(aaron): Use indent builder to fix indent of blocks, tables, etc. inside lists
class IndentBuilder extends StatelessWidget {
  const IndentBuilder(this.indent, {this.builder, Key key}) : super(key: key);

  final Widget Function(BuildContext, String, int) builder;
  final String indent;

  @override
  Widget build(BuildContext context) {
    final parentIndent = ListContext.of(context)?.indentSize ?? 0;
    final newIndent = indent.substring(parentIndent);
    final totalIndentSize = parentIndent + newIndent.length;
    return ListContext(
      parentIndent + newIndent.length,
      child: builder(context, newIndent, totalIndentSize),
    );
  }
}
