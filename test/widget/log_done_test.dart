import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import './util.dart';

void main() {
  group('Log done', () {
    testWidgets('Detects valid local var', (tester) async {
      final doc = OrgDocument.parse(r'''
* foo

# Local Variables:
# org-log-done: time
# End:
''');
      final widget = OrgController(
        root: doc,
        interpretEmbeddedSettings: true,
        errorHandler: (e) {
          fail(e.toString());
        },
        child: OrgRootWidget(child: OrgDocumentWidget(doc)),
      );
      await tester.pumpWidget(wrap(widget));
      final settings = OrgSettings.of(
        tester.element(find.byType(OrgRootWidget)),
      );
      expect(settings.settings.logDone, isTrue);
    });
    testWidgets('Ignores invalid local var', (tester) async {
      final doc = OrgDocument.parse(r'''
* foo

# Local Variables:
# org-log-done: foo
# End:
''');
      final widget = OrgController(
        root: doc,
        interpretEmbeddedSettings: true,
        errorHandler: (e) {
          fail(e.toString());
        },
        child: OrgRootWidget(child: OrgDocumentWidget(doc)),
      );
      await tester.pumpWidget(wrap(widget));
      final settings = OrgSettings.of(
        tester.element(find.byType(OrgRootWidget)),
      );
      expect(settings.settings.logDone, isFalse);
    });
    testWidgets('Detects startup keyword', (tester) async {
      final doc = OrgDocument.parse(r'''
* foo

#+STARTUP: logdone
''');
      final widget = OrgController(
        root: doc,
        interpretEmbeddedSettings: true,
        errorHandler: (e) {
          fail(e.toString());
        },
        child: OrgRootWidget(child: OrgDocumentWidget(doc)),
      );
      await tester.pumpWidget(wrap(widget));
      final settings = OrgSettings.of(
        tester.element(find.byType(OrgRootWidget)),
      );
      expect(settings.settings.logDone, isTrue);
    });
    testWidgets('Detects disabling startup keyword', (tester) async {
      final doc = OrgDocument.parse(r'''
* foo

#+STARTUP: logdone nologdone
''');
      final widget = OrgController(
        root: doc,
        interpretEmbeddedSettings: true,
        errorHandler: (e) {
          fail(e.toString());
        },
        child: OrgRootWidget(child: OrgDocumentWidget(doc)),
      );
      await tester.pumpWidget(wrap(widget));
      final settings = OrgSettings.of(
        tester.element(find.byType(OrgRootWidget)),
      );
      expect(settings.settings.logDone, isFalse);
    });
    testWidgets('Local variable beats startup keyword', (tester) async {
      final doc = OrgDocument.parse(r'''
* foo

#+STARTUP: logdone

# Local Variables:
# org-log-done: nil
# End:
''');
      final widget = OrgController(
        root: doc,
        interpretEmbeddedSettings: true,
        errorHandler: (e) {
          fail(e.toString());
        },
        child: OrgRootWidget(child: OrgDocumentWidget(doc)),
      );
      await tester.pumpWidget(wrap(widget));
      final settings = OrgSettings.of(
        tester.element(find.byType(OrgRootWidget)),
      );
      expect(settings.settings.logDone, isFalse);
    });
    testWidgets('Local variable beats startup keyword 2', (tester) async {
      final doc = OrgDocument.parse(r'''
* foo

#+STARTUP: nologdone

# Local Variables:
# org-log-done: time
# End:
''');
      final widget = OrgController(
        root: doc,
        interpretEmbeddedSettings: true,
        errorHandler: (e) {
          fail(e.toString());
        },
        child: OrgRootWidget(child: OrgDocumentWidget(doc)),
      );
      await tester.pumpWidget(wrap(widget));
      final settings = OrgSettings.of(
        tester.element(find.byType(OrgRootWidget)),
      );
      expect(settings.settings.logDone, isTrue);
    });
  });
}

/* Put a pagebreak here so Emacs doesn't bother us about the Local Variables
lists in the tests

*/
