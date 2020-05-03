import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:org_flutter/src/util.dart';

typedef Transformer = String Function(OrgContentElement, String);

String identityTransformer(OrgContentElement _, String str) => str;

typedef RecognizerHandler = Function(GestureRecognizer);

class SpanBuilder {
  SpanBuilder(
    this.context, {
    @required this.recognizerHandler,
    this.highlight,
    this.hideMarkup = false,
  })  : assert(context != null),
        assert(recognizerHandler != null),
        assert(hideMarkup != null);

  final BuildContext context;
  final RecognizerHandler recognizerHandler;
  final Pattern highlight;
  final bool hideMarkup;

  InlineSpan build(
    OrgContentElement element, {
    TextStyle style,
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
    } else if (element is OrgMacroReference) {
      return highlightedSpan(transformer(element, element.content),
          style: style.copyWith(color: OrgTheme.dataOf(context).macroColor));
    } else if (element is OrgKeyword) {
      return highlightedSpan(
        transformer(element, element.content),
        style: style.copyWith(color: OrgTheme.dataOf(context).keywordColor),
      );
    } else if (element is OrgLink) {
      final linkDispatcher =
          OrgEvents.of(context)?.dispatchLinkTap ?? (_, __) {};
      final recognizer = TapGestureRecognizer()
        ..onTap = () => linkDispatcher(context, element.location);
      recognizerHandler(recognizer);
      final visibleContent = element.description ?? element.location;
      return highlightedSpan(
        transformer(element, visibleContent),
        recognizer: recognizer,
        style: style.copyWith(
          color: OrgTheme.dataOf(context).linkColor,
          decoration: TextDecoration.underline,
        ),
        charWrap: true,
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
      final footnoteStyle = style.copyWith(
        color: OrgTheme.dataOf(context).footnoteColor,
      );
      InlineSpan _highlight(String text) {
        return highlightedSpan(
          transformer(element, text),
          style: footnoteStyle,
        );
      }

      // TODO(aaron): Make footnote references clickable
      return TextSpan(children: [
        _highlight(element.leading),
        if (element.name != null) _highlight(element.name),
        if (element.definitionDelimiter != null)
          _highlight(element.definitionDelimiter),
        if (element.definition != null)
          build(element.definition, style: style, transformer: transformer),
        _highlight(element.trailing),
      ]);
    } else if (element is OrgFootnote) {
      return TextSpan(
        children: [
          element.marker,
          element.content,
        ]
            .map((child) => build(
                  child,
                  style: style,
                  transformer: transformer == identityTransformer
                      ? (elem, text) => reflowText(
                            text,
                            end: element.content.children.last == elem,
                          )
                      : transformer,
                ))
            .toList(growable: false),
      );
    } else if (element is OrgMeta) {
      // TODO(aaron): Decide whether to hide this when `hideMarkup` is true
      return hideMarkup
          ? const TextSpan()
          : WidgetSpan(child: OrgMetaWidget(element));
    } else if (element is OrgBlock) {
      return WidgetSpan(child: OrgBlockWidget(element));
    } else if (element is OrgTable) {
      return WidgetSpan(child: OrgTableWidget(element));
    } else if (element is OrgFixedWidthArea) {
      return WidgetSpan(child: OrgFixedWidthAreaWidget(element));
    } else if (element is OrgParagraph) {
      return WidgetSpan(child: OrgParagraphWidget(element));
    } else if (element is OrgList) {
      return WidgetSpan(child: OrgListWidget(element));
    } else if (element is OrgDrawer) {
      return hideMarkup
          ? const TextSpan()
          : WidgetSpan(child: OrgDrawerWidget(element));
    } else if (element is OrgProperty) {
      return WidgetSpan(child: OrgPropertyWidget(element));
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
      throw Exception('Unknown OrgContentElement type: $element');
    }
  }

  InlineSpan highlightedSpan(
    String text, {
    TextStyle style,
    GestureRecognizer recognizer,
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
        recognizer: recognizer,
        children: tokenizeTextSpan(
          text,
          highlight,
          style.copyWith(
            backgroundColor: OrgTheme.dataOf(context).highlightColor,
          ),
          charWrap ? characterWrappable : (x) => x,
        ).toList(growable: false),
      );
    }
  }
}

Iterable<InlineSpan> tokenizeTextSpan(
  String text,
  Pattern pattern,
  TextStyle matchStyle,
  String Function(String) transform,
) sync* {
  var lastEnd = 0;
  for (final match in pattern.allMatches(text)) {
    if (match.start > lastEnd) {
      yield TextSpan(text: transform(text.substring(lastEnd, match.start)));
    }
    yield TextSpan(text: transform(match.group(0)), style: matchStyle);
    lastEnd = match.end;
  }
  if (lastEnd < text.length) {
    yield TextSpan(text: transform(text.substring(lastEnd, text.length)));
  }
}
