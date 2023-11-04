import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:org_flutter/src/util/util.dart';

typedef Transformer = String Function(OrgNode, String);

String identityTransformer(OrgNode _, String str) => str;

/// A utility for building a complex, nested [InlineSpan] out of text runs and
/// org_flutter widgets
class OrgSpanBuilder {
  OrgSpanBuilder(
    this.context, {
    required this.recognizerHandler,
    required this.highlight,
    required this.hideMarkup,
  });

  final BuildContext context;
  final RecognizerHandler recognizerHandler;
  final Pattern highlight;
  final bool hideMarkup;

  InlineSpan build(
    OrgNode element, {
    TextStyle? style,
    Transformer transformer = identityTransformer,
  }) {
    style ??= DefaultTextStyle.of(context).style;
    if (element is OrgPlainText) {
      return highlightedSpan(
        transformer(element, element.content),
        style: style,
      );
    } else if (element is OrgMarkup) {
      return highlightedSpan(
        transformer(
          element,
          hideMarkup
              ? element.content
              : '${element.leadingDecoration}${element.content}${element.trailingDecoration}',
        ),
        style: OrgTheme.dataOf(context).fontStyleForOrgStyle(
          style,
          element.style,
        ),
      );
    } else if (element is OrgEntity) {
      var text = OrgController.of(context).prettifyEntity(element.name);
      text ??= '${element.leading}${element.name}${element.trailing}';
      return highlightedSpan(transformer(element, text), style: style);
    } else if (element is OrgMacroReference) {
      return highlightedSpan(transformer(element, element.content),
          style: style.copyWith(color: OrgTheme.dataOf(context).macroColor));
    } else if (element is OrgKeyword) {
      return highlightedSpan(
        transformer(element, element.content),
        style: style.copyWith(color: OrgTheme.dataOf(context).keywordColor),
      );
    } else if (element is OrgLink) {
      if (looksLikeImagePath(element.location)) {
        final imageWidget = OrgEvents.of(context).loadImage?.call(element);
        if (imageWidget != null) {
          return WidgetSpan(child: imageWidget);
        }
      }
      final linkDispatcher = OrgEvents.of(context).dispatchLinkTap;
      final recognizer = TapGestureRecognizer()
        ..onTap = () => linkDispatcher(context, element.location);
      recognizerHandler(recognizer);
      final visibleContent = element is OrgBracketLink
          ? element.description ?? element.location
          : element.location;
      return highlightedSpan(
        transformer(element, visibleContent),
        recognizer: recognizer,
        style: style.copyWith(
          color: OrgTheme.dataOf(context).linkColor,
          decoration: TextDecoration.underline,
        ),
        charWrap: looksLikeUrl(visibleContent),
      );
    } else if (element is OrgTimestamp) {
      return highlightedSpan(
        transformer(element, element.content),
        style: style.copyWith(
          color: OrgTheme.dataOf(context).dateColor,
          decoration: TextDecoration.underline,
        ),
      );
    } else if (element is OrgFootnoteReference) {
      final key = element.name == null
          ? null
          : OrgController.of(context).generateFootnoteKey(element.id);
      return WidgetSpan(child: OrgFootnoteReferenceWidget(element, key: key));
    } else if (element is OrgFootnote) {
      return WidgetSpan(child: OrgFootnoteWidget(element));
    } else if (element is OrgMeta) {
      return WidgetSpan(child: OrgMetaWidget(element));
    } else if (element is OrgBlock) {
      return WidgetSpan(child: OrgBlockWidget(element));
    } else if (element is OrgTable) {
      return WidgetSpan(child: OrgTableWidget(element));
    } else if (element is OrgFixedWidthArea) {
      return WidgetSpan(child: OrgFixedWidthAreaWidget(element));
    } else if (element is OrgParagraph) {
      return WidgetSpan(child: OrgParagraphWidget(element));
    } else if (element is OrgPlanningLine) {
      return WidgetSpan(child: OrgPlanningLineWidget(element));
    } else if (element is OrgList) {
      return WidgetSpan(child: OrgListWidget(element));
    } else if (element is OrgDrawer) {
      return WidgetSpan(child: OrgDrawerWidget(element));
    } else if (element is OrgProperty) {
      return WidgetSpan(child: OrgPropertyWidget(element));
    } else if (element is OrgLatexBlock) {
      return WidgetSpan(child: OrgLatexBlockWidget(element));
    } else if (element is OrgLatexInline) {
      return WidgetSpan(
        child: OrgLatexInlineWidget(element),
        alignment: PlaceholderAlignment.middle,
      );
    } else if (element is OrgLocalVariables) {
      return WidgetSpan(child: OrgLocalVariablesWidget(element));
    } else if (element is OrgContent) {
      return TextSpan(
          children: element.children
              .map((child) => build(
                    child,
                    transformer: transformer,
                    style: style,
                  ))
              .toList(growable: false));
    } else {
      throw Exception('Unknown OrgNode type: $element');
    }
  }

  InlineSpan highlightedSpan(
    String text, {
    TextStyle? style,
    GestureRecognizer? recognizer,
    bool charWrap = false,
  }) {
    if (emptyPattern(highlight)) {
      return TextSpan(
        text: charWrap ? characterWrappable(text) : text,
        style: style,
        recognizer: recognizer,
      );
    } else {
      style ??= DefaultTextStyle.of(context).style;
      return TextSpan(
        style: style,
        children: tokenizeTextSpan(
          text,
          highlight,
          style.copyWith(
            backgroundColor: OrgTheme.dataOf(context).highlightColor,
          ),
          charWrap ? characterWrappable : (x) => x,
          recognizer,
        ).toList(growable: false),
      );
    }
  }

  Iterable<InlineSpan> tokenizeTextSpan(
    String text,
    Pattern pattern,
    TextStyle matchStyle,
    String Function(String) transform,
    GestureRecognizer? recognizer,
  ) sync* {
    var lastEnd = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > lastEnd) {
        yield TextSpan(
          text: transform(text.substring(lastEnd, match.start)),
          recognizer: recognizer,
        );
      }
      yield WidgetSpan(
        child: _SearchResultSpan(
          span: TextSpan(
            text: transform(match.group(0)!),
            style: matchStyle,
            recognizer: recognizer,
          ),
          key: OrgController.of(context).generateSearchResultKey(),
        ),
      );
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      yield TextSpan(
        text: transform(text.substring(lastEnd, text.length)),
        recognizer: recognizer,
      );
    }
  }
}

class _SearchResultSpan extends StatefulWidget {
  const _SearchResultSpan({required this.span, super.key});
  final InlineSpan span;

  @override
  State<_SearchResultSpan> createState() => SearchResultSpanState();
}

/// The state object for a search result. Consumers of
/// [OrgControllerData.searchResultKeys] can use [selected] to toggle focus
/// highlighting.
class SearchResultSpanState extends State<_SearchResultSpan> {
  bool _selected = false;

  set selected(bool value) {
    setState(() => _selected = value);
  }

  @override
  Widget build(BuildContext context) {
    final text = Text.rich(widget.span);
    return _selected
        ? DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 0.5,
              ),
            ),
            position: DecorationPosition.foreground,
            child: text,
          )
        : text;
  }
}

class FancySpanBuilder extends StatefulWidget {
  const FancySpanBuilder({required this.builder, super.key});
  final Widget Function(BuildContext, OrgSpanBuilder) builder;

  @override
  State<FancySpanBuilder> createState() => _FancySpanBuilderState();
}

class _FancySpanBuilderState extends State<FancySpanBuilder>
    with RecognizerManager<FancySpanBuilder> {
  @override
  Widget build(BuildContext context) {
    final controller = OrgController.of(context);
    return widget.builder(
      context,
      OrgSpanBuilder(
        context,
        recognizerHandler: registerRecognizer,
        highlight: controller.searchQuery,
        hideMarkup: controller.hideMarkup,
      ),
    );
  }
}
