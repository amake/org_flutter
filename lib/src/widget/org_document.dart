import 'package:flutter/material.dart';
import 'package:org_flutter/src/controller.dart';
import 'package:org_flutter/src/settings.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_flutter/src/widget/org_content.dart';
import 'package:org_flutter/src/widget/org_section.dart';
import 'package:org_flutter/src/widget/org_theme.dart';
import 'package:org_parser/org_parser.dart';

/// The root of the actual Org Mode document itself. Assumes that
/// [OrgRootWidget] and [OrgController] are available in the build context. See
/// the Org widget for a more user-friendly entrypoint.
class OrgDocumentWidget extends StatelessWidget {
  const OrgDocumentWidget(
    this.document, {
    this.shrinkWrap = false,
    this.safeArea = true,
    super.key,
  });

  final OrgDocument document;
  final bool shrinkWrap;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    return ListView(
      restorationId: shrinkWrap
          ? null
          : OrgController.of(context)
              .restorationIdFor('org_document_list_view'),
      padding: OrgTheme.dataOf(context).rootPadding,
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      children: <Widget>[
        if (document.content != null) ..._contentWidgets(context),
        ...document.sections.map((section) => OrgSectionWidget(section)),
        if (safeArea) listBottomSafeArea(),
      ],
    );
  }

  Iterable<Widget> _contentWidgets(BuildContext context) sync* {
    for (final child in document.content!.children) {
      Widget widget = OrgContentWidget(child);
      final textDirection = OrgController.of(context).settings.textDirection ??
          child.detectTextDirection();
      if (textDirection != null) {
        widget = Directionality(textDirection: textDirection, child: widget);
      }
      yield widget;
    }
  }
}
