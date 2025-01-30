import 'package:flutter/material.dart';
import 'package:org_flutter/src/indent.dart';
import 'package:org_flutter/src/settings.dart';
import 'package:org_flutter/src/span.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_flutter/src/widget/org_content.dart';
import 'package:org_flutter/src/widget/org_theme.dart';
import 'package:org_parser/org_parser.dart';

/// An Org Mode drawer
class OrgDrawerWidget extends StatefulWidget {
  const OrgDrawerWidget(this.drawer, {super.key});
  final OrgDrawer drawer;

  @override
  State<OrgDrawerWidget> createState() => _OrgDrawerWidgetState();
}

class _OrgDrawerWidgetState extends State<OrgDrawerWidget>
    with OpenCloseable<OrgDrawerWidget> {
  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inited) {
      openListenable.value =
          !OrgSettings.of(context).settings.hideDrawerStartup;
      _inited = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = IndentBuilder(
      widget.drawer.indent,
      builder: (context, totalIndentSize) {
        final defaultStyle = DefaultTextStyle.of(context).style;
        final drawerStyle =
            defaultStyle.copyWith(color: OrgTheme.dataOf(context).drawerColor);
        return ValueListenableBuilder<bool>(
          valueListenable: openListenable,
          builder: (context, open, child) {
            final trailingWidget = _trailing();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                InkWell(
                  onTap: () => openListenable.value = !openListenable.value,
                  child: Text(
                    widget.drawer.header.trimRight() + (open ? '' : '...'),
                    style: drawerStyle,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 100),
                  transitionBuilder: (child, animation) =>
                      SizeTransition(sizeFactor: animation, child: child),
                  child: open ? child : const SizedBox.shrink(),
                ),
                if (trailingWidget != null) trailingWidget,
              ],
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _body((_, string) =>
                  removeTrailingLineBreak(deindent(string, totalIndentSize))),
              Text(
                deindent(widget.drawer.footer, totalIndentSize),
                style: drawerStyle,
              ),
            ],
          ),
        );
      },
    );
    return reduceOpacity(
      body,
      enabled: OrgSettings.of(context).settings.deemphasizeMarkup,
    );
  }

  Widget _body(Transformer transformer) {
    final body = OrgContentWidget(
      widget.drawer.body,
      transformer: transformer,
    );
    // TODO(aaron): Better distinguish "greater block" from regular block
    return widget.drawer.body is OrgContent
        ? body
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: body,
          );
  }

  Widget? _trailing() {
    var trailing = removeTrailingLineBreak(widget.drawer.trailing);
    // If trailing is empty here then there is something immediately following
    // the drawer. Because we render the drawer with full width, any trailing
    // Text widget will result in an unwanted empty line. Thus we return null.
    if (trailing.isEmpty) return null;
    // We have to remove another linebreak because there will be an implicit
    // linebreak when this widget ends.
    return Text(removeTrailingLineBreak(trailing));
  }
}
