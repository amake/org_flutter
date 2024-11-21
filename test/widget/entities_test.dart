import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import './util.dart';

void main() {
  group('Entities', () {
    testWidgets('Custom', (tester) async {
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
      await tester.pumpWidget(wrap(widget));
      expect(find.textContaining('foo \u{1f34d} bar'), findsOneWidget);
    });
    testWidgets('Enabled', (tester) async {
      final doc = OrgDocument.parse(r'''
foo \smiley bar^{2} baz_buzz

# Local Variables:
# org-pretty-entities: t
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
      expect(find.textContaining('☺'), findsOneWidget);
      expect(find.textContaining('foo'), findsOneWidget);
      expect(find.textContaining('^{2}'), findsNothing);
      expect(find.textContaining('2'), findsOneWidget);
      expect(find.textContaining('baz_buzz'), findsNothing);
      expect(find.textContaining('baz'), findsOneWidget);
      expect(find.textContaining('buzz'), findsOneWidget);
    });
    testWidgets('Disabled', (tester) async {
      final doc = OrgDocument.parse(r'''
foo \smiley bar^{2} baz_buzz

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
      await tester.pumpWidget(wrap(widget));
      expect(find.textContaining('☺'), findsNothing);
      expect(find.textContaining('foo'), findsOneWidget);
      expect(find.textContaining('^{2}'), findsOneWidget);
      expect(find.textContaining('baz_buzz'), findsOneWidget);
    });
    testWidgets('Sub/superscripts disabled', (tester) async {
      final doc = OrgDocument.parse(r'''
foo \smiley bar^{2} baz_buzz

# Local Variables:
# org-pretty-entities: t
# org-pretty-entities-include-sub-superscripts: nil
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
      expect(find.textContaining('☺'), findsOneWidget);
      expect(find.textContaining('foo'), findsOneWidget);
      expect(find.textContaining('^{2}'), findsOneWidget);
      expect(find.textContaining('baz_buzz'), findsOneWidget);
    });
    testWidgets('Sub/superscripts disabled', (tester) async {
      final doc = OrgDocument.parse(r'''
foo \smiley bar^{2} baz_buzz

# Local Variables:
# org-pretty-entities: t
# org-use-sub-superscripts: {}
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
      expect(find.textContaining('foo'), findsOneWidget);
      expect(find.textContaining('^{2}'), findsNothing);
      expect(find.textContaining('☺'), findsOneWidget);
      expect(find.textContaining('baz_buzz'), findsOneWidget);
    });
  });
}

/* Put a pagebreak here so Emacs doesn't bother us about the Local Variables
lists in the tests

*/
