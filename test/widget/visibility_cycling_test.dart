import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import './util.dart';

void main() {
  group('Visibility cycling', () {
    testWidgets('Headline tap', (tester) async {
      await tester.pumpWidget(wrap(const Org('''
foo bar
* headline
baz buzz''')));
      expect(find.text('foo bar'), findsOneWidget);
      expect(find.text('baz buzz'), findsNothing);
      await tester.tap(find.byType(OrgHeadlineWidget));
      await tester.pump();
      expect(find.text('baz buzz'), findsOneWidget);
    });
    testWidgets('Nested sections headline tap', (tester) async {
      await tester.pumpWidget(wrap(const Org('''
foo bar
* headline 1
baz buzz
** headline 2
bazinga''')));
      expect(find.text('foo bar'), findsOneWidget);
      expect(find.text('baz buzz'), findsNothing);
      expect(find.textContaining('headline 2'), findsNothing);
      expect(find.text('bazinga'), findsNothing);
      await tester.tap(find.byType(OrgHeadlineWidget).first);
      await tester.pump();
      expect(find.text('baz buzz'), findsOneWidget);
      expect(find.textContaining('headline 2'), findsOneWidget);
      expect(find.text('bazinga'), findsNothing);
      await tester.tap(find.byType(OrgHeadlineWidget).first);
      await tester.pump();
      expect(find.text('bazinga'), findsOneWidget);
    });
    testWidgets('Whole document', (tester) async {
      await tester.pumpWidget(wrap(const Org('''
foo bar
* headline 1
baz buzz
** headline 2
bazinga''')));
      expect(find.text('foo bar'), findsOneWidget);
      expect(find.text('baz buzz'), findsNothing);
      expect(find.textContaining('headline 2'), findsNothing);
      expect(find.text('bazinga'), findsNothing);
      final controller =
          OrgController.of(tester.element(find.textContaining('foo bar')));
      controller.cycleVisibility();
      await tester.pump();
      expect(find.text('baz buzz'), findsNothing);
      expect(find.text('bazinga'), findsNothing);
      expect(find.textContaining('headline 2'), findsOneWidget);
      controller.cycleVisibility();
      await tester.pump();
      expect(find.text('baz buzz'), findsOneWidget);
      expect(find.text('bazinga'), findsOneWidget);
      expect(find.textContaining('headline 2'), findsOneWidget);
    });
    group('Archived sections', () {
      testWidgets('Global cycling', (tester) async {
        await tester.pumpWidget(wrap(const Org('''
foo bar
* headline 1 :archive:
baz buzz
* headline 2
borz burz
** headline 3 :ARCHIVE:
bazinga
* headline 4 :ARCHIVE:
bazonga''')));
        expect(find.text('foo bar'), findsOneWidget);
        expect(find.textContaining('headline 1'), findsOneWidget);
        expect(find.text('baz buzz'), findsNothing);
        expect(find.textContaining('headline 2'), findsOneWidget);
        expect(find.text('borz burz'), findsNothing);
        expect(find.textContaining('headline 3'), findsNothing);
        expect(find.text('bazinga'), findsNothing);
        expect(find.textContaining('headline 4'), findsOneWidget);
        expect(find.text('bazonga'), findsNothing);
        final controller =
            OrgController.of(tester.element(find.textContaining('foo bar')));
        controller.cycleVisibility();
        await tester.pump();
        expect(find.text('foo bar'), findsOneWidget);
        expect(find.textContaining('headline 1'), findsOneWidget);
        expect(find.text('baz buzz'), findsNothing);
        expect(find.textContaining('headline 2'), findsOneWidget);
        expect(find.text('borz burz'), findsNothing);
        expect(find.textContaining('headline 3'), findsOneWidget);
        expect(find.text('bazinga'), findsNothing);
        expect(find.textContaining('headline 4'), findsOneWidget);
        expect(find.text('bazonga'), findsNothing);
        controller.cycleVisibility();
        await tester.pump();
        expect(find.text('foo bar'), findsOneWidget);
        expect(find.textContaining('headline 1'), findsOneWidget);
        // ARCHIVE is case-sensitive so :archive: has no effect
        expect(find.text('baz buzz'), findsOneWidget);
        expect(find.textContaining('headline 2'), findsOneWidget);
        expect(find.text('borz burz'), findsOneWidget);
        expect(find.textContaining('headline 3'), findsOneWidget);
        expect(find.text('bazinga'), findsNothing);
        expect(find.textContaining('headline 4'), findsOneWidget);
        expect(find.text('bazonga'), findsNothing);
      });
      testWidgets('Tap cycling', (tester) async {
        await tester.pumpWidget(wrap(const Org('''
foo bar
* headline 1 :ARCHIVE:
baz buzz
** headline 2
borz burz
** headline 3 :ARCHIVE:
bazinga''')));
        expect(find.text('foo bar'), findsOneWidget);
        expect(find.textContaining('headline 1'), findsOneWidget);
        expect(find.text('baz buzz'), findsNothing);
        expect(find.textContaining('headline 2'), findsNothing);
        expect(find.text('borz burz'), findsNothing);
        expect(find.textContaining('headline 3'), findsNothing);
        expect(find.text('bazinga'), findsNothing);
        await tester.tap(find.byType(OrgHeadlineWidget).first);
        await tester.pump();
        expect(find.text('foo bar'), findsOneWidget);
        expect(find.textContaining('headline 1'), findsOneWidget);
        expect(find.text('baz buzz'), findsOneWidget);
        expect(find.textContaining('headline 2'), findsOneWidget);
        expect(find.text('borz burz'), findsNothing);
        expect(find.textContaining('headline 3'), findsOneWidget);
        expect(find.text('bazinga'), findsNothing);
        await tester.tap(find.byType(OrgHeadlineWidget).first);
        await tester.pump();
        expect(find.text('foo bar'), findsOneWidget);
        expect(find.textContaining('headline 1'), findsOneWidget);
        expect(find.text('baz buzz'), findsOneWidget);
        expect(find.textContaining('headline 2'), findsOneWidget);
        expect(find.text('borz burz'), findsOneWidget);
        expect(find.textContaining('headline 3'), findsOneWidget);
        expect(find.text('bazinga'), findsNothing);
      });
    });
    testWidgets('Drawer', (tester) async {
      await tester.pumpWidget(wrap(const Org('''
:PROPERTIES:
:foo: bar
:END:''')));
      expect(find.text(':foo: bar'), findsNothing);
      await tester.tap(find.text(':PROPERTIES:...'));
      await tester.pump();
      expect(find.text(':PROPERTIES:...'), findsNothing);
      expect(find.text(':foo: bar'), findsOneWidget);
      expect(find.text(':END:'), findsOneWidget);
    });
    testWidgets('Block', (tester) async {
      await tester.pumpWidget(wrap(const Org('''#+begin_example
  foo bar
#+end_example''')));
      expect(find.textContaining('foo bar'), findsOneWidget);
      expect(find.text('#+end_example'), findsOneWidget);
      await tester.tap(find.text('#+begin_example'));
      await tester.pumpAndSettle();
      expect(find.textContaining('#+begin_example...'), findsOneWidget);
      expect(find.textContaining('foo bar'), findsNothing);
      expect(find.textContaining('#+end_example'), findsNothing);
    });
  });
}
