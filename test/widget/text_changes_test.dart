import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import './util.dart';

class _TextProvider extends StatefulWidget {
  const _TextProvider({required this.text, required this.builder});

  final Widget Function(String) builder;
  final String text;

  @override
  State<_TextProvider> createState() => _TextProviderState();
}

class _TextProviderState extends State<_TextProvider> {
  late String _text;

  set text(String text) => setState(() => _text = text);

  @override
  void initState() {
    super.initState();
    _text = widget.text;
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_text);
  }
}

void main() {
  group('Text changes', () {
    testWidgets('Org widget', (tester) async {
      final widget = _TextProvider(
        text: 'foo bar',
        builder: (text) => wrap(Org(text)),
      );
      await tester.pumpWidget(widget);
      expect(find.text('foo bar'), findsOneWidget);
      final state =
          tester.state(find.byType(_TextProvider)) as _TextProviderState;
      state.text = 'baz buzz';
      await tester.pump();
      expect(find.text('foo bar'), findsNothing);
      expect(find.text('baz buzz'), findsOneWidget);
    });
    testWidgets('OrgText widget', (tester) async {
      final widget = _TextProvider(
        text: 'foo bar',
        builder: (text) => wrap(OrgText(text)),
      );
      await tester.pumpWidget(widget);
      expect(find.text('foo bar'), findsOneWidget);
      final state =
          tester.state(find.byType(_TextProvider)) as _TextProviderState;
      state.text = 'baz buzz';
      await tester.pump();
      expect(find.text('foo bar'), findsNothing);
      expect(find.text('baz buzz'), findsOneWidget);
    });
  });
}
