import 'package:flutter/material.dart';
import 'package:org_flutter/src/util/more_bidi.dart';

extension BidiUtil on String {
  TextDirection? detectTextDirection() {
    final idx = indexOf(UnicodeCharMatcher.bidiStrong());
    if (idx == -1) return null;
    final c = codeUnitAt(idx);
    return UnicodeCharMatcher.bidiLeftToRight().match(c)
        ? TextDirection.ltr
        : TextDirection.rtl;
  }
}
