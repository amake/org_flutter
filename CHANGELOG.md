## [10.0.0]
- Improve handling of links that point to sections or jumpable items within the
  document
- Return any search option alongside section in `onLocalSectionLinkTap` callback
- Bump org_parser to 10.0.0

## [9.11.0]
- Support hiding meta keywords via `org-hidden-keywords`

## [9.10.1]
- Export `OrgEvents`
- Minor tweaks

## [9.10.0]
- Support jumping to code references
- Allow simultaneous search hits and syntax highlighting in src blocks

## [9.9.0]
- Fix finding search hits in src blocks
- Require latest org_parser (9.9.1)

## [9.8.0]
- Support Org Num mode, via `#+STARTUP: num` or directly via `OrgSettings` API
- Fix coloring of :ARCHIVE: headlines

## [9.7.0]
- Improve block rendering

## [9.6.2]
- Don't show inline images for bracket links with descriptions

## [9.6.1]
- Respect `#+ATTR.*` for alignment (`#+ATTR_ORG` overrides others)
- Handle `:center t` in addition to `:align`

## [9.6.0]
- Respect `#+ATTR_ORG: :align` on inline images

## [9.5.0]
- Normalize handling of Org planning entries
- Stylize timestamp delimiter in date ranges

## [9.4.0]
- Block content rendering now better matches Org Mode in Emacs
- Support dynamic blocks

## [9.3.0]
- Visibility cycling behavior and headline styling for archived sections now
  matches that of Org Mode in Emacs

## [9.2.0]
- The document's effective value of `org-attach-id-dir` is now available from
  `OrgSettings.of(controller).orgAttachIdDir`. To read this from the document's
  local variables list, use `OrgController.interpretEmbeddedSettings`.

## [9.1.3]
- Fix indenting of block bodies with "negative" indent relative to their block
  delimiters

## [9.1.2]
- Fix deindenting outside of src blocks

## [9.1.1]
- Sub-indents are correctly preserved in deindented content

## [9.1.0]
- Settings are now accessed through `OrgSettings` instead of `OrgController`
  - Replace `OrgController.of(context).settings` with
    `OrgSettings.of(controller).settings`
  - Replace `OrgController.of(context).prettifyEntity` with
    `OrgSettings.of(controller).prettifyEntity`
- Only "strict" (delimited by `{}`) sub/superscripts are rendered in
  non-exported keywords. Exported keywords are, e.g. TITLE, AUTHOR, CAPTION

## [9.0.3]
- Fix error when rendering sub/superscripts in a meta line

## [9.0.2]
- Fix error when detecting bidi direction of text with astral codepoints

## [9.0.1]
- Fix regression on keyword value color

## [9.0.0]
- Render rich content in keyword lines
- Require Flutter 3.27+

## [8.7.1]
- Improve line wrapping

## [8.7.0]
- Improve line wrapping and text reflow

## [8.6.0]
- Support inline src blocks

## [8.5.0]
- Render rich content inside drawer property values

## [8.4.0]
- Improve parsing accuracy
- Fix trailing blank lines

## [8.3.0]
- Recognize .avif files as images

## [8.2.0]
- Render rich content inside links
- Bug fixes

## [8.1.0]
- Render rich content inside markups

## [8.0.1]
- Improve jumping behavior

## [8.0.0]
- Render radio targets and link targets
- Linkify radio links; jump to radio targets when opened
- Introduce `OrgLocator` to allow imperative jumping to footnotes, link targets,
  and named elements. Place it in your widget tree *under* `OrgController`.
- Jumped-to objects are briefly highlighted
- Jumped-to objects are more reliably made visible

## [7.13.2]
* Minor optimization

## [7.13.1] - 2024-11-23
* Improve table rendering

## [7.13.0] - 2024-11-22
* Respect the `org-pretty-entities-include-sub-superscripts` and
  `org-use-sub-superscripts` local variables
  * See also equivalent settings `subSuperscritps` and `strictSubSuperscripts`
    on `OrgSettings`

## [7.12.0] - 2024-11-18
* Render horizontal rules

## [7.11.1] - 2024-11-15
* Fix headline ellipses for headlines with no tags

## [7.11.0] - 2024-11-07
* Add `onTimestampTap` callback
* Fixed diary timestamp rendering

## [7.10.1] - 2024-11-05
* Identify document info meta lines case-insensitively

## [7.10.0] - 2024-11-05
* Style "document info" meta lines (`#+TITLE:`, etc.) accurately
* Allow scrolling meta lines when `OrgSettings.deemphasizeMarkup` is enabled

## [7.9.0] - 2024-11-03
* Support statistics cookies

## [7.8.3] - 2024-10-29
* Allow specifying a new `restorationId` in `OrgController.defaults`

## [7.8.2] - 2024-10-27
* Bug fixes

## [7.8.1] - 2024-10-23
* Upgrade dependencies

## [7.8.0] - 2024-10-22
* Detect text direction automatically
* Respect the `bidi-paragraph-direction` local variable

## [7.7.1] - 2024-10-19
* Fold whitespace between headline title and tags when the headline would not
  fit the available width as-is

## [7.7.0] - 2024-10-16
* Detect `#+LANGUAGE:` and set locale appropriately

## [7.6.0] - 2024-10-14
* Support entities in superscripts and subscripts
* All headline tags are now shown when the headline is open
* Headlines are rendered without special layout (tags aligned to the right) when
  text reflow is disabled

## [7.5.0] - 2024-10-12
* Render superscripts and subscripts. These are controlled by the same flags as
  entities.
* Local variables blocks, PGP blogs, and comments are now searchable

## [7.4.2] - 2024-10-09
* Fix extra space under drawers

## [7.4.1] - 2024-10-05
* Fix layout of inline widgets, especially images
* Fix indentation of list bodies when not using text reflow

## [7.4.0] - 2024-10-02
* Add `OrgLinkWidget`

## [7.3.0] - 2024-09-27
* Bump org_parser to 6.1.0 with support for Org Cite `[cite:@key]` citations
  * Provide an `onCitationTap` callback to `Org` etc., to handle taps
  * Customize the color with `OrgThemeData.citationColor`

## [7.2.0] - 2024-09-23
* Bump org_parser to 6.0.0 with support for `#+TODO:` keywords. See the Advanced
  example in the README.
* Expose TODO settings on `OrgSettings.todoSettings`
* Respect "in-progress" vs "done" keyword status in org_parser AST

## [7.1.0] - 2024-09-13
* Update dependencies for Flutter 3.26

## [7.0.0] - 2024-09-03
* `onLocalSectionLinkTap` can now return the root document as well

## [6.1.0] - 2024-08-28
* Add `setVisibilityOf`, `adaptVisibility` methods to `OrgControllerData`

## [6.0.3] - 2024-01-28
* Improve search behavior

## [6.0.2] - 2024-01-23
* Highlight headlines of sparse query matches
* Fix various sparse query matching bugs

## [6.0.1] - 2024-01-21
* Fix handling of queries in `OrgController.defaults`

## [6.0.0] - 2024-01-21
* Remove `OrgControllerData.search`. Supply your search query declaratively to
  `OrgController` constructors instead.
* Support "sparse trees"; see `OrgController.sparseQuery`

## [5.2.0] - 2023-12-24
* Render PGP blocks, comment lines, decrypted content

## [5.1.0] - 2023-12-10
* `onLinkTap` now returns an `OrgLink` object instead of the URL. See
  `OrgLink.location` for the URL.

## [5.0.1] - 2023-12-08
* Clear existing search result keys when performing a query

## [5.0.0] - 2023-12-05
* Support supplying swipe actions on `OrgSection`s: callers should provide an
  `Org.onSectionSlide` callback that returns widgets to display in the revealed
  region
* The `hideMarkup` flag is replaced in favor of an `OrgSettings` class allowing
  fine-grained control over each display effect, plus many new options
  * Use `OrgSettings.hideMarkup` for behavior equivalent to the old flag
* The `OrgController.of(context).hideMarkup` setter is removed; instead provide
  `OrgSettings` declaratively at the entrypoint
* Respect `org-pretty-entities`, `org-hide-emphasis-markers` in local variables
  list
* Respect `#+STARTUP` keywords:
  * `[no]hideblocks`
  * `[no]hidedrawers`
  * `hidestars`/`showstars`
  * `entitiespretty`/`entitiesplain`
  * `inlineimages`/`noinlineimages`
  * `[no]fold`/`overview`/`content`/`show[2..5]levels`/`showall`/`showeverything`

## [4.8.0] - 2023-11-23
* Improve Elisp compatibility, pin engine version to prevent unwanted upgrades

## [4.7.1] - 2023-11-20
* Prevent spurious Dart tooling crash
  ([#10](https://github.com/amake/org_flutter/issues/10))

## [4.7.0] - 2023-11-18
* Improved support for local variables

## [4.6.0] - 2023-11-06
* Receive information about errors via `OrgController.errorHandler`

## [4.5.0] - 2023-11-04
* Render [local variable
  lists](https://www.gnu.org/software/emacs/manual/html_node/emacs/Specifying-File-Variables.html)
* Optionally interpret `org-entities-user` (or `org-entities-local`) local
  variable definitions to customize the [entities
  list](https://orgmode.org/manual/Special-Symbols.html); see
  `OrgController.interpretEmbeddedSettings`

## [4.4.0] - 2023-10-14
* Expose `hideMarkup` option on `Org` and `OrgText` widgets

## [4.3.1] - 2023-09-22
* Remove disused dependency

## [4.3.0] - 2023-09-22
* Improve code block syntax highlighting (previously based on
  [highlight.js](https://highlightjs.org/) v9.18.1; now v11.8.0)
* Syntax-highlighted source blocks will now participate in text selection

## [4.2.0] - 2023-09-15
* Tap footnote references to jump between footnote definition and first
  reference

## [4.1.1] - 2023-09-12
* Fix Flutter SDK version requirement (3.14 beta has been required since 4.0)

## [4.1.0] - 2023-09-11
* Editing is now supported; see the example app
* Handle list item taps via the new `onListItemTap` callback
* `OrgThemeData.copyWith` now uses keyword args
* Bottom "safe area" padding on `OrgDocumentWidget` can now be disabled
* The new `OrgText` widget allows using an Org snippet as a rich `Text`
  equivalent

## [4.0.1] - 2023-08-29
* Fix bug in text reshaping

## [4.0.0] - 2023-08-22
* Upgrade to org_parser 4.0.0
* Require Flutter >=3.13.0, Dart >=3.0.0

## [3.1.0] - 2023-07-20
* The `loadImage` callback will be called for SVG links
* Text is no longer reflowed unless the `hideMarkup` option is enabled

## [3.0.0] - 2023-02-17
* Require iOS 11.0+

## [2.1.0] - 2023-01-15

* Track keys for search result spans, expose via `OrgControllerData`

  When performing a search with `OrgController.of(context).search`, after the
  widget build phase is complete you can access `SearchResultKey`s in
  `OrgController.of(context).searchResultKeys`.

## [2.0.0] - 2022-11-27

* Fix minor API issues
* Require Flutter >=2.14.0, Dart >=2.18

## [1.4.2] - 2022-02-28

* Fix null dereference when applying search query

## [1.4.1] - 2022-02-13

* Improve documentation

## [1.4.0] - 2021-05-13

* Handle `id:` and `#custom-id` links
* Add methods for resolving section links to `OrgControllerData`
  * `sectionWithId`
  * `sectionWithCustomId`
  * `sectionForTarget`

## [1.3.0] - 2021-04-19

* Relicense under the MIT License

## [1.2.0] - 2021-03-19

* Support loading images via `loadImage` callback supplied to `Org` or
  `OrgEvents`

## [1.1.1] - 2021-03-14

* Fix nullability issues with headline, src block
* `OrgTheme.of`, `OrgEvents.of` now return non-nullable instances; they will
  throw if the expected widgets are not present in the supplied context

## [1.1.0] - 2021-03-11

* Support automatic [state restoration](https://flutter.dev/go/state-restoration-design)
  * Manual state management facilities `initialState` and `stateListener` on
    `OrgController` have been removed
  * Instead provide `restorationId` to `Org` or `OrgController`

## [1.0.0] - 2021-03-11

* Migrate to non-nullable by default

## [0.10.0] - 2021-03-03

* Property lines, planning/clock lines no longer wrap

## [0.9.0] - 2021-02-16

* Fix handling of drawer content
* Handle planning/clock lines as separate elements

## [0.8.1] - 2020-12-02

* Take theme brightness from current `ThemeData`, not `MediaQuery`

## [0.8.0] - 2020-08-26

* Change effects of `hideMarkup` option:
  * Drawers and meta lines no longer hidden, but rather faded (reduced opacity)
  * Block headers, meta lines truncated to fit document width with no wrapping

## [0.7.0] - 2020-07-22

* Prettify org entities

## [0.6.2] - 2020-07-16

* Update flutter_tex_js to v0.1.1 (LaTeX fragments now follow ambient font size)

## [0.6.1] - 2020-07-16

* Fix extraneous line break following LaTeX block

## [0.6.0] - 2020-07-15

* Support LaTeX inline and block fragments

## [0.5.2] - 2020-06-28

* Add `shrinkWrap` option to `OrgDocumentWidget` and `OrgSectionWidget`

## [0.5.1] - 2020-06-22

* Fix error handling source blocks with no language specification

## [0.5.0] - 2020-06-22

* Highlight syntax in source blocks

## [0.4.2] - 2020-06-09

* Fix headline layout with long tags

## [0.4.1] - 2020-06-04

* Replace `OrgControllerData.initialScrollOffset` with
  `OrgControllerData.scrollController`

## [0.4.0] - 2020-06-03

* Changes to `OrgControllerData` members
  * E.g. `OrgController.of(context).hideMarkup` is now a setter/getter rather
    than a `ValueNotifier`
* Add ability to save/restore transient view state (currently section
  visibilities, scroll position)
  * See `initialState`, `stateListener` args to `OrgController` constructor

## [0.3.1] - 2020-05-23

* Add `hideMarkup` argument to `OrgController` constructor

## [0.3.0+1] - 2020-05-21

* Add example

## [0.3.0] - 2020-05-15

* Pad root view to safe area
* Inherit visibility state when narrowing
* Various refactoring

## [0.2.1] - 2020-05-09

* Fix color of inline footnote body

## [0.2.0] - 2020-05-08

* Fix table width
* Fix block, drawer trailing space when collapsed
* Only break link text by character when the text is (probably) a URL
* Use a ListView as document/section root
* Set document padding in theme: see `OrgThemeData.rootPadding`

## [0.1.1] - 2020-05-06

* Right-align table columns that are primarily numeric

## [0.1.0] - 2020-05-05

* Initial release
