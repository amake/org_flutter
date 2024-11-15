import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import './util.dart';

void main() {
  test('create widget', () {
    const Org('foo');
  });
  group('Org widget', () {
    testWidgets('Simple', (tester) async {
      await tester.pumpWidget(wrap(const Org('foo bar')));
      expect(find.text('foo bar'), findsOneWidget);
    });
  });
  group('OrgText widget', () {
    testWidgets('Simple', (tester) async {
      await tester.pumpWidget(wrap(const OrgText('foo bar')));
      expect(find.text('foo bar'), findsOneWidget);
    });
  });
}
