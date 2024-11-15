import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import 'util.dart';

void main() {
  group('Section matcher', () {
    testWidgets('Keyword', (tester) async {
      final doc = OrgDocument.parse('''foo1
* foo
** TODO bar
foo2
** DONE baz
foo3''');
      final widget = OrgController(
        root: doc,
        sparseQuery: OrgQueryMatcher.fromMarkup('TODO="TODO"'),
        child: OrgRootWidget(
          child: OrgDocumentWidget(doc),
        ),
      );
      await tester.pumpWidget(wrap(widget));
      expect(find.textContaining('foo1'), findsOneWidget);
      expect(find.textContaining('bar'), findsOneWidget);
      expect(find.textContaining('foo2'), findsNothing);
      expect(find.textContaining('foo3'), findsNothing);
    });
    testWidgets('Tag', (tester) async {
      final doc = OrgDocument.parse('''foo1
* foo
** bar
foo2
** baz :buzz:
foo3''');
      final widget = OrgController(
        root: doc,
        sparseQuery: const OrgQueryTagMatcher('buzz'),
        child: OrgRootWidget(
          child: OrgDocumentWidget(doc),
        ),
      );
      await tester.pumpWidget(wrap(widget));
      expect(find.textContaining('foo1'), findsOneWidget);
      expect(find.textContaining('foo2'), findsNothing);
      expect(find.textContaining('baz'), findsOneWidget);
      expect(find.textContaining('foo3'), findsNothing);
    });
    group('With search', () {
      testWidgets('With hit', (tester) async {
        final doc = OrgDocument.parse('''foo1
* foo
** TODO bar
foo2
** DONE baz
foo3''');
        final widget = OrgController(
          root: doc,
          sparseQuery: OrgQueryMatcher.fromMarkup('TODO="TODO"'),
          searchQuery: 'foo2',
          child: OrgRootWidget(
            child: OrgDocumentWidget(doc),
          ),
        );
        await tester.pumpWidget(wrap(widget));
        expect(find.textContaining('foo1'), findsOneWidget);
        expect(find.textContaining('bar'), findsOneWidget);
        expect(find.textContaining('foo2'), findsOneWidget);
        expect(find.textContaining('foo3'), findsNothing);
      });
      testWidgets('No hits', (tester) async {
        final doc = OrgDocument.parse('''foo1
* foo
** TODO bar
foo2
** DONE baz
foo3''');
        final widget = OrgController(
          root: doc,
          sparseQuery: OrgQueryMatcher.fromMarkup('TODO="TODO"'),
          searchQuery: 'foo3',
          child: OrgRootWidget(
            child: OrgDocumentWidget(doc),
          ),
        );
        await tester.pumpWidget(wrap(widget));
        expect(find.textContaining('foo1'), findsOneWidget);
        expect(find.textContaining('foo2'), findsNothing);
        expect(find.textContaining('foo3'), findsNothing);
      });
    });
  });
}
