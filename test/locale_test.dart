import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_parser/org_parser.dart';

void main() {
  group('extract', () {
    test('simple', () {
      final doc = OrgDocument.parse('''
#+LANGUAGE: en
foo
''');
      expect(extractLocale(doc), Locale('en'));
    });
    test('case-insensitive', () {
      final doc = OrgDocument.parse('''
#+language: en
foo
''');
      expect(extractLocale(doc), Locale('en'));
    });
    test('empty', () {
      final doc = OrgDocument.parse('''
foo
''');
      expect(extractLocale(doc), isNull);
    });
  });
  group('parse', () {
    test('language', () {
      expect(
        tryParseLocale('en'),
        Locale('en'),
      );
    });
    test('language and region', () {
      expect(
        tryParseLocale('en_US'),
        Locale('en', 'US'),
      );
    });
    test('language and script', () {
      expect(
        tryParseLocale('zh_Hans'),
        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      );
    });
    test('language, script, and region', () {
      expect(
        tryParseLocale('zh_Hans_CN'),
        Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
          countryCode: 'CN',
        ),
      );
    });
    test('hyphens', () {
      expect(
        tryParseLocale('zh-Hans-CN'),
        Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
          countryCode: 'CN',
        ),
      );
    });
    group('invalid', () {
      test('empty', () {
        expect(
          tryParseLocale(''),
          isNull,
        );
      });
      test('too many parts', () {
        expect(
          tryParseLocale('en_Latn_US_foo'),
          isNull,
        );
      });
      test('second part bad length', () {
        expect(
          tryParseLocale('en_Lat'),
          isNull,
        );
      });
    });
  });
}
