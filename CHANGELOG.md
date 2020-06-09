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
