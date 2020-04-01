/// If necessary, interleave runes with U+200B ZERO WIDTH SPACE to serve as a
/// place to wrap the line.
String characterWrappable(String text) {
  if (text.contains(' ')) {
    return text;
  } else {
    return String.fromCharCodes(interleave(text.runes, 0x200b));
  }
}

Iterable<T> interleave<T>(Iterable<T> items, T withItem) sync* {
  for (final item in items) {
    yield item;
    yield withItem;
  }
}

Iterable<R> zipMap<R, T, U>(
    Iterable<T> a, Iterable<U> b, R Function(T, U) visit) sync* {
  final iterA = a.iterator;
  final iterB = b.iterator;
  while (iterA.moveNext() && iterB.moveNext()) {
    yield visit(iterA.current, iterB.current);
  }
}

bool emptyPattern(Pattern pattern) {
  if (pattern is String) {
    return pattern.isEmpty;
  } else if (pattern is RegExp) {
    return pattern.pattern.isEmpty;
  } else {
    return pattern == null;
  }
}

bool patternEquals(Pattern a, Pattern b) {
  if (a == b) {
    return true;
  }
  if (a is RegExp && b is RegExp) {
    return a.pattern == b.pattern &&
        a.isCaseSensitive == b.isCaseSensitive &&
        a.isDotAll == b.isDotAll &&
        a.isMultiLine == b.isMultiLine &&
        a.isUnicode == b.isUnicode;
  }
  return false;
}

String reflowText(String text) =>
    text.replaceAll(_unwrappableWhitespacePattern, ' ');

final _unwrappableWhitespacePattern = RegExp(r'(?<=\S)[ \t]*\r?\n[ \t]*(?=\S)');

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
