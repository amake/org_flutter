import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:org_flutter/org_flutter.dart';

import './util.dart';

const _block = r'''
\begin{equation}
a^2 + b^2 = c^2
\end{equation}
''';

/// The effective style of the first text run containing [needle], with the
/// styles of all enclosing spans applied.
TextStyle _styleOf(String needle) {
  TextStyle? found;
  bool visit(InlineSpan span, TextStyle inherited) {
    final style = inherited.merge(span.style);
    if (span is TextSpan) {
      if (span.text?.contains(needle) ?? false) {
        found = style;
        return false;
      }
      for (final child in span.children ?? const <InlineSpan>[]) {
        if (!visit(child, style)) return false;
      }
    }
    return true;
  }

  for (final element in find.byType(RichText).evaluate()) {
    if (!visit((element.widget as RichText).text, const TextStyle())) break;
  }
  if (found == null) fail('No text run contains "$needle"');
  return found!;
}

void main() {
  group('LaTeX', () {
    group('No callback', () {
      testWidgets('Inline shows source', (tester) async {
        await tester.pumpWidget(wrap(const Org(r'foo \(a^2\) bar')));
        expect(find.textContaining(r'foo \(a^2\) bar'), findsOneWidget);
      });
      testWidgets('Inline source is in the code style', (tester) async {
        const code = TextStyle(fontFamily: 'TestCode');
        await tester.pumpWidget(
          wrap(
            Org(
              r'foo *bold \(a^2\) text* bar',
              lightTheme: OrgThemeData.light().copyWith(codeTextStyle: code),
            ),
          ),
        );
        final source = _styleOf(r'\(a^2\)');
        expect(source.fontFamily, 'TestCode');
        expect(source.color, OrgThemeData.light().codeColor);
        expect(source.fontWeight, FontWeight.bold);
        expect(_styleOf('foo').fontFamily, isNot('TestCode'));
      });
      testWidgets('Block shows source', (tester) async {
        await tester.pumpWidget(wrap(const Org(_block)));
        expect(
          find.text('\\begin{equation}\na^2 + b^2 = c^2\n\\end{equation}'),
          findsOneWidget,
        );
      });
    });
    group('Inline callback', () {
      testWidgets('Receives fragment and returned span is used', (
        tester,
      ) async {
        OrgLatexInline? received;
        await tester.pumpWidget(
          wrap(
            Org(
              r'foo \(a^2\) bar',
              loadLatexInline: (latex, style) {
                received = latex;
                return const TextSpan(text: 'RENDERED');
              },
            ),
          ),
        );
        expect(received?.content, 'a^2');
        expect(find.textContaining('foo RENDERED bar'), findsOneWidget);
        expect(find.textContaining(r'\(a^2\)'), findsNothing);
      });
      testWidgets('Null return shows source', (tester) async {
        var invoked = false;
        await tester.pumpWidget(
          wrap(
            Org(
              r'foo \(a^2\) bar',
              loadLatexInline: (latex, style) {
                invoked = true;
                return null;
              },
            ),
          ),
        );
        expect(invoked, isTrue);
        expect(find.textContaining(r'foo \(a^2\) bar'), findsOneWidget);
      });
      testWidgets('Receives resolved ambient style', (tester) async {
        TextStyle? received;
        await tester.pumpWidget(
          wrap(
            Org(
              r'foo \(a^2\) bar',
              style: const TextStyle(fontSize: 30),
              loadLatexInline: (latex, style) {
                received = style;
                return null;
              },
            ),
          ),
        );
        expect(received?.fontSize, 30);
        expect(received?.fontWeight, isNot(FontWeight.bold));
      });
      testWidgets('Receives markup style', (tester) async {
        TextStyle? received;
        await tester.pumpWidget(
          wrap(
            Org(
              r'foo *bold \(a^2\) text* bar',
              style: const TextStyle(fontSize: 30),
              loadLatexInline: (latex, style) {
                received = style;
                return null;
              },
            ),
          ),
        );
        expect(received?.fontWeight, FontWeight.bold);
        expect(received?.fontSize, 30);
      });
      testWidgets('Receives headline style', (tester) async {
        TextStyle? received;
        await tester.pumpWidget(
          wrap(
            Org(
              r'* Heading \(a^2\)',
              style: const TextStyle(fontSize: 30),
              loadLatexInline: (latex, style) {
                received = style;
                return null;
              },
            ),
          ),
        );
        expect(received?.fontWeight, FontWeight.bold);
        expect(received?.fontSize, 30);
        expect(received?.color, OrgThemeData.light().levelColor(0));
      });
    });
    group('Other contexts', () {
      for (final (name, text) in [
        ('list item', '- foo \\(a^2\\) bar'),
        ('table cell', '| foo \\(a^2\\) bar |'),
        ('link description', '[[https://example.com][foo \\(a^2\\) bar]]'),
      ]) {
        testWidgets('Inline callback in $name', (tester) async {
          TextStyle? received;
          await tester.pumpWidget(
            wrap(
              Org(
                text,
                style: const TextStyle(fontSize: 30),
                loadLatexInline: (latex, style) {
                  received = style;
                  return const TextSpan(text: 'RENDERED');
                },
              ),
            ),
          );
          expect(received?.fontSize, 30);
          expect(find.textContaining('foo RENDERED bar'), findsOneWidget);
        });
      }
      testWidgets('Source fallback is searchable', (tester) async {
        final doc = OrgDocument.parse(r'foo \(a^2\) bar');
        await tester.pumpWidget(
          wrap(
            OrgController(
              root: doc,
              searchQuery: 'a^2',
              child: OrgRootWidget(child: OrgDocumentWidget(doc)),
            ),
          ),
        );
        final controller = OrgController.of(
          tester.element(find.textContaining('foo')),
        );
        expect(controller.searchResultKeys.value.length, 1);
      });
    });
    group('Block callback', () {
      testWidgets('Receives block and returned widget is used', (tester) async {
        OrgLatexBlock? received;
        await tester.pumpWidget(
          wrap(
            Org(
              _block,
              loadLatexBlock: (latex) {
                received = latex;
                return const Text('RENDERED');
              },
            ),
          ),
        );
        expect(received?.environment, 'equation');
        expect(received?.content, '\na^2 + b^2 = c^2\n');
        expect(find.text('RENDERED'), findsOneWidget);
        expect(find.textContaining(r'\begin{equation}'), findsNothing);
      });
      testWidgets('Null return shows source', (tester) async {
        var invoked = false;
        await tester.pumpWidget(
          wrap(
            Org(
              _block,
              loadLatexBlock: (latex) {
                invoked = true;
                return null;
              },
            ),
          ),
        );
        expect(invoked, isTrue);
        expect(find.textContaining(r'\begin{equation}'), findsOneWidget);
      });
    });
    group('OrgText widget', () {
      testWidgets('Inline callback', (tester) async {
        await tester.pumpWidget(
          wrap(
            OrgText(
              r'foo \(a^2\) bar',
              loadLatexInline: (latex, style) =>
                  const TextSpan(text: 'RENDERED'),
            ),
          ),
        );
        expect(find.textContaining('foo RENDERED bar'), findsOneWidget);
      });
      testWidgets('Block callback', (tester) async {
        await tester.pumpWidget(
          wrap(
            OrgText(_block, loadLatexBlock: (latex) => const Text('RENDERED')),
          ),
        );
        expect(find.text('RENDERED'), findsOneWidget);
      });
    });
    group('OrgRootWidget', () {
      testWidgets('Callbacks', (tester) async {
        final doc = OrgDocument.parse('foo \\(a^2\\) bar\n$_block');
        await tester.pumpWidget(
          wrap(
            OrgController(
              root: doc,
              child: OrgRootWidget(
                loadLatexInline: (latex, style) =>
                    const TextSpan(text: 'INLINE'),
                loadLatexBlock: (latex) => const Text('BLOCK'),
                child: OrgDocumentWidget(doc),
              ),
            ),
          ),
        );
        expect(find.textContaining('foo INLINE bar'), findsOneWidget);
        expect(find.text('BLOCK'), findsOneWidget);
      });
    });
    group('Updates', () {
      test('updateShouldNotify', () {
        InlineSpan? inlineA(OrgLatexInline _, TextStyle _) => null;
        InlineSpan? inlineB(OrgLatexInline _, TextStyle _) => null;
        Widget? blockA(OrgLatexBlock _) => null;
        Widget? blockB(OrgLatexBlock _) => null;
        OrgEvents events({
          InlineSpan? Function(OrgLatexInline, TextStyle)? inline,
          Widget? Function(OrgLatexBlock)? block,
        }) => OrgEvents(
          loadLatexInline: inline,
          loadLatexBlock: block,
          child: const SizedBox(),
        );
        final base = events(inline: inlineA, block: blockA);
        expect(
          events(inline: inlineA, block: blockA).updateShouldNotify(base),
          isFalse,
        );
        expect(
          events(inline: inlineB, block: blockA).updateShouldNotify(base),
          isTrue,
        );
        expect(
          events(inline: inlineA, block: blockB).updateShouldNotify(base),
          isTrue,
        );
        expect(events(block: blockA).updateShouldNotify(base), isTrue);
        expect(events(inline: inlineA).updateShouldNotify(base), isTrue);
      });
      testWidgets('New callbacks are used', (tester) async {
        Widget build(String inline, String block) => wrap(
          Org(
            'foo \\(a^2\\) bar\n$_block',
            loadLatexInline: (latex, style) => TextSpan(text: inline),
            loadLatexBlock: (latex) => Text(block),
          ),
        );
        await tester.pumpWidget(build('INLINE1', 'BLOCK1'));
        expect(find.textContaining('foo INLINE1 bar'), findsOneWidget);
        expect(find.text('BLOCK1'), findsOneWidget);
        await tester.pumpWidget(build('INLINE2', 'BLOCK2'));
        expect(find.textContaining('foo INLINE2 bar'), findsOneWidget);
        expect(find.text('BLOCK2'), findsOneWidget);
      });
    });
  });
}
