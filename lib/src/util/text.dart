import 'dart:math';

import 'package:org_flutter/src/util/collection.dart';

/// If necessary, interleave runes with U+200B ZERO WIDTH SPACE to serve as a
/// place to wrap the line.
String characterWrappable(String text) {
  if (text.contains(' ')) {
    return text;
  } else {
    return String.fromCharCodes(interleave(text.runes, 0x200b));
  }
}

extension PatternUtil on Pattern? {
  bool get isEmpty {
    final self = this;
    if (self is String) {
      return self.isEmpty;
    } else if (self is RegExp) {
      return self.pattern.isEmpty;
    } else {
      return self == null;
    }
  }

  bool get isNotEmpty => !isEmpty;

  bool sameAs(Pattern? other) {
    final self = this;
    if (self == other) {
      return true;
    }
    if (self is RegExp && other is RegExp) {
      return self.pattern == other.pattern &&
          self.isCaseSensitive == other.isCaseSensitive &&
          self.isDotAll == other.isDotAll &&
          self.isMultiLine == other.isMultiLine &&
          self.isUnicode == other.isUnicode;
    }
    return false;
  }
}

String removeTrailingLineBreak(String text) {
  if (text.endsWith('\n')) {
    if (text.endsWith('\r\n')) {
      return text.substring(0, text.length - 2);
    } else {
      return text.substring(0, text.length - 1);
    }
  } else {
    return text;
  }
}

// Remove [deindentSize] spaces from the start of each line. If a line doesn't
// have that many spaces, it is left unchanged.
String hardDeindent(String text, int deindentSize) =>
    text.replaceAll(_deindentPattern(deindentSize), '');

// Remove at spaces from the start of each line. The amount removed is the
// smaller of [deindentSize] and the current indent of the entire text.
String softDeindent(String text, int deindentSize) {
  if (deindentSize == 0) return text;
  final currentIndent = detectIndent(text);
  final effectiveDeindentSize = min(currentIndent, deindentSize);
  return text.replaceAll(_deindentPattern(effectiveDeindentSize), '');
}

int detectIndent(String text) {
  var result = -1;
  for (var i = 0; i >= 0 && i < text.length;) {
    var indent = 0;
    while (i < text.length) {
      final c = text.codeUnitAt(i);
      if (c == 0x20) {
        indent++;
      } else {
        // Blank line doesn't count as indent.
        if (c == 0x0A) indent = -1;
        break;
      }
      if (++i == text.length) {
        // End of text doesn't count as indent.
        indent = -1;
        break;
      }
    }
    if (indent != -1) {
      if (result == -1 || indent < result) result = indent;
    }
    final next = i = text.indexOf('\n', i);
    if (next == -1) {
      break;
    } else {
      i = next + 1;
    }
  }
  return result == -1 ? 0 : result;
}

Pattern Function(int) _deindentPattern = _memoize1((indentSize) => RegExp(
      '^ {$indentSize}',
      multiLine: true,
    ));

R Function(T) _memoize1<T, R>(R Function(T) func) {
  final cache = <T, R>{};
  return (arg) => cache.putIfAbsent(arg, () => func(arg));
}

bool looksLikeUrl(String text) => _urlLikeRegexp.hasMatch(text);

final _urlLikeRegexp = RegExp(r'^\w+://');

bool looksLikeImagePath(String text) => _imagePathLikeRegexp.hasMatch(text);

final _imagePathLikeRegexp =
    RegExp(r'\.(?:jpe?g|png|gif|webp|w?bmp|svg|avif)$');

String trimPrefSuff(String str, String prefix, String suffix) {
  if (str.startsWith(prefix) && str.endsWith(suffix)) {
    return str.substring(prefix.length, str.length - suffix.length);
  }
  return str;
}
