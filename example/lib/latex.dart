import 'package:flutter/foundation.dart';
import 'package:flutter_tex_js/flutter_tex_js.dart';
import 'package:material_ui/material_ui.dart';
import 'package:org_flutter/org_flutter.dart';

// LaTeX rendering with flutter_tex_js, as org_flutter itself did before it
// left rendering to the app. Pass these to `Org`, `OrgText` or
// `OrgRootWidget` as `loadLatexInline` and `loadLatexBlock`.
//
// `TexImage` takes its color and font size from the ambient
// `DefaultTextStyle`, which org_flutter sets to the surrounding text's style.

/// Whether flutter_tex_js has an implementation on this platform (Android and
/// iOS only). Elsewhere the callbacks return null, so org_flutter shows the
/// LaTeX source.
bool get _texSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// An inline LaTeX fragment such as `\(a^2\)`
InlineSpan? loadLatexInline(OrgLatexInline latex) {
  if (!_texSupported) return null;
  return WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: TexImage(
      latex.content,
      displayMode: false,
      error: (context, error) {
        debugPrint(error.toString());
        return Text(latex.toMarkup());
      },
    ),
  );
}

/// A LaTeX block such as `\begin{equation}...\end{equation}`
Widget? loadLatexBlock(OrgLatexBlock block) {
  if (!_texSupported) return null;
  return TexImage(
    flutterTexJsSupportedEnvironments.contains(block.environment)
        ? '${block.begin}${block.content}${block.end}'
        : block.content,
    displayMode: true,
    error: (context, error) {
      debugPrint(error.toString());
      return Text(block.toMarkup());
    },
  );
}
