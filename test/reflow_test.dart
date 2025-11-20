import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/src/util/reflow.dart';

void main() {
  group('reflow text', () {
    group('space-delimited script', () {
      test('solitary token', () {
        final text = ' \n foo\n\nbar\n\nbaz\nbuzz \nbazinga\n  ';
        expect(reflowText(text, TokenLocation.only),
            ' \n foo\n\nbar\n\nbaz buzz bazinga\n  ');
      });
      test('start token', () {
        final text = ' \n foo\n\nbar\n\nbaz\nbuzz \nbazinga\n  ';
        expect(reflowText(text, TokenLocation.start),
            ' \n foo\n\nbar\n\nbaz buzz bazinga ');
      });
      test('middle token', () {
        final text = ' \n foo\n\nbar\n\nbaz\nbuzz \nbazinga\n  ';
        expect(reflowText(text, TokenLocation.middle),
            ' foo\n\nbar\n\nbaz buzz bazinga ');
      });
      test('end token', () {
        final text = ' \n foo\n\nbar\n\nbaz\nbuzz \nbazinga\n  ';
        expect(reflowText(text, TokenLocation.end),
            ' foo\n\nbar\n\nbaz buzz bazinga\n  ');
      });
    });
    group('non-space-delimited script', () {
      test('solitary token', () {
        final text = ' \n あ\n\nい\n\nう\nえ \nお\n  ';
        expect(reflowText(text, TokenLocation.only), ' \n あ\n\nい\n\nうえお\n  ');
      });
      test('start token', () {
        final text = ' \n あ\n\nい\n\nう\nえ \nお\n  ';
        expect(reflowText(text, TokenLocation.start), ' \n あ\n\nい\n\nうえお ');
      });
      test('middle token', () {
        final text = ' \n あ\n\nい\n\nう\nえ \nお\n  ';
        expect(reflowText(text, TokenLocation.middle), ' あ\n\nい\n\nうえお ');
      });
      test('end token', () {
        final text = ' \n あ\n\nい\n\nう\nえ \nお\n  ';
        expect(reflowText(text, TokenLocation.end), ' あ\n\nい\n\nうえお\n  ');
      });
      test('astral plane', () {
        final text = '𠮟\nる';
        expect(reflowText(text, TokenLocation.only), '𠮟る');
      });
    });
  });
  group('Unicode utils', () {
    test('codePointAt', () {
      final text = 'A𠮟る';
      expect(text.codePointAt(-1), isNull);
      expect(text.codePointAt(0), 0x41); // 'A'
      expect(text.codePointAt(1), 0x20B9F); // '𠮟'
      expect(text.codePointAt(2), 0xDF9F);
      expect(text.codePointAt(3), 0x308B); // 'る'
      expect(text.codePointAt(4), isNull);
    });
    test('codePointBefore', () {
      final text = 'A𠮟る';
      expect(text.codePointBefore(0), isNull);
      expect(text.codePointBefore(1), 0x41); // 'A'
      expect(text.codePointBefore(2), 0xD842);
      expect(text.codePointBefore(3), 0x20B9F); // '𠮟'
      expect(text.codePointBefore(4), 0x308B); // 'る'
      expect(text.codePointBefore(5), isNull);
    });
  });
}
