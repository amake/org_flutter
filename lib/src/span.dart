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
  })  : assert(context != null),
        assert(recognizerHandler != null);

  final BuildContext context;
  final RecognizerHandler recognizerHandler;
  final Pattern highlight;

  InlineSpan build(
    OrgContentElement element, {
    Transformer transformer = identityTransformer,
  }) {
    if (element is OrgPlainText) {
      return highlightedSpan(transformer(element, element.content));
    } else if (element is OrgMarkup) {
      return highlightedSpan(
        transformer(element, element.content),
        style: OrgTheme.dataOf(context).fontStyleForOrgStyle(
          DefaultTextStyle.of(context).style,
          element.style,
        ),
      );
    } else if (element is OrgMacroReference) {
      return highlightedSpan(transformer(element, element.content),
          style: DefaultTextStyle.of(context)
              .style
              .copyWith(color: OrgTheme.dataOf(context).macroColor));
    } else if (element is OrgKeyword) {
      return highlightedSpan(
        transformer(element, element.content),
        style: DefaultTextStyle.of(context)
            .style
            .copyWith(color: OrgTheme.dataOf(context).keywordColor),
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
        style: DefaultTextStyle.of(context).style.copyWith(
              color: OrgTheme.dataOf(context).linkColor,
              decoration: TextDecoration.underline,
            ),
        charWrap: true,
      );
    } else if (element is OrgTimestamp) {
      return highlightedSpan(
        transformer(element, element.content),
        style: DefaultTextStyle.of(context).style.copyWith(
              color: OrgTheme.dataOf(context).dateColor,
              decoration: TextDecoration.underline,
            ),
      );
    } else if (element is OrgMeta) {
      return WidgetSpan(
          child: IdentityTextScale(child: OrgMetaWidget(element)));
    } else if (element is OrgBlock) {
      return WidgetSpan(
          child: IdentityTextScale(child: OrgBlockWidget(element)));
    } else if (element is OrgTable) {
      return WidgetSpan(
          child: IdentityTextScale(child: OrgTableWidget(element)));
    } else if (element is OrgFixedWidthArea) {
      return WidgetSpan(
          child: IdentityTextScale(child: OrgFixedWidthAreaWidget(element)));
    } else if (element is OrgParagraph) {
      return WidgetSpan(
          child: IdentityTextScale(child: OrgParagraphWidget(element)));
    } else if (element is OrgList) {
      // Render lists with structure for reflowing, etc.
      return WidgetSpan(
          child: IdentityTextScale(child: OrgListWidget(element)));
      // Render lists as just text
//      return TextSpan(children: [
//        for (final item in element.items) build(item, transformer: transformer),
//      ]);
    } else if (element is OrgListItem) {
      // TODO(aaron): Decide what use should be made of the transformer here
      return TextSpan(children: [
        TextSpan(text: element.indent),
        TextSpan(text: element.bullet),
        if (element is OrgListOrderedItem && element.counterSet != null)
          TextSpan(text: '${element.counterSet} '),
        if (element.checkbox != null)
          TextSpan(
            text: '${element.checkbox} ',
            style: DefaultTextStyle.of(context)
                .style
                .copyWith(fontWeight: FontWeight.bold),
          ),
        if (element is OrgListUnorderedItem && element.tag != null)
          TextSpan(
            text: element.tag,
            style: DefaultTextStyle.of(context)
                .style
                .copyWith(fontWeight: FontWeight.bold),
          ),
        if (element.body != null) build(element.body, transformer: transformer),
      ]);
    } else if (element is OrgDrawer) {
      return WidgetSpan(
          child: IdentityTextScale(child: OrgDrawerWidget(element)));
    } else if (element is OrgProperty) {
      return WidgetSpan(
          child: IdentityTextScale(child: OrgPropertyWidget(element)));
    } else if (element is OrgContent) {
      return TextSpan(
          children: element.children
              .map((child) => build(child, transformer: transformer))
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
      final realStyle = style ?? DefaultTextStyle.of(context).style;
      return TextSpan(
        style: realStyle,
        recognizer: recognizer,
        children: tokenizeTextSpan(
          text,
          highlight,
          realStyle.copyWith(
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
