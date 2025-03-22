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
    test('center', () {
      final doc = OrgDocument.parse('''
#+ATTR_ORG: :center t
[[foo]]
''');
      final node = doc.find<OrgLink>((_) => true)!.node;
      expect(alignmentForNode(node, doc), OrgAlignment.center);
    });
    test('non-authoritative', () {
      final doc = OrgDocument.parse('''
#+ATTR_HTML: :align center
[[foo]]
''');
      final node = doc.find<OrgLink>((_) => true)!.node;
      expect(alignmentForNode(node, doc), OrgAlignment.center);
    });
    test('authoritative override', () {
      final doc = OrgDocument.parse('''
#+ATTR_HTML: :align center
#+ATTR_ORG: :align right
[[foo]]
''');
      final node = doc.find<OrgLink>((_) => true)!.node;
      expect(alignmentForNode(node, doc), OrgAlignment.right);
    });
    test('case-insensitive', () {
      final doc = OrgDocument.parse('''
#+attr_org: :ALIGN center
[[foo]]
''');
      final node = doc.find<OrgLink>((_) => true)!.node;
      expect(alignmentForNode(node, doc), OrgAlignment.center);
    });
    test('distant', () {
      final doc = OrgDocument.parse('''
#+ATTR_ORG: :align center
#+ATTR_HTML: :foo bar
#+ATTR_LATEX: :baz bazinga
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
    test('invalid align value', () {
      final doc = OrgDocument.parse('''
#+ATTR_ORG: :align foo
[[foo]]
''');
      final node = doc.find<OrgLink>((_) => true)!.node;
      expect(alignmentForNode(node, doc), isNull);
    });
    test('invalid center value', () {
      final doc = OrgDocument.parse('''
#+ATTR_ORG: :center foo
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
    test('in paragraph', () {
      final doc = OrgDocument.parse('''
#+ATTR_ORG: :align center
a [[foo]] b
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
