import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/src/util/text.dart';

void main() {
  group('detect indent', () {
    test('detect empty', () {
      final text = '';
      expect(detectIndent(text), 0);
    });
    test('detect none', () {
      final text = 'foo';
      expect(detectIndent(text), 0);
    });
    test('detect single line', () {
      final text = '  foo';
      expect(detectIndent(text), 2);
    });
    test('detect multiple lines', () {
      final text = '''  foo
    bar''';
      expect(detectIndent(text), 2);
    });
    test('middle blank line', () {
      final text = '''  foo
${' '}
    bar''';
      expect(detectIndent(text), 2);
    });
    test('trailing blank line', () {
      final text = '''  foo
 ''';
      expect(detectIndent(text), 2);
    });
    test('only blank line', () {
      final text = '''       ''';
      expect(detectIndent(text), 0);
    });
  });
  group('soft deindent', () {
    test('deindent none', () {
      final text = 'foo';
      expect(softDeindent(text, 0), text);
      expect(softDeindent(text, 1), text);
      expect(softDeindent(text, 2), text);
    });
    test('deindent single line', () {
      final text = '  foo';
      expect(softDeindent(text, 0), text);
      expect(softDeindent(text, 1), ' foo');
      expect(softDeindent(text, 2), 'foo');
      expect(softDeindent(text, 3), 'foo');
    });
    test('deindent multiple lines', () {
      final text = '''
  foo
    bar''';
      expect(softDeindent(text, 0), text);
      expect(softDeindent(text, 1), ' foo\n   bar');
      expect(softDeindent(text, 2), 'foo\n  bar');
      expect(softDeindent(text, 3), 'foo\n  bar');
    });
  });
  group('hard deindent', () {
    test('deindent none', () {
      final text = 'foo';
      expect(hardDeindent(text, 0), text);
      expect(hardDeindent(text, 1), text);
      expect(hardDeindent(text, 2), text);
    });
    test('deindent single line', () {
      final text = '  foo';
      expect(hardDeindent(text, 0), text);
      expect(hardDeindent(text, 1), ' foo');
      expect(hardDeindent(text, 2), 'foo');
      expect(hardDeindent(text, 3), '  foo');
    });
    test('deindent multiple lines', () {
      final text = '''
  foo
    bar''';
      expect(hardDeindent(text, 0), text);
      expect(hardDeindent(text, 1), ' foo\n   bar');
      expect(hardDeindent(text, 2), 'foo\n  bar');
      expect(hardDeindent(text, 3), '  foo\n bar');
    });
  });
}
