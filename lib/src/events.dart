import 'package:flutter/widgets.dart';
import 'package:org_flutter/src/controller.dart';
import 'package:org_flutter/src/locator.dart';
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
    this.onCitationTap,
    this.onTimestampTap,
    this.loadImage,
    super.key,
  });

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

  static OrgEvents of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OrgEvents>()!;

  /// Invoke the appropriate handler for the given [url]
  void dispatchLinkTap(BuildContext context, OrgLink link) async {
    final controller = OrgController.of(context);

    var target = link.location;

    // Check if it's an ID link like `id:SECTION_ID`
    try {
      final fileLink = OrgFileLink.parse(target);
      if (fileLink.scheme == 'id:') {
        final section = controller.sectionWithId(fileLink.body);
        if (section != null) {
          onLocalSectionLinkTap?.call(section, searchOption: fileLink.extra);
          return;
        }
      } else if (fileLink.isLocal) {
        // The "degenerate" case where a file link points within the current file;
        // https://orgmode.org/manual/Search-Options.html
        target = fileLink.extra!;
      }
    } on Exception {
      // Ignore
    }

    // First, see if it's a local section link like `*Section Title` or
    // `#CUSTOM_ID`. We don't handle `id:SECTION_ID` here because that case is
    // covered above.
    if (isOrgLocalSectionSearch(target)) {
      final sectionTitle = parseOrgLocalSectionSearch(target);
      final section = controller.sectionWithTitle(sectionTitle);
      if (section != null) {
        onLocalSectionLinkTap?.call(section, searchOption: 'title');
        return;
      }
    } else if (isOrgCustomIdSearch(target)) {
      final sectionId = parseOrgCustomIdSearch(target);
      final section = controller.sectionWithCustomId(sectionId);
      if (section != null) {
        onLocalSectionLinkTap?.call(section, searchOption: 'custom-id');
        return;
      }
    }

    final handled = await OrgLocator.of(context)?.jumpToSearchOption(target);
    if (handled == true) return;

    // If we didn't find a section or other thing to jump to, invoke the
    // callback provided by the consumer
    onLinkTap?.call(link);
  }

  @override
  bool updateShouldNotify(OrgEvents oldWidget) =>
      onLinkTap != oldWidget.onLinkTap ||
      onSectionLongPress != oldWidget.onSectionLongPress;
}
