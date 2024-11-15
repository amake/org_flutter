import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import './util.dart';

void main() {
  group('Keyword settings', () {
    testWidgets('Blocks start closed', (tester) async {
      final doc = OrgDocument.parse(r'''
#+begin_example
foo bar
#+end_example

#+STARTUP: hideblocks
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
      expect(find.textContaining('foo bar'), findsNothing);
    });
    testWidgets('Blocks start open', (tester) async {
      final doc = OrgDocument.parse(r'''
#+begin_example
foo bar
#+end_example

#+STARTUP: nohideblocks
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
      expect(find.textContaining('foo bar'), findsOneWidget);
    });
    testWidgets('Drawers start open', (tester) async {
      final doc = OrgDocument.parse(r'''
:PROPERTIES:
:foo: bar
:END:

#+STARTUP: nohidedrawers
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
      expect(find.textContaining(':foo: bar'), findsOneWidget);
    });
    testWidgets('Drawers start closed', (tester) async {
      final doc = OrgDocument.parse(r'''
:PROPERTIES:
:foo: bar
:END:

#+STARTUP: hidedrawers
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
      expect(find.textContaining(':foo: bar'), findsNothing);
    });
    testWidgets('Sections start open', (tester) async {
      final doc = OrgDocument.parse(r'''
foo

* bar
  baz
#+STARTUP: showeverything
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
      expect(find.textContaining('baz'), findsOneWidget);
    });
    testWidgets('Sections start closed', (tester) async {
      final doc = OrgDocument.parse(r'''
foo

* bar
  baz
#+STARTUP: overview
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
      expect(find.textContaining('baz'), findsNothing);
    });
    testWidgets('Showeverything overrides hideblocks, hidedrawers',
        (tester) async {
      final doc = OrgDocument.parse(r'''
:PROPERTIES:
:foo: bar
:END:

#+begin_example
biz baz
#+end_example

#+STARTUP: showeverything hideblocks hidedrawers
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
      expect(find.textContaining(':foo: bar'), findsOneWidget);
      expect(find.textContaining('biz baz'), findsOneWidget);
    });
    testWidgets('Hide stars', (tester) async {
      final doc = OrgDocument.parse(r'''
* foo
** bar
*** baz

#+STARTUP: showeverything hidestars
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
      expect(find.textContaining('* foo'), findsOneWidget);
      expect(find.textContaining('** bar'), findsNothing);
      expect(find.textContaining(' * bar'), findsOneWidget);
      expect(find.textContaining('*** baz'), findsNothing);
      expect(find.textContaining('  * baz'), findsOneWidget);
    });
    testWidgets('Disable entities', (tester) async {
      final doc = OrgDocument.parse(r'''
foo \smiley bar^{2} baz_\alpha

#+STARTUP: entitiesplain
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
      expect(find.textContaining('foo'), findsOneWidget);
      expect(find.textContaining('^{2}'), findsOneWidget);
      expect(find.textContaining(r'_\alpha'), findsOneWidget);
      expect(find.textContaining('☺'), findsNothing);
    });
    testWidgets('Disable inline images', (tester) async {
      final doc = OrgDocument.parse(r'''
file:./foo.png

#+STARTUP: noinlineimages
''');
      final widget = OrgController(
        root: doc,
        interpretEmbeddedSettings: true,
        errorHandler: (e) {
          fail(e.toString());
        },
        child: OrgRootWidget(
          loadImage: (_) => fail('Should not be invoked'),
          child: OrgDocumentWidget(doc),
        ),
      );
      await tester.pumpWidget(wrap(widget));
    });
  });
}
