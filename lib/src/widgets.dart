import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:org_flutter/src/controller.dart';
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
    this.onSectionLongPress,
    Key key,
  }) : super(key: key);

  final Widget child;
  final TextStyle style;
  final OrgThemeData lightTheme;
  final OrgThemeData darkTheme;
  final Function(String) onLinkTap;
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
    this.onSectionLongPress,
    Key key,
  }) : super(key: key, child: child);

  final Function(String) onLinkTap;
  final Function(OrgSection) onSectionLongPress;

  static OrgEvents of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OrgEvents>();

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

  bool _fullyOpen(OrgVisibilityState visibility) {
    switch (visibility) {
      case OrgVisibilityState.folded:
        return section.isEmpty;
      case OrgVisibilityState.contents:
        return section.content == null;
      case OrgVisibilityState.children:
        return section.children.isEmpty;
      case OrgVisibilityState.subtree:
        return true;
    }
    throw Exception('Unknown visibility: $visibility');
  }

  @override
  Widget build(BuildContext context) {
    final visibilityListenable =
        OrgController.of(context).nodeFor(section).visibility;
    return ValueListenableBuilder<OrgVisibilityState>(
      valueListenable: visibilityListenable,
      builder: (context, visibility, child) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            child: OrgHeadlineWidget(
              section.headline,
              open: _fullyOpen(visibility),
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

class OrgContentWidget extends StatefulWidget {
  const OrgContentWidget(this.content, {Key key}) : super(key: key);
  final OrgContentElement content;

  @override
  _OrgContentWidgetState createState() => _OrgContentWidgetState();
}

class _OrgContentWidgetState extends State<OrgContentWidget> {
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
    return Text.rich(_contentToSpanTree(
      context,
      widget.content,
      OrgEvents.of(context)?.onLinkTap ?? (_) {},
      _recognizers.add,
    ));
  }
}

InlineSpan _contentToSpanTree(
  BuildContext context,
  OrgContentElement content,
  Function(String) linkHandler,
  Function(GestureRecognizer) registerRecognizer,
) {
  assert(linkHandler != null);
  assert(registerRecognizer != null);
  if (content is OrgPlainText) {
    return TextSpan(text: content.content);
  } else if (content is OrgMarkup) {
    return TextSpan(
      text: content.content,
      style: OrgTheme.dataOf(context).fontStyleForOrgStyle(
        DefaultTextStyle.of(context).style,
        content.style,
      ),
    );
  } else if (content is OrgLink) {
    final recognizer = TapGestureRecognizer()
      ..onTap = () => linkHandler(content.location);
    registerRecognizer(recognizer);
    final visibleContent = content.description ?? content.location;
    return TextSpan(
      recognizer: recognizer,
      text: characterWrappable(visibleContent),
      style: DefaultTextStyle.of(context).style.copyWith(
            color: OrgTheme.dataOf(context).linkColor,
            decoration: TextDecoration.underline,
          ),
    );
  } else if (content is OrgMeta) {
    return TextSpan(
        text: content.content,
        style: DefaultTextStyle.of(context)
            .style
            .copyWith(color: OrgTheme.dataOf(context).metaColor));
  } else if (content is OrgTimestamp) {
    return TextSpan(
      text: content.content,
      style: DefaultTextStyle.of(context).style.copyWith(
            color: OrgTheme.dataOf(context).dateColor,
            decoration: TextDecoration.underline,
          ),
    );
  } else if (content is OrgBlock) {
    return WidgetSpan(child: IdentityTextScale(child: OrgBlockWidget(content)));
  } else if (content is OrgTable) {
    return WidgetSpan(child: IdentityTextScale(child: OrgTableWidget(content)));
  } else if (content is OrgContent) {
    return TextSpan(
        children: content.children
            .map((child) => _contentToSpanTree(
                context, child, linkHandler, registerRecognizer))
            .toList());
  } else {
    throw Exception('Unknown OrgContentElement type: $content');
  }
}

class OrgHeadlineWidget extends StatefulWidget {
  const OrgHeadlineWidget(this.headline, {@required this.open, Key key})
      : assert(open != null),
        super(key: key);
  final OrgHeadline headline;
  final bool open;

  @override
  _OrgHeadlineWidgetState createState() => _OrgHeadlineWidgetState();
}

class _OrgHeadlineWidgetState extends State<OrgHeadlineWidget> {
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
    final theme = OrgTheme.dataOf(context);
    final color = theme.levelColor(widget.headline.level);
    return DefaultTextStyle.merge(
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        height: 1.8,
      ),
      child: Builder(
        // Builder here to make modified default text style accessible
        builder: (context) => Text.rich(
          TextSpan(
            text: '${widget.headline.stars} ',
            children: [
              if (widget.headline.keyword != null)
                TextSpan(
                    text: '${widget.headline.keyword} ',
                    style: DefaultTextStyle.of(context).style.copyWith(
                        color: widget.headline.keyword == 'DONE'
                            ? theme.doneColor
                            : theme.todoColor)),
              if (widget.headline.priority != null)
                TextSpan(text: '${widget.headline.priority} '),
              if (widget.headline.title != null)
                _contentToSpanTree(
                  context,
                  widget.headline.title,
                  OrgEvents.of(context)?.onLinkTap ?? (_) {},
                  _recognizers.add,
                ),
              if (widget.headline.tags.isNotEmpty)
                TextSpan(text: ':${widget.headline.tags.join(':')}:'),
              if (!widget.open) const TextSpan(text: '...'),
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
    return ValueListenableBuilder<bool>(
      valueListenable: openListenable,
      builder: (context, open, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            InkWell(
              child: Text(
                block.header + (open ? '' : '...'),
                style: metaStyle,
              ),
              onTap: () => openListenable.value = !openListenable.value,
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 100),
              transitionBuilder: (child, animation) =>
                  SizeTransition(child: child, sizeFactor: animation),
              child: open
                  ? Column(
                      key: ValueKey(open),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        SingleChildScrollView(
                          child: OrgContentWidget(block.body),
                          scrollDirection: Axis.horizontal,
                          physics: const AlwaysScrollableScrollPhysics(),
                        ),
                        Text(block.footer, style: metaStyle),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
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
