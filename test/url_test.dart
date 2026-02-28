import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/src/util/util.dart';

void main() {
  group('image path', () {
    test('simple', () {
      expect(looksLikeImagePath('foo.jpg'), isTrue);
      expect(looksLikeImagePath('/path/to/foo.jpg'), isTrue);
      expect(looksLikeImagePath('foo.jpeg'), isTrue);
      expect(looksLikeImagePath('foo.png'), isTrue);
      expect(looksLikeImagePath('foo.gif'), isTrue);
      expect(looksLikeImagePath('foo.webp'), isTrue);
      expect(looksLikeImagePath('foo.wbmp'), isTrue);
      expect(looksLikeImagePath('foo.bmp'), isTrue);
      expect(looksLikeImagePath('foo.svg'), isTrue);
      expect(looksLikeImagePath('foo.avif'), isTrue);
      expect(looksLikeImagePath('data:image/png;base64,...'), isTrue);
      expect(looksLikeImagePath('http://example.com/foo.jpg'), isTrue);
    });
    test('not image', () {
      expect(looksLikeImagePath('foo.txt'), isFalse);
      expect(looksLikeImagePath('http://example.com/foo.txt'), isFalse);
    });
    test('case-insensitive', () {
      expect(looksLikeImagePath('foo.JpG'), isTrue);
      expect(looksLikeImagePath('foo.PnG'), isTrue);
    });
    test('with suffix', () {
      expect(looksLikeImagePath('foo.jpg?foo=bar'), isFalse);
      expect(looksLikeImagePath('foo.png#section'), isFalse);
    });
  });
  group('url-like', () {
    test('simple', () {
      expect(looksLikeUrl('http://example.com'), isTrue);
      expect(looksLikeUrl('https://example.com'), isTrue);
      expect(looksLikeUrl('ftp://example.com'), isTrue);
      expect(looksLikeUrl('file:///path/to/file'), isTrue);
    });
    test('not url', () {
      expect(looksLikeUrl('example.com'), isFalse);
      expect(looksLikeUrl('/path/to/file'), isFalse);
    });
    test('case-insensitive scheme', () {
      expect(looksLikeUrl('HTTP://example.com'), isTrue);
      expect(looksLikeUrl('Https://example.com'), isTrue);
    });
  });
}
