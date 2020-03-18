import 'package:flutter/widgets.dart';

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

Iterable<InlineSpan> tokenizeTextSpan(
  String text,
  Pattern pattern,
  TextStyle matchStyle,
  String Function(String) transform,
) sync* {
  var lastEnd = 0;
  for (final match in pattern.allMatches(text)) {
    if (match.start > lastEnd) {
      yield TextSpan(text: transform(text.substring(lastEnd, match.start)));
    }
    yield TextSpan(text: transform(match.group(0)), style: matchStyle);
    lastEnd = match.end;
  }
  if (lastEnd < text.length) {
    yield TextSpan(text: transform(text.substring(lastEnd, text.length)));
  }
}
