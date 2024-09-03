import 'package:flutter/widgets.dart';
import 'package:org_flutter/src/controller.dart';
import 'package:org_parser/org_parser.dart';

/// A widget for managing callbacks invoked upon user interaction or other
/// document-related events.
class OrgEvents extends InheritedWidget {
  const OrgEvents({
    required super.child,
    this.onLinkTap,
    this.onLocalSectionLinkTap,
    this.onSectionLongPress,
    this.onSectionSlide,
    this.onListItemTap,
    this.loadImage,
    super.key,
  });

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
  void dispatchLinkTap(BuildContext context, OrgLink link) {
    final section = _resolveLocalSectionLink(context, link.location);
    if (section != null) {
      onLocalSectionLinkTap?.call(section);
    } else {
      onLinkTap?.call(link);
    }
  }

  OrgTree? _resolveLocalSectionLink(BuildContext context, String url) {
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
