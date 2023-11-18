import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/src/util/elisp.dart';
import 'package:petit_lisp/lisp.dart';

dynamic exec(String script, [InterruptCallback? interrupt]) {
  final env = ElispEnvironment(StandardEnvironment(NativeEnvironment()))
    ..interrupt = interrupt;
  return evalString(elispParser, env, script);
}

void main() {
  test('function quote', () {
    expect(
      elispParser.parse("#'foo").value,
      [Cons(Name('quote'), Cons(Name('foo')))],
    );
  });
  test('eq', () {
    expect(exec('(eq 1 1)'), true);
    expect(exec('(eq 1 2)'), false);
    expect(exec('(eq 1 1.0)'), false);
    expect(exec('(eq 1.0 1.0)'), true);
    expect(exec('(eq "foo" "foo")'), false);
    expect(exec('(eq "foo" "bar")'), false);
    expect(exec("(eq 'foo 'foo)"), true);
  });
  test('add-to-list', () {
    expect(exec("(define foo null) (add-to-list 'foo 1)"), Cons(1));
    expect(exec("(define foo '(1)) (add-to-list 'foo 1)"), Cons(1));
    expect(exec("(define foo '(1)) (add-to-list 'foo 2)"), Cons(2, Cons(1)));
    expect(exec("(define foo '(1)) (add-to-list 'foo 2 t)"), Cons(1, Cons(2)));
    expect(
      exec("(define foo '(1)) (add-to-list 'foo 2 'foo)"),
      Cons(1, Cons(2)),
    );
    expect(
      exec('''(define foo '("foo")) (add-to-list 'foo "foo" nil 'equal)'''),
      Cons("foo"),
    );
    expect(
      exec('''(define foo '("foo")) (add-to-list 'foo "foo" nil 'eq)'''),
      Cons("foo", Cons("foo")),
    );
    expect(
      exec('''(define foo '("foo")) (add-to-list 'foo "foo" nil #'eq)'''),
      Cons("foo", Cons("foo")),
    );
  });
  test('setq', () {
    expect(exec('(setq foo 1 bar 2) (cons foo bar)'), Cons(1, 2));
    expect(exec('(setq foo 1 bar 2)'), 2);
    expect(exec('(define (foo) (setq bar 1)) (foo) bar'), 1);
    expect(
      () => exec('(define (foo x) (setq x 1)) (foo 0) x'),
      throwsArgumentError,
    );
  });
  test('dolist', () {
    expect(
      exec("""
(define result 0)
(dolist (x '(1 2 3)) (setq result (+ result x)))
result
"""),
      6,
    );
    expect(
      exec("(dolist (x '(1 2 3) result) (setq result (cons x result)))"),
      Cons(3, Cons(2, Cons(1))),
    );
  });
  test('defun', () {
    expect(exec('(defun foo () 1) (foo)'), 1);
    expect(exec('(defun bar (x) (+ 1 x)) (bar 1)'), 2);
  });
  test('defvar', () {
    expect(exec('(defvar foo 1) foo'), 1);
    expect(exec('(defvar foo 1) (defvar foo 2) foo'), 2);
  });
  test('defmacro', () {
    expect(
      exec("(defmacro foo (x) `(list 'x 'was (quote ,x))) (foo a)"),
      Cons(Name('x'), Cons(Name('was'), Cons(Name('a')))),
    );
  });
  test('infinite loop', () {
    final start = DateTime.timestamp().millisecondsSinceEpoch;
    expect(
      () => exec('(while t)', () {
        final now = DateTime.timestamp().millisecondsSinceEpoch;
        if (now - start > 200) throw StateError('interrupted');
      }),
      throwsStateError,
    );
  });
}
