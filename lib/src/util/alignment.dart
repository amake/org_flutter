import 'package:flutter/material.dart';
import 'package:org_parser/org_parser.dart';

enum OrgAlignment { left, center, right }

final _attrPattern = RegExp(r'^#\+attr(.*):$', caseSensitive: false);

OrgAlignment? alignmentForNode(OrgNode node, OrgTree root) {
  // TODO(aaron): This is potentially expensive. Think of a better way to track
  // the path within the tree.
  var zipper = root.editNode(node);
  if (zipper == null) return null;

  // For the document
  //
  // ```
  // #+ATTR_ORG: :align center
  // [[foo]]
  // ```
  //
  // the tree will look like:
  //
  //   OrgDocument: #+ATTR_ORG...
  //     OrgContent: #+ATTR_ORG...
  //       OrgMeta: #+ATTR_ORG...
  //         OrgContent:  :align ce...
  //           OrgPlainText:  :align ce...
  //       OrgParagraph: [[foo]]\n
  //         OrgContent: [[foo]]\n
  //           OrgLink: [[foo]]
  //           OrgPlainText: "\n"
  //
  // Instead of going up a fixed number of times, we go up until we can go left.
  // This is important because we don't want to detect alignment for things
  // inline within a paragraph.
  //
  // - Alignable item: alone in an OrgParagraph; must go up to the level that
  //   might have an OrgMeta sibling
  //
  // - Non-alignable item: will have siblings within OrgParagraph; will look at those
  //   and fail to find an OrgMeta (which is good)
  while (!zipper!.canGoLeft()) {
    if (!zipper.canGoUp()) return null;
    zipper = zipper.goUp();
  }

  OrgAlignment? result;
  while (zipper!.canGoLeft()) {
    zipper = zipper.goLeft();
    final node = zipper.node;
    if (node is! OrgMeta) continue;

    final match = _attrPattern.firstMatch(node.key);
    if (match == null) continue;
    final authoritative = match.group(1)?.toLowerCase() == '_org';

    final value = node.value?.toMarkup();
    if (value == null) continue;

    final plist = tokenizePlist(value);
    final center = plist.get(':center');
    if (center == 't') {
      result = OrgAlignment.center;
      if (authoritative) break;
    } else {
      final alignment = plist.get(':align');
      if (alignment == null) continue;
      switch (alignment.toLowerCase()) {
        case 'left':
          result = OrgAlignment.left;
        case 'center':
          result = OrgAlignment.center;
        case 'right':
          result = OrgAlignment.right;
      }
      if (authoritative) break;
    }
  }
  return result;
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
