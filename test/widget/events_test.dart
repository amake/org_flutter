import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';

import './util.dart';

void main() {
  group('Events', () {
    group('Org widget', () {
      testWidgets('Load images', (tester) async {
        var invoked = false;
        await tester.pumpWidget(wrap(Org(
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
        await tester.pumpWidget(wrap(Org(
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
          await tester.pumpWidget(wrap(Org(
            '''
[[*Foo][link]]
* Foo
bar
''',
            onLocalSectionLinkTap: (section, {searchOption}) {
              invoked = true;
              expect(section.toMarkup(), '* Foo\nbar\n');
              expect(searchOption, isNull);
            },
          )));
          await tester.tapOnText(find.textRange.ofSubstring('link'));
          await tester.pump();
          expect(invoked, isTrue);
        });
        testWidgets('By ID', (tester) async {
          var invoked = false;
          await tester.pumpWidget(wrap(Org(
            '''
[[id:foo][link]]
* Bar
:PROPERTIES:
:ID: foo
:END:
''',
            onLocalSectionLinkTap: (section, {searchOption}) {
              invoked = true;
              expect(
                section.toMarkup(),
                '* Bar\n:PROPERTIES:\n:ID: foo\n:END:\n',
              );
              expect(searchOption, isNull);
            },
          )));
          await tester.tapOnText(find.textRange.ofSubstring('link'));
          await tester.pump();
          expect(invoked, isTrue);
        });
        testWidgets('By ID with search option', (tester) async {
          var invoked = false;
          await tester.pumpWidget(wrap(Org(
            '''
[[id:foo::bar][link]]
* Bar
:PROPERTIES:
:ID: foo
:END:
''',
            onLocalSectionLinkTap: (section, {searchOption}) {
              invoked = true;
              expect(
                section.toMarkup(),
                '* Bar\n:PROPERTIES:\n:ID: foo\n:END:\n',
              );
              expect(searchOption, 'bar');
            },
          )));
          await tester.tapOnText(find.textRange.ofSubstring('link'));
          await tester.pump();
          expect(invoked, isTrue);
        });
        testWidgets('By custom ID', (tester) async {
          var invoked = false;
          await tester.pumpWidget(wrap(Org(
            '''
[[#foo123][link]]
* Bar
:PROPERTIES:
:CUSTOM_ID: foo123
:END:
''',
            onLocalSectionLinkTap: (section, {searchOption}) {
              invoked = true;
              expect(
                section.toMarkup(),
                '* Bar\n:PROPERTIES:\n:CUSTOM_ID: foo123\n:END:\n',
              );
              expect(searchOption, isNull);
            },
          )));
          await tester.tapOnText(find.textRange.ofSubstring('link'));
          await tester.pump();
          expect(invoked, isTrue);
        });
        testWidgets('By present named target', (tester) async {
          var invoked = false;
          await tester.pumpWidget(wrap(Org(
            '''
[[foo][link]]

#+NAME: foo
''',
            onLocalSectionLinkTap: (section, {searchOption}) {
              fail('Should not be invoked');
            },
            onLinkTap: (link) {
              fail('Should not be invoked');
            },
          )));
          await tester.tapOnText(find.textRange.ofSubstring('link'));
          await tester.pumpAndSettle();
          expect(invoked, isFalse);
        });
        testWidgets('By absent named/link target', (tester) async {
          var invoked = false;
          await tester.pumpWidget(wrap(Org(
            '''
[[foo][link]]
''',
            onLocalSectionLinkTap: (section, {searchOption}) {
              fail('Should not be invoked');
            },
            onLinkTap: (link) {
              invoked = true;
              expect(link.location, 'foo');
            },
          )));
          await tester.tapOnText(find.textRange.ofSubstring('link'));
          await tester.pumpAndSettle();
          expect(invoked, isTrue);
        });
        testWidgets('By present link target', (tester) async {
          var invoked = false;
          await tester.pumpWidget(wrap(Org(
            '''
[[foo][link]]

<<foo>>
''',
            onLocalSectionLinkTap: (section, {searchOption}) {
              fail('Should not be invoked');
            },
            onLinkTap: (link) {
              fail('Should not be invoked');
            },
          )));
          await tester.tapOnText(find.textRange.ofSubstring('link'));
          await tester.pumpAndSettle();
          expect(invoked, isFalse);
        });
        testWidgets('By present coderef target', (tester) async {
          var invoked = false;
          await tester.pumpWidget(wrap(Org(
            '''
[[(foo)][link]]

#+BEGIN_SRC emacs-lisp -n -r
  (bar)                 (ref:foo)
#+END_SRC
''',
            onLocalSectionLinkTap: (section, {searchOption}) {
              fail('Should not be invoked');
            },
            onLinkTap: (link) {
              fail('Should not be invoked');
            },
          )));
          await tester.tapOnText(find.textRange.ofSubstring('link'));
          await tester.pumpAndSettle();
          expect(invoked, isFalse);
        });
        testWidgets('By absent coderef target', (tester) async {
          var invoked = false;
          await tester.pumpWidget(wrap(Org(
            '''
[[(foo)][link]]
''',
            onLocalSectionLinkTap: (section, {searchOption}) {
              fail('Should not be invoked');
            },
            onLinkTap: (link) {
              invoked = true;
              expect(link.location, '(foo)');
            },
          )));
          await tester.tapOnText(find.textRange.ofSubstring('link'));
          await tester.pumpAndSettle();
          expect(invoked, isTrue);
        });

        testWidgets('Root by ID', (tester) async {
          var invoked = false;
          await tester.pumpWidget(wrap(Org(
            '''
:PROPERTIES:
:ID: foo
:END:
* Bar
[[id:foo][link]]
''',
            onLocalSectionLinkTap: (section, {searchOption}) {
              invoked = true;
              expect(
                section.toMarkup(),
                ':PROPERTIES:\n:ID: foo\n:END:\n* Bar\n[[id:foo][link]]\n',
              );
              expect(searchOption, isNull);
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
          await tester.pumpWidget(wrap(Org(
            '''
:PROPERTIES:
:CUSTOM_ID: foo123
:END:
* Bar
[[#foo123][link]]
''',
            onLocalSectionLinkTap: (section, {searchOption}) {
              invoked = true;
              expect(
                section.toMarkup(),
                ':PROPERTIES:\n:CUSTOM_ID: foo123\n:END:\n* Bar\n[[#foo123][link]]\n',
              );
              expect(searchOption, isNull);
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
        await tester.pumpWidget(wrap(Org(
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
        await tester.pumpWidget(wrap(Org(
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
        await tester.pumpWidget(wrap(Org(
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

    group('OrgText widget', () {
      testWidgets('Load images', (tester) async {
        var invoked = false;
        await tester.pumpWidget(wrap(OrgText(
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
        await tester.pumpWidget(wrap(OrgText(
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
}
