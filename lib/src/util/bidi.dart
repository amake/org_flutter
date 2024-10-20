import 'package:flutter/material.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:org_flutter/src/util/more_bidi.dart';

extension BidiUtil on OrgNode {
  TextDirection? detectTextDirection() {
    final serializer = OrgBidiDetectionSerializer();
    toMarkup(serializer: serializer);
    if (serializer.strongChar == null) return null;
    return UnicodeCharMatcher.bidiLeftToRight().match(serializer.strongChar!)
        ? TextDirection.ltr
        : TextDirection.rtl;
  }
}

class OrgBidiDetectionSerializer extends OrgSerializer {
  int? strongChar;
  bool canceled = false;

  @override
  void visit(OrgNode node) {
    if (canceled) return;
    super.visit(node);
  }

  @override
  void write(String str) {
    if (canceled) return;

    final idx = str.indexOf(UnicodeCharMatcher.bidiStrong());
    if (idx != -1) {
      canceled = true;
      strongChar = str.codeUnitAt(idx);
    }
    super.write(str);
  }
}
