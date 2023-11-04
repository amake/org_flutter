import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/src/util/elisp.dart';
import 'package:petit_lisp/lisp.dart';

dynamic exec(String script) {
  final env = ElispEnvironment(StandardEnvironment(NativeEnvironment()));
  return evalString(lispParser, env, script);
}

void main() {
  test('member', () {
    expect(exec("(member 1 '(1 2 3))"), true);
    expect(exec("(member 4 '(1 2 3))"), false);
  });
  test('add-to-list', () {
    expect(exec("(define foo null) (add-to-list 'foo 1)"), Cons(1));
    expect(exec("(define foo '(1)) (add-to-list 'foo 2)"), Cons(2, Cons(1)));
    expect(exec("(define foo '(1)) (add-to-list 'foo 2 t)"), Cons(1, Cons(2)));
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
}
