import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

Widget _wrap(Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Material(child: child),
  );
}

void main() {
  test('create widget', () {
    const Org('foo');
  });
  group('Org widget', () {
    testWidgets('Simple', (tester) async {
      await tester.pumpWidget(_wrap(const Org('foo bar')));
      expect(find.text('foo bar'), findsOneWidget);
    });
    group('Visibility cycling', () {
      testWidgets('Section', (tester) async {
        await tester.pumpWidget(_wrap(const Org('''
foo bar
* headline
baz buzz''')));
        expect(find.text('foo bar'), findsOneWidget);
        expect(find.text('baz buzz'), findsNothing);
        await tester.tap(find.byType(OrgHeadlineWidget));
        await tester.pump();
        expect(find.text('baz buzz'), findsOneWidget);
      });
      testWidgets('Nested sections', (tester) async {
        await tester.pumpWidget(_wrap(const Org('''
foo bar
* headline 1
baz buzz
** headline 2
bazinga''')));
        expect(find.text('foo bar'), findsOneWidget);
        expect(find.text('baz buzz'), findsNothing);
        expect(find.text('bazinga'), findsNothing);
        await tester.tap(find.byType(OrgHeadlineWidget).first);
        await tester.pump();
        expect(find.text('baz buzz'), findsOneWidget);
        expect(find.text('bazinga'), findsNothing);
        await tester.tap(find.byType(OrgHeadlineWidget).first);
        await tester.pump();
        expect(find.text('bazinga'), findsOneWidget);
      });
    });
    group('Events', () {
      testWidgets('Load images', (tester) async {
        var invoked = false;
        await tester.pumpWidget(_wrap(Org(
          'file:./foo.png',
          loadImage: (link) {
            invoked = true;
            expect(link.location, 'file:./foo.png');
            return null;
          },
        )));
        expect(invoked, isTrue);
      });
    });
    group('Local variables', () {
      testWidgets('Custom entities', (tester) async {
        final doc = OrgDocument.parse(r'''
foo \pineapple bar

# Local Variables:
# org-entities-user: (("pineapple" "[p]" nil "&#127821;" "[p]" "[p]" "🍍"))
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
        await tester.pumpWidget(_wrap(widget));
        expect(find.textContaining('foo \u{1f34d} bar'), findsOneWidget);
      });
      testWidgets('Disable entities', (tester) async {
        final doc = OrgDocument.parse(r'''
foo \smiley bar

# Local Variables:
# org-pretty-entities: nil
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
        await tester.pumpWidget(_wrap(widget));
        expect(find.textContaining('foo'), findsOneWidget);
        expect(find.textContaining('☺'), findsNothing);
      });
      testWidgets('Hide markup', (tester) async {
        final doc = OrgDocument.parse(r'''
foo *bar* baz

# Local Variables:
# org-hide-emphasis-markers: t
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
        await tester.pumpWidget(_wrap(widget));
        expect(find.textContaining('foo bar baz'), findsOneWidget);
        expect(find.textContaining('foo *bar* baz'), findsNothing);
      });
    });
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
        await tester.pumpWidget(_wrap(widget));
        expect(find.textContaining('foo bar'), findsNothing);
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
        await tester.pumpWidget(_wrap(widget));
        expect(find.textContaining(':foo: bar'), findsOneWidget);
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
        await tester.pumpWidget(_wrap(widget));
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
        await tester.pumpWidget(_wrap(widget));
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
        await tester.pumpWidget(_wrap(widget));
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
        await tester.pumpWidget(_wrap(widget));
        expect(find.textContaining('* foo'), findsOneWidget);
        expect(find.textContaining('** bar'), findsNothing);
        expect(find.textContaining(' * bar'), findsOneWidget);
        expect(find.textContaining('*** baz'), findsNothing);
        expect(find.textContaining('  * baz'), findsOneWidget);
      });
      testWidgets('Disable entities', (tester) async {
        final doc = OrgDocument.parse(r'''
foo \smiley bar

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
        await tester.pumpWidget(_wrap(widget));
        expect(find.textContaining('foo'), findsOneWidget);
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
        await tester.pumpWidget(_wrap(widget));
      });
    });
  });
}

/* Put a pagebreak here so Emacs doesn't bother us about the Local Variables
lists in the tests

*/
