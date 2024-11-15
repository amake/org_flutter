import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import './util.dart';

void main() {
  group('State restoration', () {
    testWidgets('No restoration ID', (tester) async {
      await tester.pumpWidget(RootRestorationScope(
        restorationId: 'root',
        child: wrap(const Org('''
foo bar
* headline 1
baz buzz
** headline 2
bazinga''')),
      ));
      expect(find.text('foo bar'), findsOneWidget);
      await tester.tap(find.byType(OrgHeadlineWidget).first);
      await tester.pump();
      expect(find.text('foo bar'), findsOneWidget);
      expect(find.text('baz buzz'), findsOneWidget);
      expect(find.textContaining('headline 2'), findsOneWidget);
      expect(find.text('bazinga'), findsNothing);
      await tester.restartAndRestore();
      expect(find.text('foo bar'), findsOneWidget);
      expect(find.text('baz buzz'), findsNothing);
      expect(find.textContaining('headline 2'), findsNothing);
      expect(find.text('bazinga'), findsNothing);
    });
    testWidgets('Restores section visibility', (tester) async {
      await tester.pumpWidget(RootRestorationScope(
        restorationId: 'root',
        child: wrap(const Org(
          '''
foo bar
* headline 1
baz buzz
** headline 2
bazinga''',
          restorationId: 'doc',
        )),
      ));
      expect(find.text('foo bar'), findsOneWidget);
      await tester.tap(find.byType(OrgHeadlineWidget).first);
      await tester.pump();
      expect(find.text('foo bar'), findsOneWidget);
      expect(find.text('baz buzz'), findsOneWidget);
      expect(find.textContaining('headline 2'), findsOneWidget);
      expect(find.text('bazinga'), findsNothing);
      await tester.restartAndRestore();
      expect(find.text('foo bar'), findsOneWidget);
      expect(find.text('baz buzz'), findsOneWidget);
      expect(find.textContaining('headline 2'), findsOneWidget);
      expect(find.text('bazinga'), findsNothing);
    });
    testWidgets('Ignores search on restore', (tester) async {
      final doc = OrgDocument.parse('''foo bar
* headline 1
baz buzz
** headline 2
bazinga''');
      final widget = OrgController(
        root: doc,
        searchQuery: RegExp('baz'),
        restorationId: 'doc',
        child: OrgRootWidget(
          child: OrgDocumentWidget(doc),
        ),
      );
      await tester.pumpWidget(RootRestorationScope(
        restorationId: 'root',
        child: wrap(widget),
      ));
      expect(find.text('foo bar'), findsOneWidget);
      expect(find.textContaining('buzz'), findsOneWidget);
      expect(find.textContaining('headline 2'), findsOneWidget);
      expect(find.textContaining('inga'), findsOneWidget);
      await tester.tap(find.byType(OrgHeadlineWidget).last);
      await tester.pumpAndSettle();
      expect(find.text('foo bar'), findsOneWidget);
      expect(find.textContaining('buzz'), findsOneWidget);
      expect(find.textContaining('headline 2'), findsOneWidget);
      expect(find.textContaining('inga'), findsNothing);
      await tester.restartAndRestore();
      expect(find.text('foo bar'), findsOneWidget);
      expect(find.textContaining('buzz'), findsOneWidget);
      expect(find.textContaining('headline 2'), findsOneWidget);
      expect(find.textContaining('inga'), findsNothing);
    });
    testWidgets('Ignores filter on restore', (tester) async {
      final doc = OrgDocument.parse('''foo bar
* headline 1
baz buzz
** headline 2 :abcd:
bazinga''');
      final widget = OrgController(
        root: doc,
        sparseQuery: const OrgQueryTagMatcher('abcd'),
        restorationId: 'doc',
        child: OrgRootWidget(
          child: OrgDocumentWidget(doc),
        ),
      );
      await tester.pumpWidget(RootRestorationScope(
        restorationId: 'root',
        child: wrap(widget),
      ));
      expect(find.text('foo bar'), findsOneWidget);
      expect(find.text('baz buzz'), findsNothing);
      expect(find.textContaining('headline 2'), findsOneWidget);
      expect(find.text('bazinga'), findsNothing);
      await tester.tap(find.byType(OrgHeadlineWidget).last);
      await tester.pumpAndSettle();
      expect(find.text('foo bar'), findsOneWidget);
      expect(find.text('baz buzz'), findsNothing);
      expect(find.textContaining('headline 2'), findsOneWidget);
      expect(find.text('bazinga'), findsOneWidget);
      await tester.restartAndRestore();
      expect(find.text('foo bar'), findsOneWidget);
      expect(find.text('baz buzz'), findsNothing);
      expect(find.textContaining('headline 2'), findsOneWidget);
      expect(find.text('bazinga'), findsOneWidget);
    });
  });
}
