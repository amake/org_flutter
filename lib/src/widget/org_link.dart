import 'package:flutter/material.dart';
import 'package:org_flutter/src/events.dart';
import 'package:org_flutter/src/span.dart';
import 'package:org_parser/org_parser.dart';

/// A widget to display an [OrgLink].
///
/// This is not produced in the normal flow of things; rather [OrgSpanBuilder]
/// produces an inline [TextSpan] for OrgLinks. However consumers of org_flutter
/// may want this when e.g. an image widget supplied to [OrgEvents.loadImage]
/// fails to load the image, and as a fallback the consumer wants to display the
/// link as it would have been shown had it been treated as a text link.
///
/// This widget will *not* attempt to render a link as an image.
///
/// To customize link handling, wrap this with an [OrgEvents] widget.
class OrgLinkWidget extends StatelessWidget {
  const OrgLinkWidget(this.link, {super.key});

  final OrgLink link;

  @override
  Widget build(BuildContext context) {
    return FancySpanBuilder(
      inlineImages: false,
      builder: (context, spanBuilder) => Text.rich(spanBuilder.build(link)),
    );
  }
}
