import 'package:flutter/material.dart';
import 'package:org_flutter/src/controller.dart';
import 'package:org_flutter/src/span.dart';
import 'package:org_flutter/src/widget/org_theme.dart';
import 'package:org_parser/org_parser.dart';

class OrgFootnoteReferenceWidget extends StatelessWidget {
  const OrgFootnoteReferenceWidget(this.reference, {super.key});
  final OrgFootnoteReference reference;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final footnoteStyle = defaultStyle.copyWith(
      color: OrgTheme.dataOf(context).footnoteColor,
    );

    return FancySpanBuilder(
      builder: (context, spanBuilder) => InkWell(
        onTap: reference.name == null ? null : () => _onTap(context),
        child: Text.rich(
          TextSpan(
            children: [
              spanBuilder.highlightedSpan(reference.leading,
                  style: footnoteStyle),
              if (reference.name != null)
                spanBuilder.highlightedSpan(reference.name!,
                    style: footnoteStyle),
              if (reference.definition != null)
                spanBuilder.highlightedSpan(reference.definition!.delimiter,
                    style: footnoteStyle),
              if (reference.definition != null)
                spanBuilder.build(
                  reference.definition!.value,
                  style: footnoteStyle,
                ),
              spanBuilder.highlightedSpan(reference.trailing,
                  style: footnoteStyle),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    final controller = OrgController.of(context);
    final result = controller.root.find<OrgFootnoteReference>((ref) {
      return ref.name == reference.name &&
          ref.isDefinition != reference.isDefinition;
    });
    if (result == null) return;

    final footnoteKeys = controller.footnoteKeys;
    final key = footnoteKeys.value[result.node.id];
    if (key != null && key.currentContext?.mounted == true) {
      _makeVisible(key);
      return;
    }

    // Target widget is probably not currently visible, so make it visible and
    // then listen for its key to become available.
    controller.ensureVisible(result.path);

    void listenForKey() {
      final key = footnoteKeys.value[result.node.id];
      if (key != null && key.currentContext?.mounted == true) {
        Future.delayed(
          const Duration(milliseconds: 100),
          () => _makeVisible(key),
        );
      }
      footnoteKeys.removeListener(listenForKey);
    }

    footnoteKeys.addListener(listenForKey);
  }

  void _makeVisible(FootnoteKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null || !targetContext.mounted) return;
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 100),
    );
  }
}
