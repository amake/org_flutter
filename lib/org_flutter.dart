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
    Key? key,
  }) : super(key: key);
  final String text;
  final TextStyle? style;
  final OrgThemeData? lightTheme;
  final OrgThemeData? darkTheme;
  final Function(String)? onLinkTap;
  final Function(OrgSection)? onLocalSectionLinkTap;
  final Function(OrgSection)? onSectionLongPress;
  final Widget? Function(OrgLink)? loadImage;
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
