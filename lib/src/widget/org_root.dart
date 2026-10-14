import 'package:material_ui/material_ui.dart';
import 'package:org_flutter/src/events.dart';
import 'package:org_flutter/src/settings.dart';
import 'package:org_flutter/src/theme.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_flutter/src/widget/org_theme.dart';
import 'package:org_parser/org_parser.dart';

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
    this.onSectionSlide,
    this.onListItemTap,
    this.onCitationTap,
    this.onTimestampTap,
    this.loadImage,
    this.loadTransclusion,
    super.key,
  });

  final Widget child;

  /// Text style to serve as a basis for all text in the document
  final TextStyle? style;

  final OrgThemeData? lightTheme;
  final OrgThemeData? darkTheme;

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

  /// A callback invoked when the user taps on a list item that has a checkbox
  /// within the current document. The argument is the tapped item. You might
  /// want to toggle the checkbox.
  final void Function(OrgListItem)? onListItemTap;

  /// A callback invoked when the user taps on a citation.
  final void Function(OrgCitation)? onCitationTap;

  /// A callback invoked when the user taps on a timestamp.
  final void Function(OrgNode)? onTimestampTap;

  /// A callback invoked when an image should be displayed. The argument is the
  /// [OrgLink] describing where the image data can be found. It is your
  /// responsibility to resolve the link, fetch the data, and return a widget
  /// for displaying the image.
  ///
  /// Return null instead to display the link text.
  final Widget? Function(OrgLink)? loadImage;

  /// A callback invoked when loading transcluded content. The argument is the
  /// [OrgMeta] describing the transclusion. It is your responsibility to
  /// resolve the link, if present, fetch the data, and return a widget for
  /// displaying the transcluded content.
  ///
  /// If the content cannot be loaded, return a widget indicating the failure.
  final Widget Function(OrgMeta)? loadTransclusion;

  @override
  Widget build(BuildContext context) {
    Widget body = OrgTheme(
      light: lightTheme ?? OrgThemeData.light(),
      dark: darkTheme ?? OrgThemeData.dark(),
      child: OrgEvents(
        onLinkTap: onLinkTap,
        onSectionLongPress: onSectionLongPress,
        onSectionSlide: onSectionSlide,
        onLocalSectionLinkTap: onLocalSectionLinkTap,
        loadImage: loadImage,
        onListItemTap: onListItemTap,
        onCitationTap: onCitationTap,
        onTimestampTap: onTimestampTap,
        loadTransclusion: loadTransclusion,
        child: IdentityTextScale(child: child),
      ),
    );
    final docLocale = OrgSettings.of(context).settings.locale;
    if (docLocale != null) {
      body = Localizations.override(
        context: context,
        locale: docLocale,
        delegates: _fallbackDelegates(context, docLocale),
        child: body,
      );
    }
    return style == null
        ? body
        : DefaultTextStyle.merge(style: style, child: body);
  }

  List<LocalizationsDelegate<dynamic>>? _fallbackDelegates(
    BuildContext context,
    Locale docLocale,
  ) {
    final parentLocale = Localizations.localeOf(context);
    if (docLocale == parentLocale) return null;

    // The document locale may not be supported by the app's localizations, so
    // we need to allow fallback in order for localizations in
    // consumer-provided widgets to work.
    //
    // I.e. a widget supplied from loadImage that accesses
    // MyLocalizations.of(context) will have the ambient locale set to
    // docLocale, but MyLocalizations may not support that locale. By wrapping
    // them we let them pretend to support docLocale.
    final inheritedLocalizations = context
        .findAncestorWidgetOfExactType<Localizations>();
    final delegates = inheritedLocalizations?.delegates;
    if (delegates == null) return null;

    // Preserve Flutter's first-supported-delegate selection. If any delegate
    // of a type supports the document locale, let Flutter select it normally.
    final supportedTypes = delegates
        .where((delegate) => delegate.isSupported(docLocale))
        .map((d) => d.type)
        .toSet();

    // If no delegate of a type supports the document locale, forward through
    // the first delegate of that type that supports the parent locale.
    final fallbacks = <Type, LocalizationsDelegate<dynamic>>{};
    for (final delegate in delegates) {
      if (!supportedTypes.contains(delegate.type) &&
          delegate.isSupported(parentLocale)) {
        fallbacks.putIfAbsent(delegate.type, () => delegate);
      }
    }

    return fallbacks.values
        .map((d) => _ParentLocaleFallbackDelegate(d, parentLocale))
        .toList(growable: false);
  }
}

// A [LocalizationsDelegate] that allows the provided delegate to fall back to a
// parent locale if the requested locale is not supported.
class _ParentLocaleFallbackDelegate<T> extends LocalizationsDelegate<T> {
  const _ParentLocaleFallbackDelegate(this.delegate, this.parentLocale);

  final LocalizationsDelegate<T> delegate;
  final Locale parentLocale;

  @override
  Type get type => delegate.type;

  @override
  bool isSupported(Locale locale) =>
      delegate.isSupported(locale) || delegate.isSupported(parentLocale);

  @override
  Future<T> load(Locale locale) {
    final loadLocale = delegate.isSupported(locale) ? locale : parentLocale;
    return delegate.load(loadLocale);
  }

  @override
  bool shouldReload(covariant _ParentLocaleFallbackDelegate<T> old) =>
      delegate != old.delegate || parentLocale != old.parentLocale;
}
