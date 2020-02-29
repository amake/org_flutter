library org_flutter;

import 'package:flutter/widgets.dart';
import 'package:org_flutter/src/widgets.dart';
import 'package:org_parser/org_parser.dart';

export 'package:org_flutter/src/theme.dart';
export 'package:org_flutter/src/widgets.dart';
export 'package:org_parser/org_parser.dart';

class Org extends StatelessWidget {
  const Org(
    this.text, {
    this.style,
    this.onLinkTap,
    this.onSectionLongPress,
    Key key,
  })  : assert(text != null),
        super(key: key);
  final String text;
  final TextStyle style;
  final Function(String) onLinkTap;
  final Function(OrgSection) onSectionLongPress;

  @override
  Widget build(BuildContext context) {
    return OrgRootWidget(
      style: style,
      onLinkTap: onLinkTap,
      onSectionLongPress: onSectionLongPress,
      child: OrgDocumentWidget(OrgDocument(text)),
    );
  }
}
