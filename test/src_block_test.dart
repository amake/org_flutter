import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_parser/org_parser.dart';

void main() {
  group('src block', () {
    group('coderef format', () {
      test('custom', () {
        final doc = OrgDocument.parse('''
#+begin_src emacs-lisp -n -r -l ";;ref:%s"
(save-excursion                ;;ref:this-line
  (goto-char (point-min))      ;;ref:and-that-line
#+end_src
''');
        final node = doc.find<OrgSrcBlock>((_) => true)!.node;
        expect(node.coderefFormat(), ';;ref:%s');
      });
      test('default', () {
        final doc = OrgDocument.parse('''
#+begin_src emacs-lisp -n -r
(save-excursion                ;;(ref:this-line)
  (goto-char (point-min))      ;;(ref:and-that-line)
#+end_src
''');
        final node = doc.find<OrgSrcBlock>((_) => true)!.node;
        expect(node.coderefFormat(), '(ref:%s)');
      });
    });
    group('coderef pattern', () {
      test('custom', () {
        final doc = OrgDocument.parse('''
#+begin_src emacs-lisp -n -r -l ";;ref:%s"
(save-excursion                ;;ref:this-line
  (goto-char (point-min))      ;;ref:and-that-line
#+end_src
''');
        final node = doc.find<OrgSrcBlock>((_) => true)!.node;
        final match = node.coderefPattern().firstMatch(node.body.toMarkup());
        expect(match?.namedGroup('name'), 'this-line');
      });
      test('default', () {
        final doc = OrgDocument.parse('''
#+begin_src emacs-lisp -n -r
(save-excursion                ;;(ref:this-line)
  (goto-char (point-min))      ;;(ref:and-that-line)
#+end_src
''');
        final node = doc.find<OrgSrcBlock>((_) => true)!.node;
        final match = node.coderefPattern().firstMatch(node.body.toMarkup());
        expect(match?.namedGroup('name'), 'this-line');
      });
    });
    group('has coderef', () {
      test('custom', () {
        final doc = OrgDocument.parse('''
#+begin_src emacs-lisp -n -r -l ";;ref:%s"
(save-excursion                ;;ref:this-line
  (goto-char (point-min))      ;;ref:and-that-line
#+end_src
''');
        final node = doc.find<OrgSrcBlock>((_) => true)!.node;
        expect(node.hasCoderef('this-line'), isTrue);
        expect(node.hasCoderef('and-that-line'), isTrue);
        expect(node.hasCoderef('missing'), isFalse);
      });
      test('default', () {
        final doc = OrgDocument.parse('''
#+begin_src emacs-lisp -n -r
(save-excursion                ;;(ref:this-line)
  (goto-char (point-min))      ;;(ref:and-that-line)
#+end_src
''');
        final node = doc.find<OrgSrcBlock>((_) => true)!.node;
        expect(node.hasCoderef('this-line'), isTrue);
        expect(node.hasCoderef('and-that-line'), isTrue);
        expect(node.hasCoderef('missing'), isFalse);
      });
    });
  });
}
