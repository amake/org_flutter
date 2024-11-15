import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import './util.dart';

void main() {
  group('Not reflowed', () {
    group('Headline closed', () {
      testWidgets('Empty, no tags', (tester) async {
        await tester.pumpWidget(wrap(const Org('* foo bar')));
        expect(find.textContaining('foo bar'), findsOneWidget);
        expect(find.textContaining('...'), findsNothing);
      });
      testWidgets('Empty with tags', (tester) async {
        await tester.pumpWidget(wrap(const Org('* foo bar  :tag:')));
        expect(find.textContaining('foo bar'), findsOneWidget);
        expect(find.textContaining(':tag:'), findsOneWidget);
        expect(find.textContaining('...'), findsNothing);
      });
      testWidgets('Contentful, no tags', (tester) async {
        await tester.pumpWidget(wrap(const Org('''* foo bar
content''')));
        expect(find.textContaining('foo bar'), findsOneWidget);
        expect(find.textContaining('content'), findsNothing);
        expect(find.textContaining('...'), findsOneWidget);
      });
      testWidgets('Contentful with tags', (tester) async {
        await tester.pumpWidget(wrap(const Org('''* foo bar  :tag:
content''')));
        expect(find.textContaining('foo bar'), findsOneWidget);
        expect(find.textContaining(':tag:'), findsOneWidget);
        expect(find.textContaining('content'), findsNothing);
        expect(find.textContaining('...'), findsOneWidget);
      });
    });
    group('Headline open', () {
      const settings = OrgSettings(startupFolded: OrgVisibilityState.subtree);
      testWidgets('Empty, no tags', (tester) async {
        await tester
            .pumpWidget(wrap(const Org('* foo bar', settings: settings)));
        expect(find.textContaining('foo bar'), findsOneWidget);
        expect(find.textContaining('...'), findsNothing);
      });
      testWidgets('Empty with tags', (tester) async {
        await tester.pumpWidget(
            wrap(const Org('* foo bar  :tag:', settings: settings)));
        expect(find.textContaining('foo bar'), findsOneWidget);
        expect(find.textContaining(':tag:'), findsOneWidget);
        expect(find.textContaining('...'), findsNothing);
      });
      testWidgets('Contentful, no tags', (tester) async {
        await tester.pumpWidget(wrap(const Org('''* foo bar
content''', settings: settings)));
        expect(find.textContaining('foo bar'), findsOneWidget);
        expect(find.textContaining('...'), findsNothing);
        expect(find.textContaining('content'), findsOneWidget);
      });
      testWidgets('Contentful with tags', (tester) async {
        await tester.pumpWidget(wrap(const Org('''* foo bar  :tag:
content''', settings: settings)));
        expect(find.textContaining('foo bar'), findsOneWidget);
        expect(find.textContaining(':tag:'), findsOneWidget);
        expect(find.textContaining('content'), findsOneWidget);
        expect(find.textContaining('...'), findsNothing);
      });
    });
  });
  group('Reflowed', () {
    const baseSettings = OrgSettings(reflowText: true);
    group('Headline closed', () {
      testWidgets('Empty, no tags', (tester) async {
        await tester
            .pumpWidget(wrap(const Org('* foo bar', settings: baseSettings)));
        expect(find.textContaining('foo bar'), findsOneWidget);
        expect(find.textContaining('...'), findsNothing);
      });
      testWidgets('Empty with tags', (tester) async {
        await tester.pumpWidget(
            wrap(const Org('* foo bar  :tag:', settings: baseSettings)));
        expect(find.textContaining('foo bar'), findsOneWidget);
        expect(find.textContaining(':tag:'), findsOneWidget);
        expect(find.textContaining('...'), findsNothing);
      });
      testWidgets('Contentful, no tags', (tester) async {
        await tester.pumpWidget(wrap(const Org('''* foo bar
content''', settings: baseSettings)));
        expect(find.textContaining('foo bar'), findsOneWidget);
        expect(find.textContaining('content'), findsNothing);
        expect(find.textContaining('...'), findsOneWidget);
      });
      testWidgets('Contentful with tags', (tester) async {
        await tester.pumpWidget(wrap(const Org('''* foo bar  :tag:
content''', settings: baseSettings)));
        expect(find.textContaining('foo bar'), findsOneWidget);
        expect(find.textContaining(':tag:'), findsOneWidget);
        expect(find.textContaining('content'), findsNothing);
        expect(find.textContaining('...'), findsOneWidget);
      });
    });
    group('Headline open', () {
      final settings =
          baseSettings.copyWith(startupFolded: OrgVisibilityState.subtree);
      testWidgets('Empty, no tags', (tester) async {
        await tester.pumpWidget(wrap(Org('* foo bar', settings: settings)));
        expect(find.textContaining('foo bar'), findsOneWidget);
        expect(find.textContaining('...'), findsNothing);
      });
      testWidgets('Empty with tags', (tester) async {
        await tester
            .pumpWidget(wrap(Org('* foo bar  :tag:', settings: settings)));
        expect(find.textContaining('foo bar'), findsOneWidget);
        expect(find.textContaining(':tag:'), findsOneWidget);
        expect(find.textContaining('...'), findsNothing);
      });
      testWidgets('Contentful, no tags', (tester) async {
        await tester.pumpWidget(wrap(Org('''* foo bar
content''', settings: settings)));
        expect(find.textContaining('foo bar'), findsOneWidget);
        expect(find.textContaining('...'), findsNothing);
        expect(find.textContaining('content'), findsOneWidget);
      });
      testWidgets('Contentful with tags', (tester) async {
        await tester.pumpWidget(wrap(Org('''* foo bar  :tag:
content''', settings: settings)));
        expect(find.textContaining('foo bar'), findsOneWidget);
        expect(find.textContaining(':tag:'), findsOneWidget);
        expect(find.textContaining('content'), findsOneWidget);
        expect(find.textContaining('...'), findsNothing);
      });
    });
  });
}
