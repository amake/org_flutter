import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import './util.dart';

void main() {
  group('Images', () {
    testWidgets('Path link', (tester) async {
      var invoked = false;
      await tester.pumpWidget(wrap(Org(
        'file:./foo.png',
        loadImage: (link) {
          invoked = true;
          expect(link.location, 'file:./foo.png');
          return null;
        },
      )));
      expect(invoked, isTrue);
    });
    testWidgets('Bracket link', (tester) async {
      var invoked = false;
      await tester.pumpWidget(wrap(Org(
        '[[file:./foo.png]]',
        loadImage: (link) {
          invoked = true;
          expect(link.location, 'file:./foo.png');
          return null;
        },
      )));
      expect(invoked, isTrue);
    });
    testWidgets('Bracket link with description', (tester) async {
      await tester.pumpWidget(wrap(Org(
        '[[file:./foo.png][foo]]',
        loadImage: (link) {
          fail('Should not be invoked');
        },
      )));
    });
  });
}
