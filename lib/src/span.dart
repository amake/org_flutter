import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:org_flutter/src/controller.dart';
import 'package:org_flutter/src/events.dart';
import 'package:org_flutter/src/search.dart';
import 'package:org_flutter/src/settings.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_flutter/src/widgets.dart';
import 'package:org_parser/org_parser.dart';

typedef Transformer = String Function(OrgNode, String);

String identityTransformer(OrgNode _, String str) => str;

/// A utility for building a complex, nested [InlineSpan] out of text runs and
/// org_flutter widgets
class OrgSpanBuilder {
  OrgSpanBuilder(
    this.context, {
    required this.recognizerHandler,
    required this.highlight,
    required this.hideEmphasisMarkers,
  });

  final BuildContext context;
  final RecognizerHandler recognizerHandler;
  final Pattern? highlight;
  final bool hideEmphasisMarkers;

  InlineSpan build(
    OrgNode element, {
    TextStyle? style,
    Transformer transformer = identityTransformer,
    bool inlineImages = true,
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
          hideEmphasisMarkers
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
      if (looksLikeImagePath(element.location) &&
          OrgController.of(context).settings.inlineImages &&
          inlineImages) {
        final imageWidget = OrgEvents.of(context).loadImage?.call(element);
        if (imageWidget != null) {
          return WidgetSpan(child: imageWidget);
        }
      }
      final linkDispatcher = OrgEvents.of(context).dispatchLinkTap;
      final recognizer = TapGestureRecognizer()
        ..onTap = () => linkDispatcher(context, element);
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
    } else if (element is OrgSuperscript) {
      if (OrgController.of(context).settings.prettyEntities) {
        return WidgetSpan(child: OrgSuperscriptWidget(element));
      } else {
        return TextSpan(children: [
          highlightedSpan(element.leading),
          build(element.body, transformer: transformer, style: style),
          highlightedSpan(element.trailing)
        ]);
      }
    } else if (element is OrgSubscript) {
      if (OrgController.of(context).settings.prettyEntities) {
        return WidgetSpan(child: OrgSubscriptWidget(element));
      } else {
        return TextSpan(children: [
          highlightedSpan(element.leading),
          build(element.body, transformer: transformer, style: style),
          highlightedSpan(element.trailing)
        ]);
      }
    } else if (element is OrgFootnoteReference) {
      final key = element.name == null
          ? null
          : OrgController.of(context).generateFootnoteKey(element.id);
      return WidgetSpan(child: OrgFootnoteReferenceWidget(element, key: key));
    } else if (element is OrgFootnote) {
      return WidgetSpan(child: OrgFootnoteWidget(element));
    } else if (element is OrgCitation) {
      return WidgetSpan(child: OrgCitationWidget(element));
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
    } else if (element is OrgPgpBlock) {
      return WidgetSpan(child: OrgPgpBlockWidget(element));
    } else if (element is OrgComment) {
      return WidgetSpan(child: OrgCommentWidget(element));
    } else if (element is OrgDecryptedContent) {
      return WidgetSpan(child: OrgDecryptedContentWidget(element));
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
    if (highlight.isEmpty) {
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
    Pattern? pattern,
    TextStyle matchStyle,
    String Function(String) transform,
    GestureRecognizer? recognizer,
  ) sync* {
    pattern ??= '';
    var lastEnd = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > lastEnd) {
        yield TextSpan(
          text: transform(text.substring(lastEnd, match.start)),
          recognizer: recognizer,
        );
      }
      yield WidgetSpan(
        child: SearchResult.of(
          context,
          child: Text.rich(TextSpan(
            text: transform(match.group(0)!),
            style: matchStyle,
            recognizer: recognizer,
          )),
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
        hideEmphasisMarkers: controller.settings.hideEmphasisMarkers,
      ),
    );
  }
}
