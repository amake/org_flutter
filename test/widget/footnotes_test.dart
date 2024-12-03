import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import 'util.dart';

void main() {
  group('Footnotes', () {
    testWidgets('Keys', (tester) async {
      await tester.pumpWidget(wrap(const Org('''
foo[fn:1]

[fn:1] bar baz''')));
      final locator =
          OrgLocator.of(tester.element(find.textContaining('foo')))!;
      expect(locator.footnoteKeys.value.length, 2);
    });
    testWidgets('Visibility', (tester) async {
      await tester.pumpWidget(wrap(const Org('''
foo[fn:1]

* bar baz
[fn:1] bazinga''')));
      expect(find.textContaining('bazinga'), findsNothing);
      await tester.tap(find.textContaining('fn:1').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('bazinga'), findsOneWidget);
    });
  });
}
