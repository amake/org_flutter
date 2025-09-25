import 'package:org_flutter/org_flutter.dart';

// See org-element-src-block-parser
final _labelFmtPattern = RegExp(r'-l +"(?<format>[^"]+)"');

// See org-coderef-label-format
const _coderefLabelFormat = '(ref:%s)';

extension OrgSrcBlockUtils on OrgSrcBlock {
  String coderefFormat() {
    final match = _labelFmtPattern.firstMatch(header);
    return match?.namedGroup('format') ?? _coderefLabelFormat;
  }

  /// The matched name is in the 'name' named group.
  RegExp coderefPattern() {
    final format = coderefFormat();
    final pattern = RegExp(RegExp.escape(format)
        // See org-src-coderef-regexp
        .replaceAll('%s', r'(?<name>[-a-zA-Z0-9_][-a-zA-Z0-9_ ]*)'));
    return pattern;
  }

  bool hasCoderef(String name) {
    final format = coderefFormat();
    final pattern = RegExp(RegExp.escape(format).replaceAll('%s', name));
    final haystack = (body as OrgPlainText).content;
    return pattern.hasMatch(haystack);
  }
}
