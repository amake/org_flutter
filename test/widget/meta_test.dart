import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import './util.dart';

void main() {
  group('Meta', () {
    testWidgets('Non-exported', (tester) async {
      await tester
          .pumpWidget(wrap(const Org(r'#+FOO: foo^1 bar^{2} baz_3 buzz_{4}')));
      expect(find.textContaining('^1'), findsOneWidget);
      expect(find.textContaining('2'), findsOneWidget);
      expect(find.textContaining('{2}'), findsNothing);
      expect(find.textContaining('_3'), findsOneWidget);
      expect(find.textContaining('4'), findsOneWidget);
      expect(find.textContaining('{4}'), findsNothing);
    });
    testWidgets('Exported', (tester) async {
      await tester.pumpWidget(
          wrap(const Org(r'#+CAPTION: foo^1 bar^{2} baz_3 buzz_{4}')));
      expect(find.textContaining('1'), findsOneWidget);
      expect(find.textContaining('^1'), findsNothing);
      expect(find.textContaining('2'), findsOneWidget);
      expect(find.textContaining('{2}'), findsNothing);
      expect(find.textContaining('3'), findsOneWidget);
      expect(find.textContaining('_3'), findsNothing);
      expect(find.textContaining('4'), findsOneWidget);
      expect(find.textContaining('{4}'), findsNothing);
    });
  });
}
