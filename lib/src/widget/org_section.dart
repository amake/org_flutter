import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:org_flutter/src/controller.dart';
import 'package:org_flutter/src/events.dart';
import 'package:org_flutter/src/settings.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_flutter/src/widget/org_content.dart';
import 'package:org_flutter/src/widget/org_headline.dart';
import 'package:org_flutter/src/widget/org_theme.dart';
import 'package:org_parser/org_parser.dart';

/// An Org Mode section
class OrgSectionWidget extends StatelessWidget {
  const OrgSectionWidget(
    this.section, {
    this.siblingIndex = 0,
    this.root = false,
    this.shrinkWrap = false,
    super.key,
  });
  final OrgSection section;
  final bool root;
  final bool shrinkWrap;
  final int siblingIndex;

  // Whether the section is open "enough" to not show the trailing ellipsis
  bool _openEnough(OrgVisibilityState visibility) {
    switch (visibility) {
      case OrgVisibilityState.folded:
        return section.isEmpty;
      case OrgVisibilityState.contents:
        return section.content == null;
      case OrgVisibilityState.children:
      case OrgVisibilityState.subtree:
        return true;
      case OrgVisibilityState.hidden:
        // Not meaningful
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibilityListenable =
        OrgController.of(context).nodeFor(section).visibility;
    Widget widget = ValueListenableBuilder<OrgVisibilityState>(
      valueListenable: visibilityListenable,
      builder: (context, visibility, child) => visibility ==
              OrgVisibilityState.hidden
          ? const SizedBox.shrink()
          : ListView(
              shrinkWrap: shrinkWrap || !root,
              physics: shrinkWrap || !root
                  ? const NeverScrollableScrollPhysics()
                  : null,
              // It's very important that the padding not be null here; otherwise
              // sections inside a root document will get some extraneous padding (see
              // discussion of padding behavior on ListView)
              padding:
                  root ? OrgTheme.dataOf(context).rootPadding : EdgeInsets.zero,
              children: <Widget>[
                InkWell(
                  onTap: () =>
                      OrgController.of(context).cycleVisibilityOf(section),
                  onLongPress: () =>
                      OrgEvents.of(context).onSectionLongPress?.call(section),
                  child: OrgHeadlineWidget(
                    section.headline,
                    open: _openEnough(visibility),
                    highlighted:
                        OrgController.of(context).sparseQuery?.matches(section),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 100),
                  transitionBuilder: (child, animation) =>
                      SizeTransition(sizeFactor: animation, child: child),
                  child: Column(
                    key: ValueKey(visibility),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (section.content != null &&
                          (visibility == OrgVisibilityState.children ||
                              visibility == OrgVisibilityState.subtree))
                        ..._contentWidgets(context),
                      if (visibility != OrgVisibilityState.folded)
                        for (final (i, section) in section.sections.indexed)
                          OrgSectionWidget(
                            section,
                            siblingIndex: i,
                          ),
                    ],
                  ),
                ),
                if (root) listBottomSafeArea(),
              ],
            ),
    );
    widget = _withSlideActions(context, widget);
    return OrgNumData(
      nums: {
        ...OrgNumData.of(context)?.nums ?? {},
        section.level: siblingIndex + 1
      },
      child: widget,
    );
  }

  Iterable<Widget> _contentWidgets(BuildContext context) sync* {
    for (final child in section.content!.children) {
      Widget widget = OrgContentWidget(child);
      final textDirection = OrgSettings.of(context).settings.textDirection ??
          child.detectTextDirection();
      if (textDirection != null) {
        widget = Directionality(textDirection: textDirection, child: widget);
      }
      yield widget;
    }
  }

  Widget _withSlideActions(BuildContext context, Widget child) {
    final actions = OrgEvents.of(context).onSectionSlide?.call(section);
    if (actions == null) return child;
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: actions,
      ),
      child: child,
    );
  }
}
