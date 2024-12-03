import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import 'util.dart';

void main() {
  group('Link target', () {
    testWidgets('Keys', (tester) async {
      await tester.pumpWidget(wrap(const Org('''
<<foo>>
''')));
      final locator =
          OrgLocator.of(tester.element(find.textContaining('foo')))!;
      expect(locator.linkTargetKeys.value.length, 1);
    });
    testWidgets('Visibility', (tester) async {
      await tester.pumpWidget(wrap(const Org('''
* bar baz
<<foo>>''')));
      expect(find.textContaining('foo'), findsNothing);
      final locator =
          OrgLocator.of(tester.element(find.textContaining('bar')))!;
      locator.jumpToLinkTarget('foo');
      await tester.pumpAndSettle();
      expect(find.textContaining('foo'), findsOneWidget);
    });
  });
}
