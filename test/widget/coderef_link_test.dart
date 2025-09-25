import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import 'util.dart';

void main() {
  group('Coderef links', () {
    testWidgets('Keys', (tester) async {
      final doc = OrgDocument.parse('''
#+BEGIN_SRC emacs-lisp -n -r
  (save-excursion                 (ref:sc)
     (goto-char (point-min))      (ref:jump)
#+END_SRC
''');
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
          OrgLocator.of(tester.element(find.textContaining('save-excursion')))!;
      expect(locator.coderefKeys.value.length, 2);
    });
    testWidgets('Visibility', (tester) async {
      final doc = OrgDocument.parse('''
[[(jump)][FOO]]

* bar baz
#+BEGIN_SRC emacs-lisp -n -r
  (save-excursion                 (ref:sc)
     (goto-char (point-min))      (ref:jump)
#+END_SRC
''');
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

      expect(find.textContaining('save-excursion'), findsNothing);
      await tester.tapOnText(find.textRange.ofSubstring('FOO'));
      await tester.pumpAndSettle();
      expect(find.textContaining('save-excursion'), findsOneWidget);
    });
  });
}
