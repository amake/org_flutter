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

String reflowText(String text, {required bool end}) => text.replaceAll(
    end ? _unwrappableEndWhitespacePattern : _unwrappableWhitespacePattern,
    ' ');

// Match single (CR)LF between non-whitespace chars OR at end of text for
// "inside" text runs only
final _unwrappableWhitespacePattern =
    RegExp(r'(?<=\S)[ \t]*\r?\n[ \t]*(?=\S|$)');
// Match single (CR)LF between non-whitespace chars ONLY for final text run
// (preserve trailing linebreaks)
final _unwrappableEndWhitespacePattern =
    RegExp(r'(?<=\S)[ \t]*\r?\n[ \t]*(?=\S)');

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

String deindent(String text, int indentSize) =>
    text.replaceAll(_deindentPattern(indentSize), '');

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
