library org_flutter;

import 'package:flutter/widgets.dart';
import 'package:org_flutter/src/controller.dart';
import 'package:org_flutter/src/theme.dart';
import 'package:org_flutter/src/widgets.dart';
import 'package:org_parser/org_parser.dart';

export 'package:org_flutter/src/controller.dart';
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
class Org extends StatelessWidget {
  const Org(
    this.text, {
    this.style,
    this.lightTheme,
    this.darkTheme,
    this.onLinkTap,
    this.onLocalSectionLinkTap,
    this.onSectionLongPress,
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

  /// A callback invoked when the user taps a link. The argument is the link
  /// URL. You might want to open this in a browser.
  final Function(String)? onLinkTap;

  /// A callback invoked when the user taps on a link to a section within the
  /// current document. The argument is the target section. You might want to
  /// display it somehow.
  final Function(OrgSection)? onLocalSectionLinkTap;

  /// A callback invoked when the user long-presses on a section headline within
  /// the current document. The argument is the pressed section. You might want
  /// to narrow the display to show just this section.
  final Function(OrgSection)? onSectionLongPress;

  /// A callback invoked when an image should be displayed. The argument is the
  /// [OrgLink] describing where the image data can be found. It is your
  /// responsibility to resolve the link, fetch the data, and return a widget
  /// for displaying the image.
  ///
  /// Return null instead to display the link text.
  final Widget? Function(OrgLink)? loadImage;

  /// An ID for temporary state restoration. Supply a unique ID to ensure that
  /// temporary state such as scroll position is preserved as appropriate.
  final String? restorationId;

  @override
  Widget build(BuildContext context) {
    final doc = OrgDocument.parse(text);
    return OrgController(
      root: doc,
      restorationId: restorationId,
      child: OrgRootWidget(
        style: style,
        lightTheme: lightTheme,
        darkTheme: darkTheme,
        onLinkTap: onLinkTap,
        onLocalSectionLinkTap: onLocalSectionLinkTap,
        onSectionLongPress: onSectionLongPress,
        loadImage: loadImage,
        child: OrgDocumentWidget(doc),
      ),
    );
  }
}
