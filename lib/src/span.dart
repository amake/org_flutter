import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:org_flutter/src/controller.dart';
import 'package:org_flutter/src/entity.dart';
import 'package:org_flutter/src/events.dart';
import 'package:org_flutter/src/locator.dart';
import 'package:org_flutter/src/search.dart';
import 'package:org_flutter/src/settings.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_flutter/src/widget/org_link_target.dart';
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
  });

  final BuildContext context;
  final RecognizerHandler recognizerHandler;

  InlineSpan build(
    OrgNode element, {
    TextStyle? style,
    Transformer transformer = identityTransformer,
    bool inlineImages = true,
    GestureRecognizer? recognizer,
  }) {
    style ??= DefaultTextStyle.of(context).style;
    if (element is OrgPlainText) {
      return highlightedSpan(
        transformer(element, element.content),
        style: style,
        recognizer: recognizer,
      );
    } else if (element is OrgMarkup) {
      final markupStyle = OrgTheme.dataOf(context).fontStyleForOrgStyle(
        style,
        element.style,
      );
      final body = build(element.content,
          transformer: transformer, style: markupStyle, recognizer: recognizer);
      return OrgController.of(context).settings.hideEmphasisMarkers
          ? body
          : TextSpan(children: [
              highlightedSpan(element.leadingDecoration,
                  style: markupStyle, recognizer: recognizer),
              body,
              highlightedSpan(element.trailingDecoration,
                  style: markupStyle, recognizer: recognizer),
            ]);
    } else if (element is OrgEntity) {
      var text = OrgController.of(context).prettifyEntity(element.name);
      text ??= '${element.leading}${element.name}${element.trailing}';
      return highlightedSpan(transformer(element, text),
          style: style, recognizer: recognizer);
    } else if (element is OrgMacroReference) {
      return highlightedSpan(transformer(element, element.content),
          style: style.copyWith(color: OrgTheme.dataOf(context).macroColor),
          recognizer: recognizer);
    } else if (element is OrgKeyword) {
      return highlightedSpan(
        transformer(element, element.content),
        style: style.copyWith(color: OrgTheme.dataOf(context).keywordColor),
        recognizer: recognizer,
      );
    } else if (element is OrgLink) {
      if (looksLikeImagePath(element.location) &&
          OrgController.of(context).settings.inlineImages &&
          inlineImages) {
        final imageWidget = OrgEvents.of(context).loadImage?.call(element);
        if (imageWidget != null) {
          return _styledWidgetSpan(imageWidget, style);
        }
      }
      final linkDispatcher = OrgEvents.of(context).dispatchLinkTap;
      final recognizer = TapGestureRecognizer()
        ..onTap = () => linkDispatcher(context, element);
      recognizerHandler(recognizer);
      final linkStyle = style.copyWith(
        color: OrgTheme.dataOf(context).linkColor,
        decoration: TextDecoration.underline,
      );
      if (element is OrgPlainLink ||
          element is OrgBracketLink && element.description == null) {
        return highlightedSpan(
          transformer(element, element.location),
          recognizer: recognizer,
          style: linkStyle,
          charWrap: looksLikeUrl(element.location),
        );
      }
      if (element is OrgBracketLink && element.description != null) {
        return build(
          element.description!,
          transformer: transformer,
          style: linkStyle,
          recognizer: recognizer,
        );
      }
    } else if (element is OrgRadioLink) {
      final recognizer = TapGestureRecognizer()
        ..onTap = () => OrgLocator.of(context)?.jumpToRadioTarget(element);
      return highlightedSpan(
        transformer(element, element.content),
        recognizer: recognizer,
        style: style.copyWith(
          color: OrgTheme.dataOf(context).linkColor,
          decoration: TextDecoration.underline,
        ),
      );
    } else if (element is OrgRadioTarget) {
      // TODO(aaron): Figure out what is supposed to happen when tapping a radio
      // target
      final key = OrgLocator.of(context)
          ?.generateRadioTargetKey(element.body.toLowerCase());
      return _styledWidgetSpan(OrgRadioTargetWidget(element, key: key), style);
    } else if (element is OrgLinkTarget) {
      final key = OrgLocator.of(context)
          ?.generateLinkTargetKey(element.body.toLowerCase());
      return _styledWidgetSpan(OrgLinkTargetWidget(element, key: key), style);
    } else if (element is OrgDiaryTimestamp) {
      return highlightedSpan(
        transformer(element, element.content),
        style: style.copyWith(
          color: OrgTheme.dataOf(context).dateColor,
          decoration: TextDecoration.underline,
        ),
        recognizer: recognizer,
      );
    } else if (element is OrgSimpleTimestamp) {
      final onTap = OrgEvents.of(context).onTimestampTap;
      final recognizer = onTap == null
          ? null
          : (TapGestureRecognizer()..onTap = () => onTap(element));
      if (recognizer != null) recognizerHandler(recognizer);
      return highlightedSpan(
        transformer(element, element.toMarkup()),
        recognizer: recognizer,
        style: style.copyWith(
          color: OrgTheme.dataOf(context).dateColor,
          decoration: TextDecoration.underline,
        ),
      );
    } else if (element is OrgTimeRangeTimestamp) {
      final onTap = OrgEvents.of(context).onTimestampTap;
      final recognizer = onTap == null
          ? null
          : (TapGestureRecognizer()..onTap = () => onTap(element));
      if (recognizer != null) recognizerHandler(recognizer);
      return highlightedSpan(
        transformer(element, element.toMarkup()),
        recognizer: recognizer,
        style: style.copyWith(
          color: OrgTheme.dataOf(context).dateColor,
          decoration: TextDecoration.underline,
        ),
      );
    } else if (element is OrgDateRangeTimestamp) {
      return TextSpan(children: [
        build(element.start,
            transformer: transformer, style: style, recognizer: recognizer),
        highlightedSpan(element.delimiter, recognizer: recognizer),
        build(element.end,
            transformer: transformer, style: style, recognizer: recognizer),
      ]);
    } else if (element is OrgStatisticsPercentageCookie) {
      final color = element.done
          ? OrgTheme.dataOf(context).doneColor
          : OrgTheme.dataOf(context).todoColor;
      final progressStyle =
          style.copyWith(color: color, fontWeight: FontWeight.bold);
      return highlightedSpan(transformer(element, element.toMarkup()),
          style: progressStyle, recognizer: recognizer);
    } else if (element is OrgStatisticsFractionCookie) {
      final color = element.done
          ? OrgTheme.dataOf(context).doneColor
          : OrgTheme.dataOf(context).todoColor;
      final progressStyle =
          style.copyWith(color: color, fontWeight: FontWeight.bold);
      return highlightedSpan(transformer(element, element.toMarkup()),
          style: progressStyle, recognizer: recognizer);
    } else if (element is OrgSuperscript) {
      if (shouldPrettifySubSuperscript(context, element)) {
        return _styledWidgetSpan(OrgSuperscriptWidget(element), style);
      } else {
        return TextSpan(children: [
          highlightedSpan(element.leading,
              style: style, recognizer: recognizer),
          build(element.body,
              transformer: transformer, style: style, recognizer: recognizer),
          highlightedSpan(element.trailing,
              style: style, recognizer: recognizer)
        ]);
      }
    } else if (element is OrgSubscript) {
      if (shouldPrettifySubSuperscript(context, element)) {
        return _styledWidgetSpan(OrgSubscriptWidget(element), style);
      } else {
        return TextSpan(children: [
          highlightedSpan(element.leading,
              style: style, recognizer: recognizer),
          build(element.body,
              transformer: transformer, style: style, recognizer: recognizer),
          highlightedSpan(element.trailing,
              style: style, recognizer: recognizer)
        ]);
      }
    } else if (element is OrgFootnoteReference) {
      final key = element.name == null
          ? null
          : OrgLocator.of(context)?.generateFootnoteKey(element.id);
      return _styledWidgetSpan(
          OrgFootnoteReferenceWidget(element, key: key), style);
    } else if (element is OrgFootnote) {
      return _styledWidgetSpan(OrgFootnoteWidget(element), style);
    } else if (element is OrgCitation) {
      return _styledWidgetSpan(OrgCitationWidget(element), style);
    } else if (element is OrgMeta) {
      final key = element.keyword.toUpperCase() == '#+NAME:'
          ? OrgLocator.of(context)
              ?.generateNameKey(element.trailing.trim().toLowerCase())
          : null;
      return _styledWidgetSpan(OrgMetaWidget(element, key: key), style);
    } else if (element is OrgBlock) {
      return _styledWidgetSpan(OrgBlockWidget(element), style);
    } else if (element is OrgTable) {
      return _styledWidgetSpan(OrgTableWidget(element), style);
    } else if (element is OrgHorizontalRule) {
      return _styledWidgetSpan(
          OrgHorizontalRuleWidget(element), style, PlaceholderAlignment.middle);
    } else if (element is OrgFixedWidthArea) {
      return _styledWidgetSpan(OrgFixedWidthAreaWidget(element), style);
    } else if (element is OrgParagraph) {
      return _styledWidgetSpan(OrgParagraphWidget(element), style);
    } else if (element is OrgPlanningLine) {
      return _styledWidgetSpan(OrgPlanningLineWidget(element), style);
    } else if (element is OrgList) {
      return _styledWidgetSpan(OrgListWidget(element), style);
    } else if (element is OrgDrawer) {
      return _styledWidgetSpan(OrgDrawerWidget(element), style);
    } else if (element is OrgProperty) {
      return _styledWidgetSpan(OrgPropertyWidget(element), style);
    } else if (element is OrgLatexBlock) {
      return _styledWidgetSpan(OrgLatexBlockWidget(element), style);
    } else if (element is OrgLatexInline) {
      return _styledWidgetSpan(
          OrgLatexInlineWidget(element), style, PlaceholderAlignment.middle);
    } else if (element is OrgLocalVariables) {
      return _styledWidgetSpan(OrgLocalVariablesWidget(element), style);
    } else if (element is OrgPgpBlock) {
      return _styledWidgetSpan(OrgPgpBlockWidget(element), style);
    } else if (element is OrgComment) {
      return _styledWidgetSpan(OrgCommentWidget(element), style);
    } else if (element is OrgDecryptedContent) {
      return _styledWidgetSpan(OrgDecryptedContentWidget(element), style);
    } else if (element is OrgContent) {
      return TextSpan(
          children: element.children
              .map((child) => build(
                    child,
                    transformer: transformer,
                    style: style,
                    recognizer: recognizer,
                  ))
              .toList(growable: false));
    }
    throw Exception('Unknown OrgNode type: $element');
  }

  InlineSpan highlightedSpan(
    String text, {
    TextStyle? style,
    GestureRecognizer? recognizer,
    bool charWrap = false,
  }) {
    final highlight = OrgController.of(context).searchQuery;
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

InlineSpan _styledWidgetSpan(
  Widget child,
  TextStyle? style, [
  PlaceholderAlignment? alignment,
]) {
  if (style != null) {
    // Supplying the style to the WidgetSpan doesn't get the full effect
    // because only some properties are used. We need to set it as the default
    // to get e.g. the text color to propagate.
    child = DefaultTextStyle(style: style, child: child);
  }
  return WidgetSpan(
    child: child,
    style: style,
    // TODO(aaron): Somehow check that .bottom continues to be the default
    alignment: alignment ?? PlaceholderAlignment.bottom,
  );
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
    return widget.builder(
      context,
      OrgSpanBuilder(
        context,
        recognizerHandler: registerRecognizer,
      ),
    );
  }
}
