import 'package:flutter/material.dart';
import 'package:org_parser/org_parser.dart';

enum OrgAlignment { left, center, right }

OrgAlignment? alignmentForNode(OrgNode node, OrgTree root) {
  // TODO(aaron): This is potentially expensive. Think of a better way to track
  // the path within the tree.
  var zipper = root.editNode(node);
  if (zipper == null) return null;
  while (!zipper!.canGoLeft()) {
    if (!zipper.canGoUp()) return null;
    zipper = zipper.goUp();
  }
  while (zipper!.canGoLeft()) {
    zipper = zipper.goLeft();
    final node = zipper.node;
    if (node is! OrgMeta) continue;
    if (node.key.toLowerCase() == '#+attr_org:') {
      final value = node.value?.toMarkup();
      if (value == null) continue;
      final plist = tokenizePlist(value);
      final alignment = plist.get(':align');
      if (alignment == null) continue;
      switch (alignment.toLowerCase()) {
        case 'left':
          return OrgAlignment.left;
        case 'center':
          return OrgAlignment.center;
        case 'right':
          return OrgAlignment.right;
      }
    }
  }
  return null;
}

typedef Plist = List<String>;

// TODO(aaron): Handle this properly, like with support for quoted strings.
Plist tokenizePlist(String plist) => plist
    .split(RegExp(r'\s+'))
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .toList(growable: false);

extension PlistExtension on Plist {
  String? get(String key) {
    for (var i = 0; i < length; i++) {
      final token = this[i];
      if (token.toLowerCase() == key) {
        if (i + 1 < length) {
          return this[i + 1];
        }
      }
    }
    return null;
  }
}

extension OrgAlignmentExtension on OrgAlignment {
  MainAxisAlignment get toMainAxisAlignment => switch (this) {
        OrgAlignment.left => MainAxisAlignment.start,
        OrgAlignment.center => MainAxisAlignment.center,
        OrgAlignment.right => MainAxisAlignment.end
      };
}
