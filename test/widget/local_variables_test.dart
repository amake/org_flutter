import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import './util.dart';

void main() {
  group('Local variables', () {
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
      await tester.pumpWidget(wrap(widget));
      expect(find.textContaining('foo bar baz'), findsOneWidget);
      expect(find.textContaining('foo *bar* baz'), findsNothing);
    });
  });
}

/* Put a pagebreak here so Emacs doesn't bother us about the Local Variables
lists in the tests

*/
