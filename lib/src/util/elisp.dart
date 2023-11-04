import 'dart:developer';

import 'package:petit_lisp/lisp.dart';

// TODO(aaron): more accurate standard env
class ElispEnvironment extends Environment {
  ElispEnvironment(super.owner) {
    // petit_lisp's `set!` does not evaluate the symbol
    define(Name('set'), _set);
    define(Name('setq'), _setq);
    define(Name('dolist'), _dolist);
    define(Name('debugger'), _debugger);
    evalString(lispParser, this, _standardLibrary);
  }

  static dynamic _set(Environment env, dynamic args) {
    final sym = eval(env, args.head);
    if (sym is! Name) {
      throw ArgumentError('set: first argument must be a symbol');
    }
    return env[sym] = eval(env, args.tail.head);
  }

  static dynamic _setq(Environment env, dynamic args) {
    dynamic result;
    while (args is Cons) {
      final sym = args.head;
      if (sym is! Name) {
        throw ArgumentError('Invalid setq: $sym is not a symbol');
      }
      args = args.tail;
      result = env.setOrDefine(sym, eval(env, args.head));
      args = args.tail;
    }
    return result;
  }

  static dynamic _dolist(Environment env, dynamic args) {
    if (args.head is! Cons) {
      throw ArgumentError('Invalid dolist: $args');
    }
    final loopSpec = args.head as Cons;
    if (loopSpec.head is! Name) {
      throw ArgumentError('Invalid dolist: $args');
    }
    final loopVar = loopSpec.head as Name;
    var list = eval(env, loopSpec.tail?.head);
    if (list is! Cons) {
      throw ArgumentError('Invalid dolist: $args');
    }
    final innerEnv = env.create();
    final resultVar = loopSpec.tail!.tail?.head;
    if (resultVar is Name) {
      innerEnv.define(resultVar, null);
    }
    final body = args.tail?.head;
    while (list is Cons) {
      innerEnv.define(loopVar, list.head);
      eval(innerEnv, body);
      list = list.tail;
    }
    return resultVar is Name ? innerEnv[resultVar] : null;
  }

  static dynamic _debugger(Environment env, dynamic args) {
    debugger();
  }

  static const _standardLibrary = '''
(define t true)

(define (member element list)
  (if (null? list)
    false
    (or (= element (car list))
        (member element (cdr list)))))

(define (add-to-list list-var element &optional append_)
  (if (not (member element (eval list-var)))
      (set list-var (if (= append_ true)
                        (append (eval list-var) (cons element null))
                        (cons element (eval list-var))))))
''';
}

extension ElispExt on Environment {
  Environment get _root {
    var env = this;
    while (env.owner != null) {
      env = env.owner!;
    }
    return env;
  }

  dynamic setOrDefine(Name key, dynamic value) {
    try {
      return this[key] = value;
    } on ArgumentError {
      return _root.define(key, value);
    }
  }
}
