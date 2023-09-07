import 'package:flutter/widgets.dart';

class IndentContext extends InheritedWidget {
  const IndentContext(this.indentSize, {required super.child, super.key});

  final int indentSize;

  @override
  bool updateShouldNotify(IndentContext oldWidget) =>
      indentSize != oldWidget.indentSize;

  static IndentContext? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<IndentContext>();
}

class IndentBuilder extends StatelessWidget {
  const IndentBuilder(
    this.indent, {
    required this.builder,
    super.key,
  });

  final Widget Function(BuildContext, int) builder;
  final String indent;

  @override
  Widget build(BuildContext context) {
    final parentIndent = IndentContext.of(context)?.indentSize ?? 0;
    final newIndent =
        indent.length >= parentIndent ? indent.substring(parentIndent) : '';
    final totalIndentSize = parentIndent + newIndent.length;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(newIndent),
        Expanded(
          child: IndentContext(
            parentIndent + newIndent.length,
            child: builder(context, totalIndentSize),
          ),
        ),
      ],
    );
  }
}
