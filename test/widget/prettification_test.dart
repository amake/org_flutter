import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import './util.dart';

void main() {
  testWidgets('Pretty', (tester) async {
    await tester.pumpWidget(wrap(const Org(r'foo \smiley bar^{2} baz_\alpha')));
    expect(find.textContaining('☺'), findsOneWidget);
    expect(find.textContaining(r'\smiley'), findsNothing);
    expect(find.textContaining('2'), findsOneWidget);
    expect(find.textContaining('{2}'), findsNothing);
    expect(find.textContaining('α'), findsOneWidget);
    expect(find.textContaining(r'\alpha'), findsNothing);
  });
}
