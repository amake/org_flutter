import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import './util.dart';

void main() {
  group('Search', () {
    group('Results', () {
      testWidgets('No query', (tester) async {
        final doc = OrgDocument.parse('foo bar baz');
        final widget = OrgController(
          root: doc,
          child: OrgRootWidget(
            child: OrgDocumentWidget(doc),
          ),
        );
        await tester.pumpWidget(wrap(widget));
        final controller = OrgController.of(
            tester.element(find.textContaining('foo bar baz')));
        expect(controller.searchResultKeys.value.length, 0);
      });
      testWidgets('One result', (tester) async {
        final doc = OrgDocument.parse('foo bar baz');
        final widget = OrgController(
          root: doc,
          searchQuery: 'bar',
          child: OrgRootWidget(
            child: OrgDocumentWidget(doc),
          ),
        );
        await tester.pumpWidget(wrap(widget));
        final controller =
            OrgController.of(tester.element(find.textContaining('foo')));
        expect(controller.searchResultKeys.value.length, 1);
      });
      testWidgets('Multiple results', (tester) async {
        final doc = OrgDocument.parse('foo bar baz');
        final widget = OrgController(
          root: doc,
          searchQuery: RegExp('ba[rz]'),
          child: OrgRootWidget(
            child: OrgDocumentWidget(doc),
          ),
        );
        await tester.pumpWidget(wrap(widget));
        final controller =
            OrgController.of(tester.element(find.textContaining('foo')));
        expect(controller.searchResultKeys.value.length, 2);
      });
    });
    group('Visibility', () {
      testWidgets('No query', (tester) async {
        final doc = OrgDocument.parse('''foo1
* bar
foo2
** baz
foo3''');
        final widget = OrgController(
          root: doc,
          child: OrgRootWidget(
            child: OrgDocumentWidget(doc),
          ),
        );
        await tester.pumpWidget(wrap(widget));
        expect(find.textContaining('foo1'), findsOneWidget);
        expect(find.textContaining('foo2'), findsNothing);
        expect(find.textContaining('foo3'), findsNothing);
      });
      testWidgets('Nested hits', (tester) async {
        final doc = OrgDocument.parse('''foo1
* bar
foo2
** baz
foo3''');
        final widget = OrgController(
          root: doc,
          searchQuery: RegExp('foo[123]'),
          child: OrgRootWidget(
            child: OrgDocumentWidget(doc),
          ),
        );
        await tester.pumpWidget(wrap(widget));
        expect(find.textContaining('foo1'), findsOneWidget);
        expect(find.textContaining('foo2'), findsOneWidget);
        expect(find.textContaining('foo3'), findsOneWidget);
      });
    });
  });
}
