import 'package:flutter/material.dart';
import 'package:flutter_tex_js/flutter_tex_js.dart';
import 'package:org_flutter/src/controller.dart';
import 'package:org_flutter/src/highlight.dart';
import 'package:org_flutter/src/indent.dart';
import 'package:org_flutter/src/span.dart';
import 'package:org_flutter/src/theme.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_parser/org_parser.dart';

/// The root of the actual Org Mode document itself. Assumes that
/// [OrgRootWidget] and [OrgController] are available in the build context. See
/// the Org widget for a more user-friendly entrypoint.
class OrgDocumentWidget extends StatelessWidget {
  const OrgDocumentWidget(
    this.document, {
    this.shrinkWrap = false,
    this.safeArea = true,
    super.key,
  });

  final OrgDocument document;
  final bool shrinkWrap;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    return ListView(
      restorationId: shrinkWrap
          ? null
          : OrgController.of(context)
              .restorationIdFor('org_document_list_view'),
      padding: OrgTheme.dataOf(context).rootPadding,
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      children: <Widget>[
        if (document.content != null) OrgContentWidget(document.content!),
        ...document.sections.map((section) => OrgSectionWidget(section)),
        if (safeArea) listBottomSafeArea(),
      ],
    );
  }
}

/// A widget that sits above the [OrgDocumentWidget] and orchestrates [OrgTheme]
/// and [OrgEvents].
class OrgRootWidget extends StatelessWidget {
  const OrgRootWidget({
    required this.child,
    this.style,
    this.lightTheme,
    this.darkTheme,
    this.onLinkTap,
    this.onLocalSectionLinkTap,
    this.onSectionLongPress,
    this.onListItemTap,
    this.loadImage,
    super.key,
  });

  final Widget child;

  /// Text style to serve as a basis for all text in the document
  final TextStyle? style;

  final OrgThemeData? lightTheme;
  final OrgThemeData? darkTheme;

  /// A callback invoked when the user taps a link. The argument is the link
  /// URL. You might want to open this in a browser.
  final Function(String)? onLinkTap;

  /// A callback invoked when the user taps on a link to a section within the
  /// current document. The argument is the target section. You might want to
  /// display it somehow.
  final Function(OrgSection)? onLocalSectionLinkTap;

  /// A callback invoked when the user long-presses on a section headline within
  /// the current document. The argument is the pressed section. You might want
  /// to narrow the display to show just this section.
  final Function(OrgSection)? onSectionLongPress;

  /// A callback invoked when the user taps on a list item that has a checkbox
  /// within the current document. The argument is the tapped item. You might
  /// want to toggle the checkbox.
  final Function(OrgListItem)? onListItemTap;

  /// A callback invoked when an image should be displayed. The argument is the
  /// [OrgLink] describing where the image data can be found. It is your
  /// responsibility to resolve the link, fetch the data, and return a widget
  /// for displaying the image.
  ///
  /// Return null instead to display the link text.
  final Widget? Function(OrgLink)? loadImage;

  @override
  Widget build(BuildContext context) {
    final body = OrgTheme(
      light: lightTheme ?? OrgThemeData.light(),
      dark: darkTheme ?? OrgThemeData.dark(),
      child: OrgEvents(
        onLinkTap: onLinkTap,
        onSectionLongPress: onSectionLongPress,
        onLocalSectionLinkTap: onLocalSectionLinkTap,
        loadImage: loadImage,
        onListItemTap: onListItemTap,
        child: IdentityTextScale(child: child),
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

/// The theme for the Org Mode document
class OrgTheme extends InheritedWidget {
  const OrgTheme({
    required super.child,
    required this.light,
    required this.dark,
    super.key,
  });

  static OrgTheme of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OrgTheme>()!;

  /// Throws an exception if OrgTheme is not found in the context.
  static OrgThemeData dataOf(BuildContext context) {
    final theme = of(context);
    final brightness = Theme.of(context).brightness;
    switch (brightness) {
      case Brightness.dark:
        return theme.dark;
      case Brightness.light:
        return theme.light;
    }
  }

  final OrgThemeData light;
  final OrgThemeData dark;

  @override
  bool updateShouldNotify(OrgTheme oldWidget) =>
      light != oldWidget.light || dark != oldWidget.dark;
}

/// A widget for managing callbacks invoked upon user interaction or other
/// document-related events.
class OrgEvents extends InheritedWidget {
  const OrgEvents({
    required super.child,
    this.onLinkTap,
    this.onLocalSectionLinkTap,
    this.onSectionLongPress,
    this.onListItemTap,
    this.loadImage,
    super.key,
  });

  /// A callback invoked when the user taps a link. The argument is the link
  /// URL. You might want to open this in a browser.
  final Function(String)? onLinkTap;

  /// A callback invoked when the user taps on a link to a section within the
  /// current document. The argument is the target section. You might want to
  /// display it somehow.
  final Function(OrgSection)? onLocalSectionLinkTap;

  /// A callback invoked when the user long-presses on a section headline within
  /// the current document. The argument is the pressed section. You might want
  /// to narrow the display to show just this section.
  final Function(OrgSection)? onSectionLongPress;

  /// A callback invoked when the user taps on a list item that has a checkbox
  /// within the current document. The argument is the tapped item. You might
  /// want to toggle the checkbox.
  final Function(OrgListItem)? onListItemTap;

  /// A callback invoked when an image should be displayed. The argument is the
  /// [OrgLink] describing where the image data can be found. It is your
  /// responsibility to resolve the link, fetch the data, and return a widget
  /// for displaying the image.
  ///
  /// Return null instead to display the link text.
  final Widget? Function(OrgLink)? loadImage;

  static OrgEvents of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OrgEvents>()!;

  /// Invoke the appropriate handler for the given [url]
  void dispatchLinkTap(BuildContext context, String url) {
    final section = _resolveLocalSectionLink(context, url);
    if (section != null) {
      onLocalSectionLinkTap?.call(section);
    } else {
      onLinkTap?.call(url);
    }
  }

  OrgSection? _resolveLocalSectionLink(BuildContext context, String url) {
    if (isOrgLocalSectionUrl(url)) {
      final sectionTitle = parseOrgLocalSectionUrl(url);
      final section = OrgController.of(context).sectionWithTitle(sectionTitle);
      if (section == null) {
        debugPrint('Failed to find local section with title "$sectionTitle"');
      }
      return section;
    } else if (isOrgIdUrl(url)) {
      final sectionId = parseOrgIdUrl(url);
      final section = OrgController.of(context).sectionWithId(sectionId);
      if (section == null) {
        debugPrint('Failed to find local section with ID "$sectionId"');
      }
      return section;
    } else if (isOrgCustomIdUrl(url)) {
      final sectionId = parseOrgCustomIdUrl(url);
      final section = OrgController.of(context).sectionWithCustomId(sectionId);
      if (section == null) {
        debugPrint('Failed to find local section with CUSTOM_ID "$sectionId"');
      }
      return section;
    }
    try {
      final link = OrgFileLink.parse(url);
      if (link.isLocal) {
        return _resolveLocalSectionLink(context, link.extra!);
      }
    } on Exception {
      // Ignore
    }
    return null;
  }

  @override
  bool updateShouldNotify(OrgEvents oldWidget) =>
      onLinkTap != oldWidget.onLinkTap ||
      onSectionLongPress != oldWidget.onSectionLongPress;
}

/// An Org Mode section
class OrgSectionWidget extends StatelessWidget {
  const OrgSectionWidget(
    this.section, {
    this.root = false,
    this.shrinkWrap = false,
    super.key,
  });
  final OrgSection section;
  final bool root;
  final bool shrinkWrap;

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
  }

  @override
  Widget build(BuildContext context) {
    final visibilityListenable =
        OrgController.of(context).nodeFor(section)?.visibility;
    if (visibilityListenable == null) {
      throw Exception('Visibility not found');
    }
    return ValueListenableBuilder<OrgVisibilityState>(
      valueListenable: visibilityListenable,
      builder: (context, visibility, child) => ListView(
        shrinkWrap: shrinkWrap || !root,
        physics:
            shrinkWrap || !root ? const NeverScrollableScrollPhysics() : null,
        // It's very important that the padding not be null here; otherwise
        // sections inside a root document will get some extraneous padding (see
        // discussion of padding behavior on ListView)
        padding: root ? OrgTheme.dataOf(context).rootPadding : EdgeInsets.zero,
        children: <Widget>[
          InkWell(
            onTap: () => OrgController.of(context).cycleVisibilityOf(section),
            onLongPress: () =>
                OrgEvents.of(context).onSectionLongPress?.call(section),
            child: OrgHeadlineWidget(
              section.headline,
              open: _openEnough(visibility),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 100),
            transitionBuilder: (child, animation) =>
                SizeTransition(sizeFactor: animation, child: child),
            child: Column(
              key: ValueKey(visibility),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (section.content != null &&
                    (visibility == OrgVisibilityState.children ||
                        visibility == OrgVisibilityState.subtree))
                  OrgContentWidget(section.content!),
                if (visibility != OrgVisibilityState.folded)
                  ...section.sections.map((child) => OrgSectionWidget(child)),
              ],
            ),
          ),
          if (root) listBottomSafeArea(),
        ],
      ),
    );
  }
}

/// Generic Org Mode content
class OrgContentWidget extends StatelessWidget {
  const OrgContentWidget(
    this.content, {
    this.transformer,
    this.textAlign,
    super.key,
  });
  final OrgNode content;
  final Transformer? transformer;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return FancySpanBuilder(
      builder: (context, spanBuilder) => Text.rich(
        spanBuilder.build(
          content,
          transformer: transformer ?? identityTransformer,
        ),
        textAlign: textAlign,
      ),
    );
  }
}

/// An Org Mode section headline
class OrgHeadlineWidget extends StatelessWidget {
  const OrgHeadlineWidget(this.headline, {required this.open, super.key});
  final OrgHeadline headline;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final theme = OrgTheme.dataOf(context);
    final color = theme.levelColor(headline.level - 1);
    return DefaultTextStyle.merge(
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        height: 1.8,
      ),
      child: FancySpanBuilder(
        builder: (context, spanBuilder) {
          final body = Text.rich(
            TextSpan(
              children: [
                spanBuilder.highlightedSpan(
                    headline.stars.value + headline.stars.trailing),
                if (headline.keyword != null)
                  spanBuilder.highlightedSpan(
                      headline.keyword!.value + headline.keyword!.trailing,
                      style: DefaultTextStyle.of(context).style.copyWith(
                          color: headline.keyword!.value == 'DONE'
                              ? theme.doneColor
                              : theme.todoColor)),
                if (headline.priority != null)
                  spanBuilder.highlightedSpan(
                      headline.priority!.leading +
                          headline.priority!.value +
                          headline.priority!.trailing,
                      style: DefaultTextStyle.of(context)
                          .style
                          .copyWith(color: theme.priorityColor)),
                if (headline.title != null)
                  spanBuilder.build(
                    headline.title!,
                    transformer: (elem, text) {
                      if (identical(elem, headline.title!.children.last)) {
                        return text.trimRight();
                      } else {
                        return text;
                      }
                    },
                  ),
                if (!open && headline.tags == null) const TextSpan(text: '...'),
              ],
            ),
          );
          if (headline.tags == null) {
            return body;
          } else {
            return LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: body),
                    const SizedBox(width: 16),
                    ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: constraints.maxWidth / 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text.rich(
                              spanBuilder.highlightedSpan(
                                  headline.tags!.leading +
                                      headline.tags!.values.join(':') +
                                      headline.tags!.trailing),
                              overflow: TextOverflow.fade,
                              softWrap: false,
                            ),
                          ),
                          if (!open) const Text('...'),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          }
        },
      ),
    );
  }
}

/// A utility for overriding the text scale to be 1
class IdentityTextScale extends StatelessWidget {
  const IdentityTextScale({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1),
      ),
      child: child,
    );
  }
}

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
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final metaStyle =
        defaultStyle.copyWith(color: OrgTheme.dataOf(context).metaColor);
    final hideMarkup = OrgController.of(context).hideMarkup;
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
          language: block.language,
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

class OrgFootnoteReferenceWidget extends StatelessWidget {
  const OrgFootnoteReferenceWidget(this.reference, {super.key});
  final OrgFootnoteReference reference;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final footnoteStyle = defaultStyle.copyWith(
      color: OrgTheme.dataOf(context).footnoteColor,
    );

    return FancySpanBuilder(
      builder: (context, spanBuilder) => Text.rich(
        TextSpan(
          children: [
            spanBuilder.highlightedSpan(reference.leading,
                style: footnoteStyle),
            if (reference.name != null)
              spanBuilder.highlightedSpan(reference.name!,
                  style: footnoteStyle),
            if (reference.definitionDelimiter != null)
              spanBuilder.highlightedSpan(reference.definitionDelimiter!,
                  style: footnoteStyle),
            if (reference.definition != null)
              spanBuilder.build(
                reference.definition!,
                style: footnoteStyle,
              ),
            spanBuilder.highlightedSpan(reference.trailing,
                style: footnoteStyle),
          ],
        ),
      ),
    );
  }
}

class OrgFootnoteWidget extends StatelessWidget {
  const OrgFootnoteWidget(this.footnote, {super.key});
  final OrgFootnote footnote;

  @override
  Widget build(BuildContext context) {
    return FancySpanBuilder(
      builder: (context, spanBuilder) => Text.rich(
        TextSpan(
          children: [
            spanBuilder.build(footnote.marker),
            spanBuilder.build(footnote.content),
          ],
        ),
      ),
    );
  }
}

/// An Org Mode meta line
class OrgMetaWidget extends StatelessWidget {
  const OrgMetaWidget(this.meta, {super.key});
  final OrgMeta meta;

  @override
  Widget build(BuildContext context) {
    final hideMarkup = OrgController.of(context).hideMarkup;
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

/// An Org Mode table
class OrgTableWidget extends StatelessWidget {
  const OrgTableWidget(this.table, {super.key});
  final OrgTable table;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: TextStyle(color: OrgTheme.dataOf(context).tableColor),
      child: ConstrainedBox(
        // Ensure that table takes up entire width (can't have tables
        // side-by-side)
        constraints: const BoxConstraints.tightFor(width: double.infinity),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Row(
                children: <Widget>[
                  Text(table.indent),
                  _buildTable(context),
                ],
              ),
            ),
            if (table.trailing.isNotEmpty)
              Text(removeTrailingLineBreak(table.trailing)),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    final tableColor = OrgTheme.dataOf(context).tableColor;
    final borderSide =
        tableColor == null ? const BorderSide() : BorderSide(color: tableColor);
    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      border: TableBorder(
        verticalInside: borderSide,
        left: borderSide,
        right: table.rectangular ? borderSide : BorderSide.none,
      ),
      children: _tableRows(borderSide).toList(growable: false),
    );
  }

  Iterable<TableRow> _tableRows(BorderSide borderSide) sync* {
    final columnCount = table.columnCount;
    final numerical = List<bool>.generate(columnCount, table.columnIsNumeric);
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
            for (var j = 0; j < columnCount; j++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: j < row.cellCount
                    ? OrgContentWidget(
                        row.cells[j].content,
                        textAlign: numerical[j] ? TextAlign.right : null,
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        );
      }
    }
  }
}

/// An Org Mode fixed-width area
class OrgFixedWidthAreaWidget extends StatelessWidget {
  const OrgFixedWidthAreaWidget(this.fixedWidthArea, {super.key});
  final OrgFixedWidthArea fixedWidthArea;

  @override
  Widget build(BuildContext context) {
    return IndentBuilder(
      fixedWidthArea.indent,
      builder: (context, totalIndentSize) {
        return DefaultTextStyle.merge(
          style: TextStyle(color: OrgTheme.dataOf(context).codeColor),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: FancySpanBuilder(
              builder: (context, spanBuilder) => Text.rich(
                spanBuilder.highlightedSpan(
                  deindent(fixedWidthArea.content, totalIndentSize) +
                      removeTrailingLineBreak(fixedWidthArea.trailing),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// An Org Mode planning line
class OrgPlanningLineWidget extends StatelessWidget {
  const OrgPlanningLineWidget(this.planningLine, {super.key});
  final OrgPlanningLine planningLine;

  @override
  Widget build(BuildContext context) {
    return IndentBuilder(
      planningLine.indent,
      builder: (context, totalIndentSize) {
        return FancySpanBuilder(
          builder: (context, spanBuilder) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Text.rich(
              TextSpan(
                children: _spans(context, spanBuilder).toList(growable: false),
              ),
            ),
          ),
        );
      },
    );
  }

  Iterable<InlineSpan> _spans(
      BuildContext context, OrgSpanBuilder builder) sync* {
    yield builder.build(planningLine.keyword);
    yield builder.build(planningLine.body);
    final trailing = removeTrailingLineBreak(planningLine.trailing);
    if (trailing.isNotEmpty) {
      yield builder.highlightedSpan(trailing);
    }
  }
}

/// An Org Mode paragraph
class OrgParagraphWidget extends StatelessWidget {
  const OrgParagraphWidget(this.paragraph, {super.key});
  final OrgParagraph paragraph;

  @override
  Widget build(BuildContext context) {
    final hideMarkup = OrgController.of(context).hideMarkup;
    return IndentBuilder(
      paragraph.indent,
      builder: (context, totalIndentSize) {
        return OrgContentWidget(
          paragraph.body,
          transformer: (elem, content) {
            final isLast = identical(elem, paragraph.body.children.last);
            var formattedContent = deindent(content, totalIndentSize);
            if (hideMarkup) {
              formattedContent = reflowText(formattedContent, end: isLast);
            }
            return isLast
                ? removeTrailingLineBreak(formattedContent)
                : formattedContent;
          },
        );
      },
    );
  }
}

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
      yield OrgListItemWidget(item);
    }
    final trailing = removeTrailingLineBreak(list.trailing);
    if (trailing.isNotEmpty) {
      yield Text(trailing);
    }
  }
}

/// An Org Mode list item
class OrgListItemWidget extends StatelessWidget {
  const OrgListItemWidget(this.item, {super.key});
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
      yield builder.build(item.body!, transformer: (elem, content) {
        final isLast = identical(item.body!.children.last, elem);
        final hideMarkup = OrgController.of(context).hideMarkup;
        final formattedContent = hideMarkup
            ? reflowText(content, end: isLast)
            : deindent(content, totalIndentSize);
        return isLast
            ? removeTrailingLineBreak(formattedContent)
            : formattedContent;
      });
    }
  }
}

/// An Org Mode drawer
class OrgDrawerWidget extends StatefulWidget {
  const OrgDrawerWidget(this.drawer, {super.key});
  final OrgDrawer drawer;

  @override
  State<OrgDrawerWidget> createState() => _OrgDrawerWidgetState();
}

class _OrgDrawerWidgetState extends State<OrgDrawerWidget>
    with OpenCloseable<OrgDrawerWidget> {
  @override
  bool get defaultOpen => false;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final drawerStyle =
        defaultStyle.copyWith(color: OrgTheme.dataOf(context).drawerColor);
    final body = IndentBuilder(
      widget.drawer.indent,
      builder: (context, totalIndentSize) {
        return ValueListenableBuilder<bool>(
          valueListenable: openListenable,
          builder: (context, open, child) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              InkWell(
                onTap: () => openListenable.value = !openListenable.value,
                child: Text(
                  widget.drawer.header.trimRight() + (open ? '' : '...'),
                  style: drawerStyle,
                ),
              ),
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
                  removeTrailingLineBreak(widget.drawer.trailing),
                ),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _body((_, string) =>
                  removeTrailingLineBreak(deindent(string, totalIndentSize))),
              Text(
                deindent(widget.drawer.footer, totalIndentSize),
                style: drawerStyle,
              ),
            ],
          ),
        );
      },
    );
    return reduceOpacity(body, enabled: OrgController.of(context).hideMarkup);
  }

  Widget _body(Transformer transformer) {
    final body = OrgContentWidget(
      widget.drawer.body,
      transformer: transformer,
    );
    // TODO(aaron): Better distinguish "greater block" from regular block
    return widget.drawer.body is OrgContent
        ? body
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: body,
          );
  }
}

/// An Org Mode property
class OrgPropertyWidget extends StatelessWidget {
  const OrgPropertyWidget(this.property, {super.key});
  final OrgProperty property;

  @override
  Widget build(BuildContext context) {
    return IndentBuilder(
      property.indent,
      builder: (context, _) {
        return FancySpanBuilder(
          builder: (context, spanBuilder) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Text.rich(
              TextSpan(
                children: _spans(context, spanBuilder).toList(growable: false),
              ),
            ),
          ),
        );
      },
    );
  }

  Iterable<InlineSpan> _spans(
      BuildContext context, OrgSpanBuilder builder) sync* {
    yield builder.highlightedSpan(
      property.key,
      style: DefaultTextStyle.of(context)
          .style
          .copyWith(color: OrgTheme.dataOf(context).keywordColor),
    );
    yield builder.highlightedSpan(property.value);
    final trailing = removeTrailingLineBreak(property.trailing);
    if (trailing.isNotEmpty) {
      yield builder.highlightedSpan(trailing);
    }
  }
}

/// An Org Mode LaTeX block
class OrgLatexBlockWidget extends StatelessWidget {
  const OrgLatexBlockWidget(this.block, {super.key});

  final OrgLatexBlock block;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints.tightFor(width: double.infinity),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: TexImage(
              _content,
              displayMode: true,
              error: (context, error) {
                debugPrint(error.toString());
                return Text([
                  block.leading,
                  block.begin,
                  block.content,
                  block.end
                ].join(''));
              },
            ),
          ),
        ),
        // Remove two linebreaks because we introduce two by splitting the
        // text into two widgets in this Column
        Text(removeTrailingLineBreak(removeTrailingLineBreak(block.trailing))),
      ],
    );
  }

  String get _content {
    if (flutterTexJsSupportedEnvironments.contains(block.environment)) {
      return '${block.begin}${block.content}${block.end}';
    } else {
      return block.content;
    }
  }
}

/// An Org Mode LaTeX inline span
class OrgLatexInlineWidget extends StatelessWidget {
  const OrgLatexInlineWidget(this.latex, {super.key});

  final OrgLatexInline latex;

  @override
  Widget build(BuildContext context) {
    return TexImage(
      latex.content,
      displayMode: false,
      error: (context, error) {
        debugPrint(error.toString());
        return Text([
          latex.leadingDecoration,
          latex.content,
          latex.trailingDecoration,
        ].join(''));
      },
    );
  }
}
