import 'package:flutter/material.dart';
import 'package:org_flutter/org_flutter.dart';

/// Extracts the locale from `#+LANGUAGE:` in the given [tree].
Locale? extractLocale(
  OrgTree tree,
) {
  Locale? result;
  tree.visit<OrgMeta>((meta) {
    if (meta.key.toUpperCase() == '#+LANGUAGE:' && meta.value != null) {
      final trailing = meta.value!.toMarkup().trim();
      result = tryParseLocale(trailing);
      if (result != null) return false;
    }
    return true;
  });
  debugPrint('Detected locale: $result');
  return result;
}

Locale? tryParseLocale(String locale) {
  final parts = locale.split(RegExp('[_-]'));
  if (parts.length == 1 && parts[0].isNotEmpty) {
    return Locale(parts[0]);
  } else if (parts.length == 2 && parts[1].length == 2) {
    return Locale(parts[0], parts[1]);
  } else if (parts.length == 2 && parts[1].length == 4) {
    return Locale.fromSubtags(
      languageCode: parts[0],
      scriptCode: parts[1],
    );
  } else if (parts.length == 3) {
    return Locale.fromSubtags(
      languageCode: parts[0],
      scriptCode: parts[1],
      countryCode: parts[2],
    );
  }
  return null;
}
