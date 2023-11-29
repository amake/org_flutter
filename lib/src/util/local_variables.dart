import 'package:org_flutter/org_flutter.dart';
import 'package:org_flutter/src/util/elisp.dart';
import 'package:petit_lisp/lisp.dart';
import 'package:petitparser/petitparser.dart';

final _lispParserDef = LispParserDefinition();

class LocalVariablesParser extends GrammarDefinition {
  @override
  Parser start() => ref0(entry).plus().end();

  Parser entry() =>
      ref0(entryItems).map((items) => (key: items[0], value: items[2]));

  Parser entryItems() =>
      ref0(symbol) & ref0(delimiter).trim() & ref0(atom) & ref0(trailing);

  Parser symbol() => ref0(symbolToken).flatten('Symbol expected');

  // Patterns taken from LispParserDefinition.symbolToken, but adapted here to
  // stop at the delimiter
  Parser symbolToken() =>
      pattern('a-zA-Z!#\$%&*/:<=>?@\\^_|~+-') &
      pattern('a-zA-Z0-9!#\$%&*/:<=>?@\\^_|~+-')
          .starLazy(ref0(delimiter) | endOfInput());

  Parser delimiter() => char(':') & whitespace();

  // We use atomChoice instead of atom to avoid trimming whitespace
  Parser atom() => _lispParserDef.buildFrom(_lispParserDef.atomChoice());

  Parser trailing() => any().starLazy(ref0(endOfLine)) & ref0(endOfLine);

  Parser endOfLine() => newline() | endOfInput();
}

final localVariablesParser = LocalVariablesParser().build<List<dynamic>>();

const _kExecutionTimeLimitMs = 100;

class _TimeoutException implements Exception {}

Map<String, dynamic> extractLocalVariables(
  OrgDocument doc,
  OrgErrorHandler onError,
) {
  final lvars = doc.find<OrgLocalVariables>((_) => true);
  if (lvars == null) return {};

  final parsed = localVariablesParser.parse(lvars.node.contentString);
  if (parsed is Failure) {
    // Give up and throw now
    throw OrgParserError(
      '${parsed.toPositionString()}: ${parsed.message}',
      parsed,
    );
  }

  final entries = parsed.value.cast<({String key, dynamic value})>();

  final start = DateTime.timestamp().millisecondsSinceEpoch;
  final env = ElispEnvironment(StandardEnvironment(NativeEnvironment()))
    ..define(Name('org-entities-user'), null)
    ..interrupt = () {
      final end = DateTime.timestamp().millisecondsSinceEpoch;
      if (end - start > _kExecutionTimeLimitMs) {
        throw _TimeoutException();
      }
    };

  final initialKeys = List.of(env.keys);

  for (final (key: symbol, value: value) in entries) {
    switch (symbol) {
      case 'eval':
        try {
          eval(env, value);
          // Don't throw because we want to continue execution
        } on _TimeoutException {
          onError.call(
            OrgTimeoutError(
              'Execution timed out',
              value.toString(),
              const Duration(milliseconds: _kExecutionTimeLimitMs),
            ),
          );
        } catch (e) {
          onError.call(
            OrgExecutionError('Failed to eval', value.toString(), e),
          );
        }
        break;
      default:
        env.define(Name(symbol), value);
        break;
    }
  }

  final addedKeys = List.of(env.keys)
    ..removeWhere((key) => initialKeys.contains(key));

  if (env[Name('org-entities-user')] != null) {
    addedKeys.add(Name('org-entities-user'));
  }

  return addedKeys.fold<Map<String, dynamic>>(
    {},
    (acc, key) => acc..[key.toString()] = env[key],
  );
}

const _kOrgEntitiesUserKeys = [
  'org-entities-user',
  'org-entities-local',
];

Map<String, String> getOrgEntities(
  Map<String, String> defaults,
  Map<String, dynamic> localVariables,
  OrgErrorHandler onError,
) {
  if (!_kOrgEntitiesUserKeys.any(localVariables.containsKey)) return defaults;

  final result = Map.of(defaults);

  for (final key in _kOrgEntitiesUserKeys) {
    var userEntities = localVariables[key];
    while (userEntities is Cons) {
      final entry = userEntities.head;
      if (entry is Cons) {
        final name = entry.head;
        // Entries are of the form
        // 1. name
        // 2. LaTeX replacement
        // 3. LaTeX mathp
        // 4. HTML replacement
        // 5. ASCII replacement
        // 6. Latin1 replacement
        // 7. utf-8 replacement
        final value = entry.tail?.tail?.tail?.tail?.tail?.tail?.head;
        if (name is String && value is String) {
          result[name] = value;
        } else {
          onError.call(OrgArgumentError('Invalid org entity', entry));
        }
      } else {
        onError.call(OrgArgumentError('Invalid org entity', entry));
      }
      userEntities = userEntities.tail;
    }
  }

  return result;
}

const _kOrgPrettyEntitiesKey = 'org-pretty-entities';

bool? getPrettyEntities(Map<String, dynamic> localVariables) =>
    _getBooleanValue(localVariables, _kOrgPrettyEntitiesKey);

const _kOrgHideEmphasisMarkersKey = 'org-hide-emphasis-markers';

bool? getHideEmphasisMarkers(Map<String, dynamic> localVariables) =>
    _getBooleanValue(localVariables, _kOrgHideEmphasisMarkersKey);

bool? _getBooleanValue(Map<String, dynamic> localVariables, String key) {
  if (localVariables.containsKey(key)) {
    final value = localVariables[key];
    if (value == Name('nil')) {
      return false;
    } else if (value == Name('t')) {
      return true;
    }
  }
  return null;
}
