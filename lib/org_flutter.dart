import 'package:flutter/widgets.dart';
import 'package:org_flutter/src/controller.dart';
import 'package:org_flutter/src/locator.dart';
import 'package:org_flutter/src/settings.dart';
import 'package:org_flutter/src/theme.dart';
import 'package:org_flutter/src/widgets.dart';
import 'package:org_parser/org_parser.dart';

export 'package:org_flutter/src/controller.dart';
export 'package:org_flutter/src/error.dart';
export 'package:org_flutter/src/events.dart';
export 'package:org_flutter/src/locator.dart';
export 'package:org_flutter/src/settings.dart';
export 'package:org_flutter/src/theme.dart';
export 'package:org_flutter/src/util/util.dart'
    show looksLikeImagePath, looksLikeUrl;
export 'package:org_flutter/src/widgets.dart';
export 'package:org_parser/org_parser.dart';

/// Display an Org Mode document with full interaction.
///
/// This is the default entrypoint for org_flutter. It composes its own
/// [OrgController], [OrgRootWidget], and [OrgDocumentWidget]. For advanced use
/// cases you may want to arrange these on your own.
class Org extends StatefulWidget {
  const Org(
    this.text, {
    this.style,
    this.lightTheme,
    this.darkTheme,
    this.settings,
    this.onLinkTap,
    this.onLocalSectionLinkTap,
    this.onSectionLongPress,
    this.onSectionSlide,
    this.onListItemTap,
    this.onCitationTap,
    this.onTimestampTap,
    this.loadImage,
    this.loadLatexInline,
    this.loadLatexBlock,
    this.loadTransclusion,
    this.restorationId,
    super.key,
  });

  /// Raw Org Mode document in text form
  final String text;

  /// Text style to serve as a basis for all text in the document
  final TextStyle? style;

  final OrgThemeData? lightTheme;
  final OrgThemeData? darkTheme;

  /// A collection of settings that affect the appearance of the document
  final OrgSettings? settings;

  /// A callback invoked when the user taps a link. The argument is the
  /// [OrgLink] object; the URL is [OrgLink.location]. You might want to open
  /// this in a browser.
  final void Function(OrgLink)? onLinkTap;

  /// A callback invoked when the user taps on a link to a section within the
  /// current document. The argument is the target section. You might want to
  /// display it somehow. If the link to the section included a [search
  /// option](https://orgmode.org/manual/Search-Options.html), it will be
  /// included as [searchOption].
  final void Function(OrgTree, {String? searchOption})? onLocalSectionLinkTap;

  /// A callback invoked when the user long-presses on a section headline within
  /// the current document. The argument is the pressed section. You might want
  /// to narrow the display to show just this section.
  final void Function(OrgSection)? onSectionLongPress;

  /// A callback invoked to build a list of actions revealed when the user
  /// slides a section. The argument is the section being slid. Consider
  /// supplying instances of `SlidableAction` from the
  /// [flutter_slidable](https://pub.dev/packages/flutter_slidable) package.
  final List<Widget> Function(OrgSection)? onSectionSlide;

  /// A callback invoked when an image should be displayed. The argument is the
  /// [OrgLink] describing where the image data can be found. It is your
  /// responsibility to resolve the link, fetch the data, and return a widget
  /// for displaying the image.
  ///
  /// Return null instead to display the link text.
  final Widget? Function(OrgLink)? loadImage;

  /// A callback invoked when an inline LaTeX fragment such as `\(a^2\)` should
  /// be displayed. The argument is the [OrgLatexInline] fragment; the LaTeX
  /// source is [OrgLatexInline.content]. It is your responsibility to render
  /// the fragment and return a span for displaying it, e.g. a [WidgetSpan]
  /// with [PlaceholderAlignment.baseline].
  ///
  /// `style` is the ambient text style at that point: the fully resolved style
  /// the surrounding text is drawn with, including markup such as bold and the
  /// theme's colors (e.g. a headline's level color). Apply it to the rendered
  /// formula so that it matches the surrounding text; a [WidgetSpan] does not
  /// pick it up on its own.
  ///
  /// Return null instead to display the LaTeX source.
  final InlineSpan? Function(OrgLatexInline latex, TextStyle style)?
  loadLatexInline;

  /// A callback invoked when a LaTeX block such as
  /// `\begin{equation}...\end{equation}` should be displayed. The argument is
  /// the [OrgLatexBlock]; the environment is [OrgLatexBlock.environment] and
  /// the LaTeX source is [OrgLatexBlock.begin], [OrgLatexBlock.content], and
  /// [OrgLatexBlock.end]. It is your responsibility to render the block and
  /// return a widget for displaying it. The widget is placed in a horizontally
  /// scrolling container, so its width is unbounded and it must size itself.
  ///
  /// Return null instead to display the LaTeX source.
  final Widget? Function(OrgLatexBlock latex)? loadLatexBlock;

  /// A callback invoked when loading transcluded content. The argument is the
  /// [OrgMeta] describing the transclusion. It is your responsibility to
  /// resolve the link, if present, fetch the data, and return a widget for
  /// displaying the transcluded content.
  ///
  /// If the content cannot be loaded, return a widget indicating the failure.
  final Widget Function(OrgMeta)? loadTransclusion;

  /// A callback invoked when the user taps on a list item that has a checkbox
  /// within the current document. The argument is the tapped item. You might
  /// want to toggle the checkbox.
  final void Function(OrgListItem)? onListItemTap;

  /// A callback invoked when the user taps on a citation.
  final void Function(OrgCitation)? onCitationTap;

  /// A callback invoked when the user taps on a timestamp.
  final void Function(OrgNode)? onTimestampTap;

  /// An ID for temporary state restoration. Supply a unique ID to ensure that
  /// temporary state such as scroll position is preserved as appropriate.
  final String? restorationId;

  @override
  State<Org> createState() => _OrgState();
}

class _OrgState extends State<Org> {
  late OrgDocument _doc;

  @override
  void initState() {
    _doc = OrgDocument.parse(widget.text);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant Org oldWidget) {
    if (oldWidget.text != widget.text) {
      _doc = OrgDocument.parse(widget.text);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return OrgController(
      root: _doc,
      settings: widget.settings,
      restorationId: widget.restorationId,
      child: OrgLocator(
        child: OrgRootWidget(
          style: widget.style,
          lightTheme: widget.lightTheme,
          darkTheme: widget.darkTheme,
          onLinkTap: widget.onLinkTap,
          onLocalSectionLinkTap: widget.onLocalSectionLinkTap,
          onSectionLongPress: widget.onSectionLongPress,
          onSectionSlide: widget.onSectionSlide,
          onListItemTap: widget.onListItemTap,
          onCitationTap: widget.onCitationTap,
          onTimestampTap: widget.onTimestampTap,
          loadImage: widget.loadImage,
          loadLatexInline: widget.loadLatexInline,
          loadLatexBlock: widget.loadLatexBlock,
          loadTransclusion: widget.loadTransclusion,
          child: OrgDocumentWidget(_doc),
        ),
      ),
    );
  }
}

/// Display an Org Mode document with minimal interaction, suitable for use as a
/// rich equivalent to a [Text] widget.
class OrgText extends StatefulWidget {
  const OrgText(
    this.text, {
    this.onLinkTap,
    this.loadImage,
    this.loadLatexInline,
    this.loadLatexBlock,
    this.settings,
    super.key,
  });

  /// Raw Org Mode document in text form
  final String text;

  /// A collection of settings that affect the appearance of the document
  final OrgSettings? settings;

  /// A callback invoked when the user taps a link. The argument is the
  /// [OrgLink] object; the URL is [OrgLink.location]. You might want to open
  /// this in a browser.
  final void Function(OrgLink)? onLinkTap;

  /// A callback invoked when an image should be displayed. The argument is the
  /// [OrgLink] describing where the image data can be found. It is your
  /// responsibility to resolve the link, fetch the data, and return a widget
  /// for displaying the image.
  ///
  /// Return null instead to display the link text.
  final Widget? Function(OrgLink)? loadImage;

  /// A callback invoked when an inline LaTeX fragment such as `\(a^2\)` should
  /// be displayed. The argument is the [OrgLatexInline] fragment; the LaTeX
  /// source is [OrgLatexInline.content]. It is your responsibility to render
  /// the fragment and return a span for displaying it, e.g. a [WidgetSpan]
  /// with [PlaceholderAlignment.baseline].
  ///
  /// `style` is the ambient text style at that point: the fully resolved style
  /// the surrounding text is drawn with, including markup such as bold and the
  /// theme's colors (e.g. a headline's level color). Apply it to the rendered
  /// formula so that it matches the surrounding text; a [WidgetSpan] does not
  /// pick it up on its own.
  ///
  /// Return null instead to display the LaTeX source.
  final InlineSpan? Function(OrgLatexInline latex, TextStyle style)?
  loadLatexInline;

  /// A callback invoked when a LaTeX block such as
  /// `\begin{equation}...\end{equation}` should be displayed. The argument is
  /// the [OrgLatexBlock]; the environment is [OrgLatexBlock.environment] and
  /// the LaTeX source is [OrgLatexBlock.begin], [OrgLatexBlock.content], and
  /// [OrgLatexBlock.end]. It is your responsibility to render the block and
  /// return a widget for displaying it. The widget is placed in a horizontally
  /// scrolling container, so its width is unbounded and it must size itself.
  ///
  /// Return null instead to display the LaTeX source.
  final Widget? Function(OrgLatexBlock latex)? loadLatexBlock;

  @override
  State<OrgText> createState() => _OrgTextState();
}

class _OrgTextState extends State<OrgText> {
  late OrgDocument _doc;

  @override
  void initState() {
    _doc = OrgDocument.parse(widget.text);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant OrgText oldWidget) {
    if (oldWidget.text != widget.text) {
      _doc = OrgDocument.parse(widget.text);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return OrgController(
      root: _doc,
      settings: widget.settings ?? OrgSettings.hideMarkup,
      child: OrgRootWidget(
        onLinkTap: widget.onLinkTap,
        loadImage: widget.loadImage,
        loadLatexInline: widget.loadLatexInline,
        loadLatexBlock: widget.loadLatexBlock,
        lightTheme: OrgThemeData.light().copyWith(rootPadding: EdgeInsets.zero),
        darkTheme: OrgThemeData.dark().copyWith(rootPadding: EdgeInsets.zero),
        child: OrgDocumentWidget(_doc, shrinkWrap: true, safeArea: false),
      ),
    );
  }
}
