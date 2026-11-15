import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import './util.dart';

const _code = TextStyle(fontFamily: 'TestCode');
const _verbatim = TextStyle(fontFamily: 'TestVerbatim');
const _block = TextStyle(fontFamily: 'TestBlock');

const _doc = '''
Plain text with ~inline code~ and =inline verbatim= in it.

Inline source: src_sh[:exports code]{echo inlinesrc}

Highlighted inline source: src_dart{var inlineHighlighted = 1}

#+begin_src dart
var highlightedValue = 1;
#+end_src

#+begin_src nosuchlanguage
unknown language body
#+end_src

#+begin_src
no language body
#+end_src

#+begin_example
example body
#+end_example

#+begin_export html
export body
#+end_export

: fixed width line

#+RESULTS:
: results line

#+begin_quote
quote body
#+end_quote

#+begin_verse
verse body
#+end_verse
''';

/// Text in [_doc] styled like the Emacs face `org-code`
const _codeNeedles = ['inline code', 'fixed width line', 'results line'];

/// Text in [_doc] styled like the Emacs face `org-verbatim`
const _verbatimNeedles = ['inline verbatim'];

/// Text in [_doc] styled like the Emacs face `org-block`
const _blockNeedles = [
  'sh', // The language of an inline source block
  ':exports code', // Its header arguments
  'echo inlinesrc',
  'inlineHighlighted',
  'highlightedValue',
  'unknown language body',
  'no language body',
  'example body',
  'export body',
];

/// Text in [_doc] that none of the styles applies to
const _otherNeedles = ['Plain text with', 'quote body', 'verse body'];

const _allStyledNeedles = [
  ..._codeNeedles,
  ..._verbatimNeedles,
  ..._blockNeedles,
];

/// The effective style of the first text run containing [needle], with the
/// styles of all enclosing spans applied.
TextStyle _styleOf(String needle, {bool exact = false}) {
  TextStyle? found;
  bool visit(InlineSpan span, TextStyle inherited) {
    final style = inherited.merge(span.style);
    if (span is TextSpan) {
      final text = span.text;
      if (text != null && (exact ? text == needle : text.contains(needle))) {
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
    final richText = element.widget as RichText;
    if (!visit(richText.text, const TextStyle())) break;
  }
  if (found == null) fail('No text run contains "$needle"');
  return found!;
}

/// A tall test window, so the whole document is built (it is in a scrolling
/// list, and only visible children are built).
void _tallWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

OrgThemeData _withStyles(
  OrgThemeData theme, {
  TextStyle? code,
  TextStyle? verbatim,
  TextStyle? block,
  Map<String, TextStyle>? srcTheme,
}) => theme.copyWith(
  codeTextStyle: code,
  verbatimTextStyle: verbatim,
  blockTextStyle: block,
  srcTheme: srcTheme,
);

Widget _org({
  String doc = _doc,
  TextStyle? code,
  TextStyle? verbatim,
  TextStyle? block,
}) => wrap(
  Org(
    doc,
    lightTheme: _withStyles(
      OrgThemeData.light(),
      code: code,
      verbatim: verbatim,
      block: block,
    ),
    darkTheme: _withStyles(
      OrgThemeData.dark(),
      code: code,
      verbatim: verbatim,
      block: block,
    ),
  ),
);

Widget _searched(
  String doc,
  String query, {
  TextStyle? block,
  Map<String, TextStyle>? srcTheme,
}) {
  final root = OrgDocument.parse(doc);
  return wrap(
    OrgController(
      root: root,
      searchQuery: query,
      child: OrgRootWidget(
        lightTheme: _withStyles(
          OrgThemeData.light(),
          block: block,
          srcTheme: srcTheme,
        ),
        darkTheme: _withStyles(
          OrgThemeData.dark(),
          block: block,
          srcTheme: srcTheme,
        ),
        child: OrgDocumentWidget(root),
      ),
    ),
  );
}

void main() {
  group('Text styles', () {
    testWidgets('Each element gets the style of its face', (tester) async {
      _tallWindow(tester);
      await tester.pumpWidget(
        _org(code: _code, verbatim: _verbatim, block: _block),
      );
      for (final needle in _codeNeedles) {
        expect(_styleOf(needle).fontFamily, 'TestCode', reason: needle);
      }
      for (final needle in _verbatimNeedles) {
        expect(_styleOf(needle).fontFamily, 'TestVerbatim', reason: needle);
      }
      for (final needle in _blockNeedles) {
        expect(_styleOf(needle).fontFamily, 'TestBlock', reason: needle);
      }
      // Without a color in the styles, the elements keep codeColor
      final codeColor = OrgThemeData.light().codeColor;
      expect(_styleOf('inline code').color, codeColor);
      expect(_styleOf('inline verbatim').color, codeColor);
      expect(_styleOf('example body').color, codeColor);
    });
    for (final (name, needles) in [
      ('codeTextStyle', _codeNeedles),
      ('verbatimTextStyle', _verbatimNeedles),
      ('blockTextStyle', _blockNeedles),
    ]) {
      testWidgets('$name applies only to its own elements', (tester) async {
        const only = TextStyle(fontFamily: 'TestOnly');
        _tallWindow(tester);
        await tester.pumpWidget(
          _org(
            code: name == 'codeTextStyle' ? only : null,
            verbatim: name == 'verbatimTextStyle' ? only : null,
            block: name == 'blockTextStyle' ? only : null,
          ),
        );
        for (final needle in [..._allStyledNeedles, ..._otherNeedles]) {
          expect(
            _styleOf(needle).fontFamily,
            needles.contains(needle) ? 'TestOnly' : isNot('TestOnly'),
            reason: needle,
          );
        }
      });
    }
    testWidgets('Org colors take precedence over style colors', (tester) async {
      const red = Color(0xffff0000);
      const green = Color(0xff00ff00);
      const blue = Color(0xff0000ff);
      _tallWindow(tester);
      await tester.pumpWidget(
        _org(
          code: _code.copyWith(color: red),
          verbatim: _verbatim.copyWith(color: green),
          block: _block.copyWith(color: blue),
        ),
      );
      final codeColor = OrgThemeData.light().codeColor;
      expect(_styleOf('inline code').color, codeColor);
      expect(_styleOf('fixed width line').color, codeColor);
      expect(_styleOf('inline verbatim').color, codeColor);
      expect(_styleOf('example body').color, codeColor);
      expect(_styleOf('unknown language body').color, codeColor);
      expect(_styleOf('highlightedValue').color, isNot(blue));
    });
    testWidgets('A non-inheriting style replaces the surrounding style', (
      tester,
    ) async {
      const block = TextStyle(inherit: false, fontFamily: 'TestBlock');
      _tallWindow(tester);
      await tester.pumpWidget(_org(block: block));
      final style = _styleOf('example body');
      expect(style.fontFamily, 'TestBlock');
      expect(style.fontSize, isNull);
      expect(style.color, OrgThemeData.light().codeColor);
    });
    testWidgets('The inline source language keeps metaColor', (tester) async {
      _tallWindow(tester);
      await tester.pumpWidget(_org(block: _block));
      final meta = OrgThemeData.light().metaColor;
      expect(_styleOf('sh', exact: true).color, meta);
      expect(_styleOf('sh', exact: true).fontFamily, 'TestBlock');
      await tester.pumpWidget(
        _org(block: _block.copyWith(color: const Color(0xff0000ff))),
      );
      expect(_styleOf('sh', exact: true).color, meta);
    });
    testWidgets('Quote and verse blocks are unaffected', (tester) async {
      _tallWindow(tester);
      await tester.pumpWidget(_org());
      final unstyled = {
        for (final needle in _otherNeedles) needle: _styleOf(needle),
      };
      await tester.pumpWidget(
        _org(code: _code, verbatim: _verbatim, block: _block),
      );
      for (final needle in _otherNeedles) {
        expect(_styleOf(needle), unstyled[needle], reason: needle);
      }
    });
    testWidgets('Null keeps everything in the surrounding font', (
      tester,
    ) async {
      _tallWindow(tester);
      await tester.pumpWidget(_org());
      final surrounding = _styleOf('Plain text with').fontFamily;
      for (final needle in _allStyledNeedles) {
        expect(_styleOf(needle).fontFamily, surrounding, reason: needle);
      }
      final codeColor = OrgThemeData.light().codeColor;
      for (final needle in [
        'inline code',
        'inline verbatim',
        'fixed width line',
        'example body',
        'unknown language body',
      ]) {
        expect(_styleOf(needle).color, codeColor, reason: needle);
      }
    });
  });
  group('Widgets inside highlighted source', () {
    testWidgets('Coderef', (tester) async {
      _tallWindow(tester);
      await tester.pumpWidget(
        _org(
          doc: '''
#+begin_src dart
var step = 1; // (ref:step)
#+end_src
''',
          code: _code,
          block: _block,
        ),
      );
      expect(_styleOf('(ref:step)').fontFamily, 'TestBlock');
    });
    testWidgets('Nested tokens keep the enclosing color', (tester) async {
      _tallWindow(tester);
      const green = Color(0xff00aa00);
      final theme = OrgThemeData.light().copyWith(
        blockTextStyle: _block,
        srcTheme: {
          'string': const TextStyle(color: green),
          'subst': const TextStyle(fontWeight: FontWeight.bold),
        },
      );
      await tester.pumpWidget(
        wrap(
          Org(
            r'''
#+begin_src dart
var s = "a ${nestedvar} b";
#+end_src
''',
            lightTheme: theme,
            darkTheme: theme,
          ),
        ),
      );
      final style = _styleOf('nestedvar');
      expect(style.fontWeight, FontWeight.bold);
      expect(style.color, green);
      expect(style.fontFamily, 'TestBlock');

      await tester.pumpWidget(
        _searched(
          r'''
#+begin_src dart
var s = "a ${nestedvar} b";
#+end_src
''',
          'nestedvar',
          block: _block,
          srcTheme: {
            'string': const TextStyle(color: green),
            'subst': const TextStyle(fontWeight: FontWeight.bold),
          },
        ),
      );
      final matchedStyle = _styleOf('nestedvar');
      expect(matchedStyle.fontWeight, FontWeight.bold);
      expect(matchedStyle.color, green);
      expect(matchedStyle.fontFamily, 'TestBlock');
    });
    testWidgets('Search match', (tester) async {
      _tallWindow(tester);
      await tester.pumpWidget(
        _searched(
          '''
#+begin_src dart
var searchme = 1;
#+end_src
''',
          'searchme',
          block: _block,
        ),
      );
      expect(_styleOf('searchme').fontFamily, 'TestBlock');
    });
    testWidgets('Search match in example and export blocks', (tester) async {
      _tallWindow(tester);
      await tester.pumpWidget(
        _searched(
          '''
#+begin_example
an examplematch here
#+end_example

#+begin_export html
an exportmatch here
#+end_export
''',
          'match',
          block: _block,
        ),
      );
      expect(_styleOf('match').fontFamily, 'TestBlock');
      expect(
        tester
            .widgetList<Text>(find.byType(Text))
            .where((t) => t.textSpan?.toPlainText() == 'match')
            .length,
        2,
      );
    });
    testWidgets('Unmatched code during search', (tester) async {
      _tallWindow(tester);
      await tester.pumpWidget(
        _searched(
          '''
Plain words here.

#+begin_src dart
var findme = 1; final unmatchedrun = 2;
#+end_src
''',
          'findme',
          block: _block,
        ),
      );
      // The match inside the source block, and unstyled code around it
      expect(_styleOf('findme').fontFamily, 'TestBlock');
      expect(_styleOf('unmatchedrun').fontFamily, 'TestBlock');
      // Plain text outside the block
      expect(_styleOf('Plain words here').fontFamily, isNot('TestBlock'));
    });
  });
  group('OrgThemeData text styles', () {
    final styled = _withStyles(
      OrgThemeData.light(),
      code: _code,
      verbatim: _verbatim,
      block: _block,
    );
    test('copyWith', () {
      expect(styled.codeTextStyle, _code);
      expect(styled.verbatimTextStyle, _verbatim);
      expect(styled.blockTextStyle, _block);
      final copy = styled.copyWith();
      expect(copy.codeTextStyle, _code);
      expect(copy.verbatimTextStyle, _verbatim);
      expect(copy.blockTextStyle, _block);
    });
    test('equality', () {
      final same = _withStyles(
        OrgThemeData.light(),
        code: _code,
        verbatim: _verbatim,
        block: _block,
      );
      expect(styled, same);
      expect(styled.hashCode, same.hashCode);
      expect(styled == OrgThemeData.light(), isFalse);
      // Each field takes part on its own
      const other = TextStyle(fontFamily: 'Other');
      expect(styled == styled.copyWith(codeTextStyle: other), isFalse);
      expect(styled == styled.copyWith(verbatimTextStyle: other), isFalse);
      expect(styled == styled.copyWith(blockTextStyle: other), isFalse);
    });
    test('lerp', () {
      TextStyle sized(double size) => TextStyle(fontSize: size);
      final a = _withStyles(
        OrgThemeData.light(),
        code: sized(10),
        verbatim: sized(20),
        block: sized(30),
      );
      final b = _withStyles(
        OrgThemeData.light(),
        code: sized(20),
        verbatim: sized(40),
        block: sized(60),
      );
      final mid = OrgThemeData.lerp(a, b, 0.5)!;
      expect(mid.codeTextStyle?.fontSize, 15);
      expect(mid.verbatimTextStyle?.fontSize, 30);
      expect(mid.blockTextStyle?.fontSize, 45);
    });
    test('lerp from null', () {
      final a = OrgThemeData.light();
      final start = OrgThemeData.lerp(a, styled, 0)!;
      expect(start.codeTextStyle?.fontFamily, isNull);
      expect(start.verbatimTextStyle?.fontFamily, isNull);
      expect(start.blockTextStyle?.fontFamily, isNull);
      final end = OrgThemeData.lerp(a, styled, 1)!;
      expect(end.codeTextStyle?.fontFamily, 'TestCode');
      expect(end.verbatimTextStyle?.fontFamily, 'TestVerbatim');
      expect(end.blockTextStyle?.fontFamily, 'TestBlock');
    });
    test('fontStyleForOrgStyle separates code and verbatim', () {
      const base = TextStyle();
      expect(
        styled.fontStyleForOrgStyle(base, OrgStyle.code).fontFamily,
        'TestCode',
      );
      expect(
        styled.fontStyleForOrgStyle(base, OrgStyle.verbatim).fontFamily,
        'TestVerbatim',
      );
    });
  });
}
