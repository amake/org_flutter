import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import './util.dart';

void main() {
  group('org-attach-id-dir', () {
    testWidgets('Detects valid', (tester) async {
      final doc = OrgDocument.parse(r'''
foo *bar* baz

# Local Variables:
# org-attach-id-dir: "../foo"
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
      final settings =
          OrgSettings.of(tester.element(find.byType(OrgRootWidget)));
      expect(settings.settings.orgAttachIdDir, '../foo');
    });
    testWidgets('Ignores invalid', (tester) async {
      final doc = OrgDocument.parse(r'''
foo *bar* baz

# Local Variables:
# org-attach-id-dir: foo
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
      final settings =
          OrgSettings.of(tester.element(find.byType(OrgRootWidget)));
      expect(settings.settings.orgAttachIdDir, 'data');
    });
  });
}

/* Put a pagebreak here so Emacs doesn't bother us about the Local Variables
lists in the tests

*/
