import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test', (tester) async {
    await tester.pumpWidget(const MyApp());
  });
}
