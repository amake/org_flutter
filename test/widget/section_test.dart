import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import 'util.dart';

void main() {
  group('Section', () {
    testWidgets('Keys', (tester) async {
      await tester.pumpWidget(
        wrap(
          const Org('''
* foo
'''),
        ),
      );
      final locator = OrgLocator.of(
        tester.element(find.textContaining('foo')),
      )!;
      expect(locator.headlineKeys.value.length, 1);
    });
    group('Visibility', () {
      testWidgets('By headline', (tester) async {
        await tester.pumpWidget(
          wrap(
            const Org('''
* foo
** bar baz'''),
          ),
        );
        expect(find.textContaining('bar baz'), findsNothing);
        final locator = OrgLocator.of(
          tester.element(find.textContaining('foo')),
        )!;
        locator.jumpToSection('*bar baz');
        await tester.pumpAndSettle();
        expect(find.textContaining('bar baz'), findsOneWidget);
      });
      testWidgets('By id', (tester) async {
        await tester.pumpWidget(
          wrap(
            const Org('''
* foo
** bar baz
:PROPERTIES:
:ID: bar-id
:END:'''),
          ),
        );
        expect(find.textContaining('bar baz'), findsNothing);
        final locator = OrgLocator.of(
          tester.element(find.textContaining('foo')),
        )!;
        locator.jumpToSection('id:bar-id');
        await tester.pumpAndSettle();
        expect(find.textContaining('bar baz'), findsOneWidget);
      });
      testWidgets('By id', (tester) async {
        await tester.pumpWidget(
          wrap(
            const Org('''
* foo
** bar baz
:PROPERTIES:
:CUSTOM_ID: bar-custom-id
:END:'''),
          ),
        );
        expect(find.textContaining('bar baz'), findsNothing);
        final locator = OrgLocator.of(
          tester.element(find.textContaining('foo')),
        )!;
        locator.jumpToSection('#bar-custom-id');
        await tester.pumpAndSettle();
        expect(find.textContaining('bar baz'), findsOneWidget);
      });
    });
  });
}
