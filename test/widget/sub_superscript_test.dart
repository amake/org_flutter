import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import './util.dart';

void main() {
  testWidgets('Sub/superscript', (tester) async {
    await tester.pumpWidget(wrap(const Org(r'#+FOO: foo bar^{2} baz_{1}')));
    expect(find.textContaining('2'), findsOneWidget);
    expect(find.textContaining('{2}'), findsNothing);
    expect(find.textContaining('1'), findsOneWidget);
    expect(find.textContaining('{1}'), findsNothing);
  });
}
