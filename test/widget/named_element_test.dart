import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import 'util.dart';

void main() {
  group('Named element', () {
    testWidgets('Keys', (tester) async {
      await tester.pumpWidget(wrap(const Org('''
#+name: foo
#+NAME: bar
''')));
      final locator =
          OrgLocator.of(tester.element(find.textContaining('foo')))!;
      expect(locator.nameKeys.value.length, 2);
    });
    testWidgets('Visibility', (tester) async {
      await tester.pumpWidget(wrap(const Org('''
* bar baz
#+NAME: foo''')));
      expect(find.textContaining('foo'), findsNothing);
      final locator =
          OrgLocator.of(tester.element(find.textContaining('bar')))!;
      locator.jumpToName('foo');
      await tester.pumpAndSettle();
      expect(find.textContaining('foo'), findsOneWidget);
    });
  });
}
