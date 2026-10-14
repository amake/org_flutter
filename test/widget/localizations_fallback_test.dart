import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:org_flutter/org_flutter.dart';

void main() {
  testWidgets(
    'uses a document-locale delegate even if an earlier delegate only supports the parent locale',
    (tester) async {
      await tester.pumpWidget(
        _wrapWithDelegates([
          const _TestStringsDelegate(languageCode: 'en', value: 'parent'),
          const _TestStringsDelegate(languageCode: 'zh', value: 'document'),
        ], _document('zh-Hant')),
      );

      final context = tester.element(find.byType(_LocalizedProbe));
      expect(Localizations.localeOf(context).toString(), 'zh_Hant');
      expect(find.text('document'), findsOneWidget);
    },
  );

  testWidgets(
    'falls back to the parent locale when no delegate supports the document locale',
    (tester) async {
      await tester.pumpWidget(
        _wrapWithDelegates([
          const _TestStringsDelegate(languageCode: 'en', value: 'parent'),
        ], _document('zh-Hant')),
      );

      final context = tester.element(find.byType(_LocalizedProbe));
      expect(Localizations.localeOf(context).toString(), 'zh_Hant');
      expect(find.text('parent'), findsOneWidget);
    },
  );
}

Widget _document(String language) {
  final doc = OrgDocument.parse('''
#+LANGUAGE: $language
''');
  return OrgController(
    root: doc,
    interpretEmbeddedSettings: true,
    errorHandler: (error) => fail(error.toString()),
    child: OrgRootWidget(child: const _LocalizedProbe()),
  );
}

Widget _wrapWithDelegates(
  List<LocalizationsDelegate<dynamic>> delegates,
  Widget child,
) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Localizations(
      delegates: [...delegates, ...GlobalMaterialLocalizations.delegates],
      locale: const Locale('en', 'US'),
      child: Material(child: child),
    ),
  );
}

class _LocalizedProbe extends StatelessWidget {
  const _LocalizedProbe();

  @override
  Widget build(BuildContext context) =>
      Text(Localizations.of<_TestStrings>(context, _TestStrings)!.value);
}

class _TestStrings {
  const _TestStrings(this.value);

  final String value;
}

class _TestStringsDelegate extends LocalizationsDelegate<_TestStrings> {
  const _TestStringsDelegate({required this.languageCode, required this.value});

  final String languageCode;
  final String value;

  @override
  bool isSupported(Locale locale) => locale.languageCode == languageCode;

  @override
  Future<_TestStrings> load(Locale locale) =>
      SynchronousFuture(_TestStrings(value));

  @override
  bool shouldReload(_TestStringsDelegate old) => false;
}
