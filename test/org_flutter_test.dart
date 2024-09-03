import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

Widget _wrap(Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Material(child: child),
  );
}

void main() {
  test('create widget', () {
    const Org('foo');
  });
  group('Org widget', () {
    testWidgets('Simple', (tester) async {
      await tester.pumpWidget(_wrap(const Org('foo bar')));
      expect(find.text('foo bar'), findsOneWidget);
    });
    group('Visibility cycling', () {
      testWidgets('Headline tap', (tester) async {
        await tester.pumpWidget(_wrap(const Org('''
foo bar
* headline
baz buzz''')));
        expect(find.text('foo bar'), findsOneWidget);
        expect(find.text('baz buzz'), findsNothing);
        await tester.tap(find.byType(OrgHeadlineWidget));
        await tester.pump();
        expect(find.text('baz buzz'), findsOneWidget);
      });
      testWidgets('Nested sections headline tap', (tester) async {
        await tester.pumpWidget(_wrap(const Org('''
foo bar
* headline 1
baz buzz
** headline 2
bazinga''')));
        expect(find.text('foo bar'), findsOneWidget);
        expect(find.text('baz buzz'), findsNothing);
        expect(find.textContaining('headline 2'), findsNothing);
        expect(find.text('bazinga'), findsNothing);
        await tester.tap(find.byType(OrgHeadlineWidget).first);
        await tester.pump();
        expect(find.text('baz buzz'), findsOneWidget);
        expect(find.textContaining('headline 2'), findsOneWidget);
        expect(find.text('bazinga'), findsNothing);
        await tester.tap(find.byType(OrgHeadlineWidget).first);
        await tester.pump();
        expect(find.text('bazinga'), findsOneWidget);
      });
      testWidgets('Whole document', (tester) async {
        await tester.pumpWidget(_wrap(const Org('''
foo bar
* headline 1
baz buzz
** headline 2
bazinga''')));
        expect(find.text('foo bar'), findsOneWidget);
        expect(find.text('baz buzz'), findsNothing);
        expect(find.textContaining('headline 2'), findsNothing);
        expect(find.text('bazinga'), findsNothing);
        final controller =
            OrgController.of(tester.element(find.textContaining('foo bar')));
        controller.cycleVisibility();
        await tester.pump();
        expect(find.text('baz buzz'), findsNothing);
        expect(find.text('bazinga'), findsNothing);
        expect(find.textContaining('headline 2'), findsOneWidget);
        controller.cycleVisibility();
        await tester.pump();
        expect(find.text('baz buzz'), findsOneWidget);
        expect(find.text('bazinga'), findsOneWidget);
        expect(find.textContaining('headline 2'), findsOneWidget);
      });
      testWidgets('Drawer', (tester) async {
        await tester.pumpWidget(_wrap(const Org('''
:PROPERTIES:
:foo: bar
:END:''')));
        expect(find.text(':foo: bar'), findsNothing);
        await tester.tap(find.text(':PROPERTIES:...'));
        await tester.pump();
        expect(find.text(':PROPERTIES:...'), findsNothing);
        expect(find.text(':foo: bar'), findsOneWidget);
        expect(find.text(':END:'), findsOneWidget);
      });
      testWidgets('Block', (tester) async {
        await tester.pumpWidget(_wrap(const Org('''#+begin_example
  foo bar
#+end_example''')));
        expect(find.textContaining('foo bar'), findsOneWidget);
        expect(find.text('#+end_example'), findsOneWidget);
        await tester.tap(find.text('#+begin_example'));
        await tester.pumpAndSettle();
        expect(find.textContaining('#+begin_example...'), findsOneWidget);
        expect(find.textContaining('foo bar'), findsNothing);
        expect(find.textContaining('#+end_example'), findsNothing);
      });
    });
    group('State restoration', () {
      testWidgets('No restoration ID', (tester) async {
        await tester.pumpWidget(RootRestorationScope(
          restorationId: 'root',
          child: _wrap(const Org('''
foo bar
* headline 1
baz buzz
** headline 2
bazinga''')),
        ));
        expect(find.text('foo bar'), findsOneWidget);
        await tester.tap(find.byType(OrgHeadlineWidget).first);
        await tester.pump();
        expect(find.text('foo bar'), findsOneWidget);
        expect(find.text('baz buzz'), findsOneWidget);
        expect(find.textContaining('headline 2'), findsOneWidget);
        expect(find.text('bazinga'), findsNothing);
        await tester.restartAndRestore();
        expect(find.text('foo bar'), findsOneWidget);
        expect(find.text('baz buzz'), findsNothing);
        expect(find.textContaining('headline 2'), findsNothing);
        expect(find.text('bazinga'), findsNothing);
      });
      testWidgets('Restores section visibility', (tester) async {
        await tester.pumpWidget(RootRestorationScope(
          restorationId: 'root',
          child: _wrap(const Org(
            '''
foo bar
* headline 1
baz buzz
** headline 2
bazinga''',
            restorationId: 'doc',
          )),
        ));
        expect(find.text('foo bar'), findsOneWidget);
        await tester.tap(find.byType(OrgHeadlineWidget).first);
        await tester.pump();
        expect(find.text('foo bar'), findsOneWidget);
        expect(find.text('baz buzz'), findsOneWidget);
        expect(find.textContaining('headline 2'), findsOneWidget);
        expect(find.text('bazinga'), findsNothing);
        await tester.restartAndRestore();
        expect(find.text('foo bar'), findsOneWidget);
        expect(find.text('baz buzz'), findsOneWidget);
        expect(find.textContaining('headline 2'), findsOneWidget);
        expect(find.text('bazinga'), findsNothing);
      });
      testWidgets('Ignores search on restore', (tester) async {
        final doc = OrgDocument.parse('''foo bar
* headline 1
baz buzz
** headline 2
bazinga''');
        final widget = OrgController(
          root: doc,
          searchQuery: RegExp('baz'),
          restorationId: 'doc',
          child: OrgRootWidget(
            child: OrgDocumentWidget(doc),
          ),
        );
        await tester.pumpWidget(RootRestorationScope(
          restorationId: 'root',
          child: _wrap(widget),
        ));
        expect(find.text('foo bar'), findsOneWidget);
        expect(find.textContaining('buzz'), findsOneWidget);
        expect(find.textContaining('headline 2'), findsOneWidget);
        expect(find.textContaining('inga'), findsOneWidget);
        await tester.tap(find.byType(OrgHeadlineWidget).last);
        await tester.pumpAndSettle();
        expect(find.text('foo bar'), findsOneWidget);
        expect(find.textContaining('buzz'), findsOneWidget);
        expect(find.textContaining('headline 2'), findsOneWidget);
        expect(find.textContaining('inga'), findsNothing);
        await tester.restartAndRestore();
        expect(find.text('foo bar'), findsOneWidget);
        expect(find.textContaining('buzz'), findsOneWidget);
        expect(find.textContaining('headline 2'), findsOneWidget);
        expect(find.textContaining('inga'), findsNothing);
      });
      testWidgets('Ignores filter on restore', (tester) async {
        final doc = OrgDocument.parse('''foo bar
* headline 1
baz buzz
** headline 2 :abcd:
bazinga''');
        final widget = OrgController(
          root: doc,
          sparseQuery: const OrgQueryTagMatcher('abcd'),
          restorationId: 'doc',
          child: OrgRootWidget(
            child: OrgDocumentWidget(doc),
          ),
        );
        await tester.pumpWidget(RootRestorationScope(
          restorationId: 'root',
          child: _wrap(widget),
        ));
        expect(find.text('foo bar'), findsOneWidget);
        expect(find.text('baz buzz'), findsNothing);
        expect(find.textContaining('headline 2'), findsOneWidget);
        expect(find.text('bazinga'), findsNothing);
        await tester.tap(find.byType(OrgHeadlineWidget).last);
        await tester.pumpAndSettle();
        expect(find.text('foo bar'), findsOneWidget);
        expect(find.text('baz buzz'), findsNothing);
        expect(find.textContaining('headline 2'), findsOneWidget);
        expect(find.text('bazinga'), findsOneWidget);
        await tester.restartAndRestore();
        expect(find.text('foo bar'), findsOneWidget);
        expect(find.text('baz buzz'), findsNothing);
        expect(find.textContaining('headline 2'), findsOneWidget);
        expect(find.text('bazinga'), findsOneWidget);
      });
    });
    group('Events', () {
      testWidgets('Load images', (tester) async {
        var invoked = false;
        await tester.pumpWidget(_wrap(Org(
          'file:./foo.png',
          loadImage: (link) {
            invoked = true;
            expect(link.location, 'file:./foo.png');
            return null;
          },
        )));
        expect(invoked, isTrue);
      });
      testWidgets('Tap link', (tester) async {
        var invoked = false;
        await tester.pumpWidget(_wrap(Org(
          '[[http://example.com][example]]',
          onLinkTap: (link) {
            invoked = true;
            expect(link.location, 'http://example.com');
          },
        )));
        await tester.tapOnText(find.textRange.ofSubstring('example'));
        await tester.pump();
        expect(invoked, isTrue);
      });
      group('Tap local sections link', () {
        testWidgets('By title', (tester) async {
          var invoked = false;
          await tester.pumpWidget(_wrap(Org(
            '''
[[*Foo][link]]
* Foo
bar
''',
            onLocalSectionLinkTap: (section) {
              invoked = true;
              expect(section.toMarkup(), '* Foo\nbar\n');
            },
          )));
          await tester.tapOnText(find.textRange.ofSubstring('link'));
          await tester.pump();
          expect(invoked, isTrue);
        });
        testWidgets('By ID', (tester) async {
          var invoked = false;
          await tester.pumpWidget(_wrap(Org(
            '''
[[id:foo][link]]
* Bar
:PROPERTIES:
:ID: foo
:END:
''',
            onLocalSectionLinkTap: (section) {
              invoked = true;
              expect(
                section.toMarkup(),
                '* Bar\n:PROPERTIES:\n:ID: foo\n:END:\n',
              );
            },
          )));
          await tester.tapOnText(find.textRange.ofSubstring('link'));
          await tester.pump();
          expect(invoked, isTrue);
        });
        testWidgets('By custom ID', (tester) async {
          var invoked = false;
          await tester.pumpWidget(_wrap(Org(
            '''
[[#foo123][link]]
* Bar
:PROPERTIES:
:CUSTOM_ID: foo123
:END:
''',
            onLocalSectionLinkTap: (section) {
              invoked = true;
              expect(
                section.toMarkup(),
                '* Bar\n:PROPERTIES:\n:CUSTOM_ID: foo123\n:END:\n',
              );
            },
          )));
          await tester.tapOnText(find.textRange.ofSubstring('link'));
          await tester.pump();
          expect(invoked, isTrue);
        });
        testWidgets('Root by ID', (tester) async {
          var invoked = false;
          await tester.pumpWidget(_wrap(Org(
            '''
:PROPERTIES:
:ID: foo
:END:
* Bar
[[id:foo][link]]
''',
            onLocalSectionLinkTap: (section) {
              invoked = true;
              expect(
                section.toMarkup(),
                ':PROPERTIES:\n:ID: foo\n:END:\n* Bar\n[[id:foo][link]]\n',
              );
            },
          )));
          await tester.tap(find.byType(OrgHeadlineWidget));
          await tester.pumpAndSettle();
          await tester.tapOnText(find.textRange.ofSubstring('link'));
          await tester.pumpAndSettle();
          expect(invoked, isTrue);
        });
        testWidgets('Root by custom ID', (tester) async {
          var invoked = false;
          await tester.pumpWidget(_wrap(Org(
            '''
:PROPERTIES:
:CUSTOM_ID: foo123
:END:
* Bar
[[#foo123][link]]
''',
            onLocalSectionLinkTap: (section) {
              invoked = true;
              expect(
                section.toMarkup(),
                ':PROPERTIES:\n:CUSTOM_ID: foo123\n:END:\n* Bar\n[[#foo123][link]]\n',
              );
            },
          )));
          await tester.tap(find.byType(OrgHeadlineWidget));
          await tester.pumpAndSettle();
          await tester.tapOnText(find.textRange.ofSubstring('link'));
          await tester.pumpAndSettle();
          expect(invoked, isTrue);
        });
      });
      testWidgets('Long press section', (tester) async {
        var invoked = false;
        await tester.pumpWidget(_wrap(Org(
          '* Foo',
          onSectionLongPress: (section) {
            invoked = true;
            expect(section.toMarkup(), '* Foo');
          },
        )));
        await tester.longPress(find.text('* Foo'));
        await tester.pump();
        expect(invoked, isTrue);
      });
      testWidgets('Slide section', (tester) async {
        var onSectionSlideInvoked = false;
        var onPressedInvoked = false;
        await tester.pumpWidget(_wrap(Org(
          '* Foo',
          onSectionSlide: (section) {
            onSectionSlideInvoked = true;
            expect(section.toMarkup(), '* Foo');
            return [
              IconButton(
                icon: const Icon(Icons.abc),
                onPressed: () => onPressedInvoked = true,
              )
            ];
          },
        )));
        await tester.drag(find.text('* Foo'), const Offset(-100, 0));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.abc));
        expect(onSectionSlideInvoked, isTrue);
        expect(onPressedInvoked, isTrue);
      });
      testWidgets('List item tap', (tester) async {
        var invoked = false;
        await tester.pumpWidget(_wrap(Org(
          '- [ ] foo',
          onListItemTap: (item) {
            invoked = true;
            expect(item.toMarkup(), '- [ ] foo');
          },
        )));
        await tester.tap(find.textContaining('[ ]'));
        await tester.pump();
        expect(invoked, isTrue);
      });
    });
    group('Search', () {
      group('Results', () {
        testWidgets('No query', (tester) async {
          final doc = OrgDocument.parse('foo bar baz');
          final widget = OrgController(
            root: doc,
            child: OrgRootWidget(
              child: OrgDocumentWidget(doc),
            ),
          );
          await tester.pumpWidget(_wrap(widget));
          final controller = OrgController.of(
              tester.element(find.textContaining('foo bar baz')));
          expect(controller.searchResultKeys.value.length, 0);
        });
        testWidgets('One result', (tester) async {
          final doc = OrgDocument.parse('foo bar baz');
          final widget = OrgController(
            root: doc,
            searchQuery: 'bar',
            child: OrgRootWidget(
              child: OrgDocumentWidget(doc),
            ),
          );
          await tester.pumpWidget(_wrap(widget));
          final controller =
              OrgController.of(tester.element(find.textContaining('foo')));
          expect(controller.searchResultKeys.value.length, 1);
        });
        testWidgets('Multiple results', (tester) async {
          final doc = OrgDocument.parse('foo bar baz');
          final widget = OrgController(
            root: doc,
            searchQuery: RegExp('ba[rz]'),
            child: OrgRootWidget(
              child: OrgDocumentWidget(doc),
            ),
          );
          await tester.pumpWidget(_wrap(widget));
          final controller =
              OrgController.of(tester.element(find.textContaining('foo')));
          expect(controller.searchResultKeys.value.length, 2);
        });
      });
      group('Visibility', () {
        testWidgets('No query', (tester) async {
          final doc = OrgDocument.parse('''foo1
* bar
foo2
** baz
foo3''');
          final widget = OrgController(
            root: doc,
            child: OrgRootWidget(
              child: OrgDocumentWidget(doc),
            ),
          );
          await tester.pumpWidget(_wrap(widget));
          expect(find.textContaining('foo1'), findsOneWidget);
          expect(find.textContaining('foo2'), findsNothing);
          expect(find.textContaining('foo3'), findsNothing);
        });
        testWidgets('Nested hits', (tester) async {
          final doc = OrgDocument.parse('''foo1
* bar
foo2
** baz
foo3''');
          final widget = OrgController(
            root: doc,
            searchQuery: RegExp('foo[123]'),
            child: OrgRootWidget(
              child: OrgDocumentWidget(doc),
            ),
          );
          await tester.pumpWidget(_wrap(widget));
          expect(find.textContaining('foo1'), findsOneWidget);
          expect(find.textContaining('foo2'), findsOneWidget);
          expect(find.textContaining('foo3'), findsOneWidget);
        });
      });
    });
    group('Section matcher', () {
      testWidgets('Keyword', (tester) async {
        final doc = OrgDocument.parse('''foo1
* foo
** TODO bar
foo2
** DONE baz
foo3''');
        final widget = OrgController(
          root: doc,
          sparseQuery: OrgQueryMatcher.fromMarkup('TODO="TODO"'),
          child: OrgRootWidget(
            child: OrgDocumentWidget(doc),
          ),
        );
        await tester.pumpWidget(_wrap(widget));
        expect(find.textContaining('foo1'), findsOneWidget);
        expect(find.textContaining('bar'), findsOneWidget);
        expect(find.textContaining('foo2'), findsNothing);
        expect(find.textContaining('foo3'), findsNothing);
      });
      testWidgets('Tag', (tester) async {
        final doc = OrgDocument.parse('''foo1
* foo
** bar
foo2
** baz :buzz:
foo3''');
        final widget = OrgController(
          root: doc,
          sparseQuery: const OrgQueryTagMatcher('buzz'),
          child: OrgRootWidget(
            child: OrgDocumentWidget(doc),
          ),
        );
        await tester.pumpWidget(_wrap(widget));
        expect(find.textContaining('foo1'), findsOneWidget);
        expect(find.textContaining('foo2'), findsNothing);
        expect(find.textContaining('baz'), findsOneWidget);
        expect(find.textContaining('foo3'), findsNothing);
      });
      group('With search', () {
        testWidgets('With hit', (tester) async {
          final doc = OrgDocument.parse('''foo1
* foo
** TODO bar
foo2
** DONE baz
foo3''');
          final widget = OrgController(
            root: doc,
            sparseQuery: OrgQueryMatcher.fromMarkup('TODO="TODO"'),
            searchQuery: 'foo2',
            child: OrgRootWidget(
              child: OrgDocumentWidget(doc),
            ),
          );
          await tester.pumpWidget(_wrap(widget));
          expect(find.textContaining('foo1'), findsOneWidget);
          expect(find.textContaining('bar'), findsOneWidget);
          expect(find.textContaining('foo2'), findsOneWidget);
          expect(find.textContaining('foo3'), findsNothing);
        });
        testWidgets('No hits', (tester) async {
          final doc = OrgDocument.parse('''foo1
* foo
** TODO bar
foo2
** DONE baz
foo3''');
          final widget = OrgController(
            root: doc,
            sparseQuery: OrgQueryMatcher.fromMarkup('TODO="TODO"'),
            searchQuery: 'foo3',
            child: OrgRootWidget(
              child: OrgDocumentWidget(doc),
            ),
          );
          await tester.pumpWidget(_wrap(widget));
          expect(find.textContaining('foo1'), findsOneWidget);
          expect(find.textContaining('foo2'), findsNothing);
          expect(find.textContaining('foo3'), findsNothing);
        });
      });
    });
    group('Footnotes', () {
      testWidgets('Keys', (tester) async {
        await tester.pumpWidget(_wrap(const Org('''
foo[fn:1]

[fn:1] bar baz''')));
        final controller =
            OrgController.of(tester.element(find.textContaining('foo')));
        expect(controller.footnoteKeys.value.length, 2);
      });
      testWidgets('Visibility', (tester) async {
        await tester.pumpWidget(_wrap(const Org('''
foo[fn:1]

* bar baz
[fn:1] bazinga''')));
        expect(find.textContaining('bazinga'), findsNothing);
        await tester.tap(find.textContaining('fn:1').first);
        await tester.pump();
        expect(find.textContaining('bazinga'), findsOneWidget);
      });
    });
  });
  group('OrgText widget', () {
    group('Events', () {
      testWidgets('Load images', (tester) async {
        var invoked = false;
        await tester.pumpWidget(_wrap(OrgText(
          'file:./foo.png',
          loadImage: (link) {
            invoked = true;
            expect(link.location, 'file:./foo.png');
            return null;
          },
        )));
        expect(invoked, isTrue);
      });
      testWidgets('Tap link', (tester) async {
        var invoked = false;
        await tester.pumpWidget(_wrap(OrgText(
          '[[http://example.com][example]]',
          onLinkTap: (link) {
            invoked = true;
            expect(link.location, 'http://example.com');
          },
        )));
        await tester.tapOnText(find.textRange.ofSubstring('example'));
        await tester.pump();
        expect(invoked, isTrue);
      });
    });
  });
  group('Local variables', () {
    testWidgets('Custom entities', (tester) async {
      final doc = OrgDocument.parse(r'''
foo \pineapple bar

# Local Variables:
# org-entities-user: (("pineapple" "[p]" nil "&#127821;" "[p]" "[p]" "🍍"))
# End:
''');
      final widget = OrgController(
        root: doc,
        interpretEmbeddedSettings: true,
        errorHandler: (e) {
          fail(e.toString());
        },
        child: OrgRootWidget(
          child: OrgDocumentWidget(doc),
        ),
      );
      await tester.pumpWidget(_wrap(widget));
      expect(find.textContaining('foo \u{1f34d} bar'), findsOneWidget);
    });
    testWidgets('Disable entities', (tester) async {
      final doc = OrgDocument.parse(r'''
foo \smiley bar

# Local Variables:
# org-pretty-entities: nil
# End:
''');
      final widget = OrgController(
        root: doc,
        interpretEmbeddedSettings: true,
        errorHandler: (e) {
          fail(e.toString());
        },
        child: OrgRootWidget(
          child: OrgDocumentWidget(doc),
        ),
      );
      await tester.pumpWidget(_wrap(widget));
      expect(find.textContaining('foo'), findsOneWidget);
      expect(find.textContaining('☺'), findsNothing);
    });
    testWidgets('Hide markup', (tester) async {
      final doc = OrgDocument.parse(r'''
foo *bar* baz

# Local Variables:
# org-hide-emphasis-markers: t
# End:
''');
      final widget = OrgController(
        root: doc,
        interpretEmbeddedSettings: true,
        errorHandler: (e) {
          fail(e.toString());
        },
        child: OrgRootWidget(
          child: OrgDocumentWidget(doc),
        ),
      );
      await tester.pumpWidget(_wrap(widget));
      expect(find.textContaining('foo bar baz'), findsOneWidget);
      expect(find.textContaining('foo *bar* baz'), findsNothing);
    });
  });
  group('Keyword settings', () {
    testWidgets('Blocks start closed', (tester) async {
      final doc = OrgDocument.parse(r'''
#+begin_example
foo bar
#+end_example

#+STARTUP: hideblocks
''');
      final widget = OrgController(
        root: doc,
        interpretEmbeddedSettings: true,
        errorHandler: (e) {
          fail(e.toString());
        },
        child: OrgRootWidget(
          child: OrgDocumentWidget(doc),
        ),
      );
      await tester.pumpWidget(_wrap(widget));
      expect(find.textContaining('foo bar'), findsNothing);
    });
    testWidgets('Blocks start open', (tester) async {
      final doc = OrgDocument.parse(r'''
#+begin_example
foo bar
#+end_example

#+STARTUP: nohideblocks
''');
      final widget = OrgController(
        root: doc,
        interpretEmbeddedSettings: true,
        errorHandler: (e) {
          fail(e.toString());
        },
        child: OrgRootWidget(
          child: OrgDocumentWidget(doc),
        ),
      );
      await tester.pumpWidget(_wrap(widget));
      expect(find.textContaining('foo bar'), findsOneWidget);
    });
    testWidgets('Drawers start open', (tester) async {
      final doc = OrgDocument.parse(r'''
:PROPERTIES:
:foo: bar
:END:

#+STARTUP: nohidedrawers
''');
      final widget = OrgController(
        root: doc,
        interpretEmbeddedSettings: true,
        errorHandler: (e) {
          fail(e.toString());
        },
        child: OrgRootWidget(
          child: OrgDocumentWidget(doc),
        ),
      );
      await tester.pumpWidget(_wrap(widget));
      expect(find.textContaining(':foo: bar'), findsOneWidget);
    });
    testWidgets('Drawers start closed', (tester) async {
      final doc = OrgDocument.parse(r'''
:PROPERTIES:
:foo: bar
:END:

#+STARTUP: hidedrawers
''');
      final widget = OrgController(
        root: doc,
        interpretEmbeddedSettings: true,
        errorHandler: (e) {
          fail(e.toString());
        },
        child: OrgRootWidget(
          child: OrgDocumentWidget(doc),
        ),
      );
      await tester.pumpWidget(_wrap(widget));
      expect(find.textContaining(':foo: bar'), findsNothing);
    });
    testWidgets('Sections start open', (tester) async {
      final doc = OrgDocument.parse(r'''
foo

* bar
  baz
#+STARTUP: showeverything
''');
      final widget = OrgController(
        root: doc,
        interpretEmbeddedSettings: true,
        errorHandler: (e) {
          fail(e.toString());
        },
        child: OrgRootWidget(
          child: OrgDocumentWidget(doc),
        ),
      );
      await tester.pumpWidget(_wrap(widget));
      expect(find.textContaining('baz'), findsOneWidget);
    });
    testWidgets('Sections start closed', (tester) async {
      final doc = OrgDocument.parse(r'''
foo

* bar
  baz
#+STARTUP: overview
''');
      final widget = OrgController(
        root: doc,
        interpretEmbeddedSettings: true,
        errorHandler: (e) {
          fail(e.toString());
        },
        child: OrgRootWidget(
          child: OrgDocumentWidget(doc),
        ),
      );
      await tester.pumpWidget(_wrap(widget));
      expect(find.textContaining('baz'), findsNothing);
    });
    testWidgets('Showeverything overrides hideblocks, hidedrawers',
        (tester) async {
      final doc = OrgDocument.parse(r'''
:PROPERTIES:
:foo: bar
:END:

#+begin_example
biz baz
#+end_example

#+STARTUP: showeverything hideblocks hidedrawers
''');
      final widget = OrgController(
        root: doc,
        interpretEmbeddedSettings: true,
        errorHandler: (e) {
          fail(e.toString());
        },
        child: OrgRootWidget(
          child: OrgDocumentWidget(doc),
        ),
      );
      await tester.pumpWidget(_wrap(widget));
      expect(find.textContaining(':foo: bar'), findsOneWidget);
      expect(find.textContaining('biz baz'), findsOneWidget);
    });
    testWidgets('Hide stars', (tester) async {
      final doc = OrgDocument.parse(r'''
* foo
** bar
*** baz

#+STARTUP: showeverything hidestars
''');
      final widget = OrgController(
        root: doc,
        interpretEmbeddedSettings: true,
        errorHandler: (e) {
          fail(e.toString());
        },
        child: OrgRootWidget(
          child: OrgDocumentWidget(doc),
        ),
      );
      await tester.pumpWidget(_wrap(widget));
      expect(find.textContaining('* foo'), findsOneWidget);
      expect(find.textContaining('** bar'), findsNothing);
      expect(find.textContaining(' * bar'), findsOneWidget);
      expect(find.textContaining('*** baz'), findsNothing);
      expect(find.textContaining('  * baz'), findsOneWidget);
    });
    testWidgets('Disable entities', (tester) async {
      final doc = OrgDocument.parse(r'''
foo \smiley bar

#+STARTUP: entitiesplain
''');
      final widget = OrgController(
        root: doc,
        interpretEmbeddedSettings: true,
        errorHandler: (e) {
          fail(e.toString());
        },
        child: OrgRootWidget(
          child: OrgDocumentWidget(doc),
        ),
      );
      await tester.pumpWidget(_wrap(widget));
      expect(find.textContaining('foo'), findsOneWidget);
      expect(find.textContaining('☺'), findsNothing);
    });
    testWidgets('Disable inline images', (tester) async {
      final doc = OrgDocument.parse(r'''
file:./foo.png

#+STARTUP: noinlineimages
''');
      final widget = OrgController(
        root: doc,
        interpretEmbeddedSettings: true,
        errorHandler: (e) {
          fail(e.toString());
        },
        child: OrgRootWidget(
          loadImage: (_) => fail('Should not be invoked'),
          child: OrgDocumentWidget(doc),
        ),
      );
      await tester.pumpWidget(_wrap(widget));
    });
  });
}

/* Put a pagebreak here so Emacs doesn't bother us about the Local Variables
lists in the tests

*/
