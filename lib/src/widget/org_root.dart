import 'package:flutter/material.dart';
import 'package:org_flutter/src/events.dart';
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
    this.loadImage,
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
  /// display it somehow.
  final void Function(OrgTree)? onLocalSectionLinkTap;

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
        onSectionSlide: onSectionSlide,
        onLocalSectionLinkTap: onLocalSectionLinkTap,
        loadImage: loadImage,
        onListItemTap: onListItemTap,
        onCitationTap: onCitationTap,
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
