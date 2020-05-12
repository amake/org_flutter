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
