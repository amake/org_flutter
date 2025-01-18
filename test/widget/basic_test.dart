import 'dart:io';

import 'package:flutter/material.dart';
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
    testWidgets('Big', (tester) async {
      final markup = File('test/widget/org-manual.org').readAsStringSync();
      await tester.pumpWidget(wrap(Org(markup)));
      expect(find.textContaining('The Org Manual'), findsOneWidget);
    });
    testWidgets('Screenshot', (tester) async {
      final markup = File('test/widget/org-manual.org').readAsStringSync();
      final key = ValueKey('test');
      await tester.pumpWidget(SingleChildScrollView(
        child: RepaintBoundary(
          key: key,
          child: wrap(
            OrgText(
              markup,
              settings: OrgSettings(
                startupFolded: OrgVisibilityState.subtree,
                reflowText: true,
              ),
            ),
          ),
        ),
      ));
      const goldDir = String.fromEnvironment('GOLD_DIR', defaultValue: '.');
      await expectLater(
        find.byKey(key),
        matchesGoldenFile('$goldDir/org-manual.png'),
      );
      // This is very slow and only good for manual checks, so we skip it. Run
      // with `make screenshot`.
    }, skip: true);
  });
  group('OrgText widget', () {
    testWidgets('Simple', (tester) async {
      await tester.pumpWidget(wrap(const OrgText('foo bar')));
      expect(find.text('foo bar'), findsOneWidget);
    });
    testWidgets('Big', (tester) async {
      final markup = File('test/widget/org-manual.org').readAsStringSync();
      await tester.pumpWidget(wrap(OrgText(markup)));
      expect(find.textContaining('The Org Manual'), findsOneWidget);
    });
  });
}
