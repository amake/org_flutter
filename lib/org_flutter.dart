library org_flutter;

import 'package:flutter/widgets.dart';
import 'package:org_flutter/src/controller.dart';
import 'package:org_flutter/src/settings.dart';
import 'package:org_flutter/src/theme.dart';
import 'package:org_flutter/src/widgets.dart';
import 'package:org_parser/org_parser.dart';

export 'package:org_flutter/src/controller.dart';
export 'package:org_flutter/src/error.dart';
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
    this.onListItemTap,
    this.loadImage,
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

  /// A callback invoked when the user taps a link. The argument is the link
  /// URL. You might want to open this in a browser.
  final void Function(String)? onLinkTap;

  /// A callback invoked when the user taps on a link to a section within the
  /// current document. The argument is the target section. You might want to
  /// display it somehow.
  final void Function(OrgSection)? onLocalSectionLinkTap;

  /// A callback invoked when the user long-presses on a section headline within
  /// the current document. The argument is the pressed section. You might want
  /// to narrow the display to show just this section.
  final void Function(OrgSection)? onSectionLongPress;

  /// A callback invoked when an image should be displayed. The argument is the
  /// [OrgLink] describing where the image data can be found. It is your
  /// responsibility to resolve the link, fetch the data, and return a widget
  /// for displaying the image.
  ///
  /// Return null instead to display the link text.
  final Widget? Function(OrgLink)? loadImage;

  /// A callback invoked when the user taps on a list item that has a checkbox
  /// within the current document. The argument is the tapped item. You might
  /// want to toggle the checkbox.
  final void Function(OrgListItem)? onListItemTap;

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
  Widget build(BuildContext context) {
    return OrgController(
      root: _doc,
      settings: widget.settings,
      restorationId: widget.restorationId,
      child: OrgRootWidget(
        style: widget.style,
        lightTheme: widget.lightTheme,
        darkTheme: widget.darkTheme,
        onLinkTap: widget.onLinkTap,
        onLocalSectionLinkTap: widget.onLocalSectionLinkTap,
        onSectionLongPress: widget.onSectionLongPress,
        onListItemTap: widget.onListItemTap,
        loadImage: widget.loadImage,
        child: OrgDocumentWidget(_doc),
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
    this.settings,
    super.key,
  });

  /// Raw Org Mode document in text form
  final String text;

  /// A collection of settings that affect the appearance of the document
  final OrgSettings? settings;

  /// A callback invoked when the user taps a link. The argument is the link
  /// URL. You might want to open this in a browser.
  final void Function(String)? onLinkTap;

  /// A callback invoked when an image should be displayed. The argument is the
  /// [OrgLink] describing where the image data can be found. It is your
  /// responsibility to resolve the link, fetch the data, and return a widget
  /// for displaying the image.
  ///
  /// Return null instead to display the link text.
  final Widget? Function(OrgLink)? loadImage;

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
  Widget build(BuildContext context) {
    return OrgController(
      root: _doc,
      settings: widget.settings ?? OrgSettings.hideMarkup,
      child: OrgRootWidget(
        onLinkTap: widget.onLinkTap,
        loadImage: widget.loadImage,
        lightTheme: OrgThemeData.light().copyWith(rootPadding: EdgeInsets.zero),
        darkTheme: OrgThemeData.dark().copyWith(rootPadding: EdgeInsets.zero),
        child: OrgDocumentWidget(
          _doc,
          shrinkWrap: true,
          safeArea: false,
        ),
      ),
    );
  }
}
