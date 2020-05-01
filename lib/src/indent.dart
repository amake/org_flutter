import 'package:flutter/widgets.dart';

class ListContext extends InheritedWidget {
  const ListContext(this.indentSize, {Widget child, Key key})
      : super(child: child, key: key);

  final int indentSize;

  @override
  bool updateShouldNotify(ListContext oldWidget) =>
      indentSize != oldWidget.indentSize;

  static ListContext of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ListContext>();
}

class IndentBuilder extends StatelessWidget {
  const IndentBuilder(this.indent, {this.builder, Key key})
      : assert(indent != null),
        super(key: key);

  final Widget Function(BuildContext, int) builder;
  final String indent;

  @override
  Widget build(BuildContext context) {
    final parentIndent = ListContext.of(context)?.indentSize ?? 0;
    final newIndent =
        indent.length >= parentIndent ? indent.substring(parentIndent) : '';
    final totalIndentSize = parentIndent + newIndent.length;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(newIndent),
        Expanded(
          child: ListContext(
            parentIndent + newIndent.length,
            child: builder(context, totalIndentSize),
          ),
        ),
      ],
    );
  }
}
