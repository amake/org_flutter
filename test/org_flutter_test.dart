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
    });
  });
}

/* Put a pagebreak here so Emacs doesn't bother us about the Local Variables
lists in the tests

*/
