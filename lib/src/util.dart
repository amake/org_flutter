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
