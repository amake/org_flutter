import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import './util.dart';

void main() {
  group('Meta', () {
    testWidgets('Non-exported', (tester) async {
      await tester
          .pumpWidget(wrap(const Org(r'#+FOO: foo^1 bar^{2} baz_3 buzz_{4}')));
      expect(find.textContaining('^1'), findsOneWidget);
      expect(find.textContaining('2'), findsOneWidget);
      expect(find.textContaining('{2}'), findsNothing);
      expect(find.textContaining('_3'), findsOneWidget);
      expect(find.textContaining('4'), findsOneWidget);
      expect(find.textContaining('{4}'), findsNothing);
    });
    testWidgets('Exported', (tester) async {
      await tester.pumpWidget(
          wrap(const Org(r'#+CAPTION: foo^1 bar^{2} baz_3 buzz_{4}')));
      expect(find.textContaining('1'), findsOneWidget);
      expect(find.textContaining('^1'), findsNothing);
      expect(find.textContaining('2'), findsOneWidget);
      expect(find.textContaining('{2}'), findsNothing);
      expect(find.textContaining('3'), findsOneWidget);
      expect(find.textContaining('_3'), findsNothing);
      expect(find.textContaining('4'), findsOneWidget);
      expect(find.textContaining('{4}'), findsNothing);
    });
    testWidgets('Hidden', (tester) async {
      final doc = OrgDocument.parse(r'''
#+TITLE: A very good doc
#+SUBTITLE: The foo story
#+AUTHOR: That Guy
#+EMAIL: thatguy@example.com
#+DATE: 2024-11-05
#+FOO: a regular meta line

#+title: a VERY GOOD DOC

# Local Variables:
# org-hidden-keywords: (title subtitle foo)
# End:
''');
      final widget = OrgController(
        root: doc,
        interpretEmbeddedSettings: true,
        errorHandler: (e) {
          fail(e.toString());
        },
        child: OrgRootWidget(
          child: OrgDocumentWidget(doc),
        ),
      );
      await tester.pumpWidget(wrap(widget));
      expect(find.textContaining('A very good doc'), findsOneWidget);
      expect(find.textContaining('#+TITLE:'), findsNothing);
      expect(find.textContaining('The foo story'), findsOneWidget);
      expect(find.textContaining('#+SUBTITLE:'), findsNothing);
      expect(find.textContaining('That Guy'), findsOneWidget);
      expect(find.textContaining('#+AUTHOR:'), findsOneWidget);
      expect(find.textContaining('#+FOO:'), findsOneWidget);
      expect(find.textContaining('a regular meta line'), findsOneWidget);
      expect(find.textContaining('a VERY GOOD DOC'), findsOneWidget);
      expect(find.textContaining('#+title:'), findsNothing);
    });
  });
}
