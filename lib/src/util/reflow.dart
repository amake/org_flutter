import 'package:flutter/foundation.dart';
import 'package:more/char_matcher.dart';

enum TokenLocation { start, middle, end, only }

TokenLocation locationOf(Object elem, List<Object> elems) {
  final isLast = identical(elem, elems.last);
  final isFirst = identical(elem, elems.first);
  return isLast && isFirst
      ? TokenLocation.only
      : isLast
          ? TokenLocation.end
          : isFirst
              ? TokenLocation.start
              : TokenLocation.middle;
}

String reflowText(String text, TokenLocation location) => text.replaceAllMapped(
      switch (location) {
        TokenLocation.only => _unwrappableWhitespacePattern,
        TokenLocation.start => _unwrappableStartWhitespacePattern,
        TokenLocation.middle => _unwrappableMiddleWhitespacePattern,
        TokenLocation.end => _unwrappableEndWhitespacePattern,
      },
      (match) {
        final before = text.codePointBefore(match.start);
        if (before != null && _isNonSpaceDelimited(before)) {
          final after = text.codePointAt(match.end);
          if (after != null && _isNonSpaceDelimited(after)) {
            return '';
          }
        }
        return ' ';
      },
    );

// Match single (CR)LF between non-whitespace chars only (preserve leading and
// trailing linebreaks)
final _unwrappableWhitespacePattern =
    RegExp(r'(?<=\S)[ \t]*\r?\n[ \t]*(?=\S)', unicode: true);
// Match single (CR)LF between non-whitespace chars OR at end of text for
// leading text run (preserve leading linebreaks)
final _unwrappableStartWhitespacePattern =
    RegExp(r'(?<=\S)[ \t]*\r?\n[ \t]*(?=\S|$)', unicode: true);
// Match single (CR)LF between non-whitespace chars OR at edge of text for
// "inside" text runs (preserve none)
final _unwrappableMiddleWhitespacePattern =
    RegExp(r'(?<=\S|^)[ \t]*\r?\n[ \t]*(?=\S|$)', unicode: true);
// Match single (CR)LF between non-whitespace chars OR at start of text for
// final text run (preserve trailing linebreaks)
final _unwrappableEndWhitespacePattern =
    RegExp(r'(?<=\S|^)[ \t]*\r?\n[ \t]*(?=\S)', unicode: true);

@visibleForTesting
extension UnicodeUtils on String {
  // We purposely return a lone high surrogate if the index points to one, for
  // speed and because that shouldn't happen given the use case here.
  int? codePointAt(int index) {
    if (index < 0 || index >= length) return null;
    final firstCodeUnit = codeUnitAt(index);
    if (_isLeadSurrogate(firstCodeUnit) && length > index + 1) {
      final secondCodeUnit = codeUnitAt(index + 1);
      if (_isTrailSurrogate(secondCodeUnit)) {
        return _combineSurrogatePair(firstCodeUnit, secondCodeUnit);
      }
    }
    return firstCodeUnit;
  }

  // We purposely return a lone low surrogate if the index points to one, for
  // speed and because that shouldn't happen given the use case here.
  int? codePointBefore(int index) {
    if (index <= 0 || index > length) return null;
    final lastCodeUnit = codeUnitAt(index - 1);
    if (_isTrailSurrogate(lastCodeUnit) && index >= 2) {
      final prevCodeUnit = codeUnitAt(index - 2);
      if (_isLeadSurrogate(prevCodeUnit)) {
        return _combineSurrogatePair(prevCodeUnit, lastCodeUnit);
      }
    }
    return lastCodeUnit;
  }
}

// Is then code (a 16-bit unsigned integer) a UTF-16 trail surrogate.
bool _isTrailSurrogate(int code) => (code & 0xFC00) == 0xDC00;
// Is then code (a 16-bit unsigned integer) a UTF-16 lead surrogate.
bool _isLeadSurrogate(int code) => (code & 0xFC00) == 0xD800;
// Combine a lead and a trail surrogate value into a single code point.
int _combineSurrogatePair(int start, int end) =>
    0x10000 + ((start & 0x3FF) << 10) + (end & 0x3FF);

// Additional scripts may deserve this treatment, but I'm not familiar enough
// with them. See:
// https://en.wikipedia.org/wiki/Category:Writing_systems_without_word_boundaries
final _hanMatcher = UnicodeCharMatcher.scriptHan();
final _hiraganaMatcher = UnicodeCharMatcher.scriptHiragana();
final _katakanaMatcher = UnicodeCharMatcher.scriptKatakana();

// These catch ranges that should be treated as full-width CJK (should not have
// spaces inserted) but include characters that are Common script.
bool _isCjkOther(int codeUnit) =>
    (codeUnit >= 0x3000 && codeUnit <= 0x303F) || // CJK Symbols and Punctuation
    (codeUnit >= 0x31C0 && codeUnit <= 0x31EF) || // CJK Strokes
    (codeUnit >= 0x3200 && codeUnit <= 0x32FF) || // Enclosed CJK Letters and Months
    (codeUnit >= 0x3300 && codeUnit <= 0x33FF) || // CJK Compatibility
    (codeUnit >= 0xFE30 && codeUnit <= 0xFE4F) || // CJK Compatibility Forms
    (codeUnit >= 0xFF00 && codeUnit <= 0xFFEF); // Halfwidth and Fullwidth Forms


bool _isNonSpaceDelimited(int codeUnit) =>
    _hanMatcher.match(codeUnit) ||
    _hiraganaMatcher.match(codeUnit) ||
    _katakanaMatcher.match(codeUnit) || _isCjkOther(codeUnit);
