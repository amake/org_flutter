import 'package:flutter/material.dart';
import 'package:org_flutter/src/widget/org_content.dart';
import 'package:org_flutter/src/widget/org_section.dart';
import 'package:org_parser/org_parser.dart';

/// A widget representing content decrypted from an [OrgPgpBlock]
class OrgDecryptedContentWidget extends StatelessWidget {
  const OrgDecryptedContentWidget(this.content, {super.key});

  final OrgDecryptedContent content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (content.content != null) OrgContentWidget(content.content!),
        for (final (i, section) in content.sections.indexed)
          OrgSectionWidget(
            section,
            siblingIndex: i,
          ),
      ],
    );
  }
}
