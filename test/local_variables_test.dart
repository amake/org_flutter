import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/src/error.dart';
import 'package:org_flutter/src/util/local_variables.dart';
import 'package:org_parser/org_parser.dart';
import 'package:petit_lisp/lisp.dart';
import 'package:petitparser/petitparser.dart';

void main() {
  group('parser', () {
    group('components', () {
      final parserDefinition = LocalVariablesParser();
      Parser buildSpecific(Parser Function() start) {
        return parserDefinition.buildFrom(start()).end();
      }

      test('symbol', () {
        final parser = buildSpecific(parserDefinition.symbol);
        final result = parser.parse('foo').value;
        expect(result, 'foo');
      });
      group('atom', () {
        final parser = buildSpecific(parserDefinition.atom);
        test('list', () {
          final result = parser.parse('(foo bar)').value;
          expect(result, isA<Cons>());
          expect(result, Cons(Name('foo'), Cons(Name('bar'), null)));
        });
        test('string', () {
          final result = parser.parse('"foo"').value;
          expect(result, 'foo');
        });
        test('number', () {
          final result = parser.parse('123').value;
          expect(result, 123);
        });
      });
      test('entry', () {
        final parser = buildSpecific(parserDefinition.entry);
        final result = parser.parse('foo: bar').value;
        expect(result, isA<({String key, dynamic value})>());
        expect(result.key, 'foo');
        expect(result.value, Name('bar'));
      });
    });

    group('full', () {
      group('single', () {
        test('simple', () {
          final result = localVariablesParser.parse('foo: (bar)').value;
          expect(result, [(key: 'foo', value: Cons(Name('bar'), null))]);
        });
        test('multiline', () {
          final result = localVariablesParser.parse('''foo: (
  bar
)
''').value;
          expect(result[0], (key: 'foo', value: Cons(Name('bar'), null)));
        });
        test('extraneous atom', () {
          final result = localVariablesParser.parse('foo: 1 (bar)').value;
          expect(result, [(key: 'foo', value: 1)]);
        });
        test('confusing key', () {
          final result = localVariablesParser.parse('foo:: 1').value;
          expect(result, [(key: 'foo:', value: 1)]);
        });
        test('missing value', () {
          final result = localVariablesParser.parse('foo:');
          expect(result, isA<Failure>());
        });
        test('value on next line', () {
          final result = localVariablesParser.parse('''foo:
 1''').value;
          expect(result, [(key: 'foo', value: 1)]);
        });
      });
      group('multiple', () {
        test('simple', () {
          final result = localVariablesParser.parse('''foo: (bar)
baz: 1''').value;
          expect(result[0], (key: 'foo', value: Cons(Name('bar'), null)));
          expect(result[1], (key: 'baz', value: 1));
        });
        test('missing value', () {
          final result = localVariablesParser.parse('''foo:
baz: 1''').value;
          expect(result[0], (key: 'foo', value: Name('baz:')));
        });
      });
    });
  });
  group('extract', () {
    void ignoreError(dynamic _) {}
    test('simple', () {
      final doc = OrgDocument.parse('''# Local Variables:
# foo: bar
# End:''');
      final result = extractLocalVariables(doc, ignoreError);
      expect(result, {'foo': Name('bar')});
    });
    test('multiple', () {
      final doc = OrgDocument.parse('''# Local Variables:
# foo: bar
# baz: 1
# buzz: ("a" "b")
# End:''');
      final result = extractLocalVariables(doc, ignoreError);
      expect(
        result,
        {'foo': Name('bar'), 'baz': 1, 'buzz': Cons('a', Cons('b'))},
      );
    });
    test('eval', () {
      final doc = OrgDocument.parse('''# Local Variables:
# foo: 1
# eval: (set! foo 2)
# End:''');
      final result = extractLocalVariables(doc, ignoreError);
      expect(result, {'foo': 2});
    });
    test('add to entities', () {
      final doc = OrgDocument.parse('''# Local Variables:
# eval: (
#   add-to-list
#   'org-entities-user
#   '("snowman" "[snowman]" nil "&#9731;" "[snowman]")
# )
# End:''');
      final result = extractLocalVariables(doc, ignoreError);
      expect(result, {
        'org-entities-user': Cons(Cons(
            'snowman',
            Cons('[snowman]',
                Cons(Name('nil'), Cons('&#9731;', Cons('[snowman]'))))))
      });
    });
  });
  group('error handling', () {
    test('parse error', () {
      final doc = OrgDocument.parse('''# Local Variables:
# foo: (
# End:''');
      expect(
        () => extractLocalVariables(
            doc, (e) => fail('should not call error handler')),
        throwsA(isA<OrgParserError>()),
      );
    });
    test('execution error', () {
      final doc = OrgDocument.parse('''# Local Variables:
# eval: (foo)
# End:''');
      var called = false;
      final lvars = extractLocalVariables(doc, (e) {
        called = true;
        expect(e, isA<OrgExecutionError>());
      });
      expect(lvars, <String, dynamic>{});
      expect(called, isTrue);
    });
    test('timeout error', () {
      final doc = OrgDocument.parse('''# Local Variables:
# eval: (while t)
# End:''');
      var called = false;
      final lvars = extractLocalVariables(doc, (e) {
        called = true;
        expect(e, isA<OrgTimeoutError>());
      });
      expect(lvars, <String, dynamic>{});
      expect(called, isTrue);
    });
    group('argument error', () {
      test('bad entities list', () {
        final doc = OrgDocument.parse('''# Local Variables:
# org-entities-user: (foo)
# End:''');
        final lvars = extractLocalVariables(
          doc,
          (e) => fail('should not call error handler'),
        );
        expect(lvars.length, 1);
        var called = false;
        final entities = getOrgEntities({}, lvars, (e) {
          called = true;
          expect(e, isA<OrgArgumentError>());
        });
        expect(entities, <String, String>{});
        expect(called, isTrue);
      });
      test('bad entity', () {
        final doc = OrgDocument.parse('''# Local Variables:
# org-entities-user: (
#   ("snowman" "[snowman]" nil "&#9731;" "[snowman]")
#   ("avocado" "[avocado]" nil "&#129361;" "[avocado]" "[avocado]" "🥑")
# )
# End:''');
        final lvars = extractLocalVariables(
          doc,
          (e) => fail('should not call error handler'),
        );
        expect(lvars.length, 1);
        var called = false;
        final entities = getOrgEntities({}, lvars, (e) {
          called = true;
          expect(e, isA<OrgArgumentError>());
        });
        expect(entities, {'avocado': '🥑'});
        expect(called, isTrue);
      });
    });
  });
}
