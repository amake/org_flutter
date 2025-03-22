import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_parser/org_parser.dart';

void main() {
  group('extract', () {
    test('simple', () {
      final doc = OrgDocument.parse('''
#+ATTR_ORG: :align center
[[foo]]
''');
      final node = doc.find<OrgLink>((_) => true)!.node;
      expect(alignmentForNode(node, doc), OrgAlignment.center);
    });
    test('case-insensitive', () {
      final doc = OrgDocument.parse('''
#+attr_org: :ALIGN center
[[foo]]
''');
      final node = doc.find<OrgLink>((_) => true)!.node;
      expect(alignmentForNode(node, doc), OrgAlignment.center);
    });
    test('not present', () {
      final doc = OrgDocument.parse('''
[[foo]]
''');
      final node = doc.find<OrgLink>((_) => true)!.node;
      expect(alignmentForNode(node, doc), isNull);
    });
    test('invalid value', () {
      final doc = OrgDocument.parse('''
#+ATTR_ORG: :align foo
[[foo]]
''');
      final node = doc.find<OrgLink>((_) => true)!.node;
      expect(alignmentForNode(node, doc), isNull);
    });
    test('missing plist value', () {
      final doc = OrgDocument.parse('''
#+ATTR_ORG: :align
[[foo]]
''');
      final node = doc.find<OrgLink>((_) => true)!.node;
      expect(alignmentForNode(node, doc), isNull);
    });
    test('missing meta value', () {
      final doc = OrgDocument.parse('''
#+ATTR_ORG:
[[foo]]
''');
      final node = doc.find<OrgLink>((_) => true)!.node;
      expect(alignmentForNode(node, doc), isNull);
    });
  });
  group('plist', () {
    test('tokenize', () {
      expect(
        tokenizePlist(':align center'),
        [':align', 'center'],
      );
    });
    test('extra whitespace', () {
      expect(
        tokenizePlist(':align  center'),
        [':align', 'center'],
      );
    });
    test('get value', () {
      expect(
        tokenizePlist(':align center').get(':align'),
        'center',
      );
    });
    test('get missing key', () {
      expect(
        tokenizePlist(':align center').get(':foo'),
        isNull,
      );
    });
    test('malformed', () {
      expect(
        tokenizePlist(':align foo bar').get('bar'),
        isNull,
      );
    });
  });
}
