# org_flutter

[Org Mode](https://orgmode.org/) widgets for Flutter.

# Usage

For parsing Org Mode documents, see
[org_parser](https://github.com/amake/org_parser). For an example application
that displays Org Mode documents with org_parser and org_flutter, see
[Orgro](https://orgro.org).

The simplest way to display an Org Mode document in your Flutter application is
to use the `Org` widget:

```dart
import 'package:org_flutter/org_flutter.dart';

class MyOrgViewWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return Org('''* TODO [#A] foo bar
baz buzz''');
  }
}
```

See the [example](./example/lib/main.dart) for more.

## Rich text

Use Org markup to create rich `Text`-equivalent widgets with `OrgText`.

```dart
OrgText('*This* is a /rich/ text label ([[https://example.com][details]])')
```

## Advanced

For more advanced usage, such as specifying link handling, use `OrgController`
in concert with `OrgRootWidget`:

```dart
import 'package:org_flutter/org_flutter.dart';

Widget build(BuildContext context) {
  final doc = OrgDocument.parse(rawOrgModeDocString);
  return OrgController(
    root: doc,
    child: OrgRootWidget(
      style: myTextStyle,
      onLinkTap: launch, // e.g. from url_launcher package
      child: OrgDocumentWidget(doc),
    ),
  );
}
```

Place `OrgController` higher up in your widget hierarchy and access via
`OrgController.of(context)` to dynamically control various properties of the
displayed document:

```dart
IconButton(
  icon: const Icon(Icons.repeat),
  onPressed: OrgController.of(context).cycleVisibility,
);
```

## Text selection

The Org Mode text is not selectable by default, but you can make it so by
wrapping the widget in
[`SelectionArea`](https://api.flutter.dev/flutter/material/SelectionArea-class.html).
