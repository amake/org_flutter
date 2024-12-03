import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import 'util.dart';

void main() {
  group('Radio links', () {
    testWidgets('Keys', (tester) async {
      final doc =
          OrgDocument.parse('<<<foo>>>', interpretEmbeddedSettings: true);
      final widget = OrgController(
        root: doc,
        errorHandler: (e) {
          fail(e.toString());
        },
        child: OrgLocator(
          child: OrgRootWidget(
            child: OrgDocumentWidget(doc),
          ),
        ),
      );
      await tester.pumpWidget(wrap(widget));
      final locator =
          OrgLocator.of(tester.element(find.textContaining('foo')))!;
      expect(locator.radioTargetKeys.value.length, 1);
    });
    testWidgets('Visibility', (tester) async {
      final doc = OrgDocument.parse('''
FOO

* bar baz
bazinga
<<<foo>>>''', interpretEmbeddedSettings: true);
      final widget = OrgController(
        root: doc,
        errorHandler: (e) {
          fail(e.toString());
        },
        child: OrgLocator(
          child: OrgRootWidget(
            child: OrgDocumentWidget(doc),
          ),
        ),
      );
      await tester.pumpWidget(wrap(widget));

      expect(find.textContaining('bazinga'), findsNothing);
      await tester.tapOnText(find.textRange.ofSubstring('FOO'));
      await tester.pumpAndSettle();
      expect(find.textContaining('bazinga'), findsOneWidget);
    });
  });
}
