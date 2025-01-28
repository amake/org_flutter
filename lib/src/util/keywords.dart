import 'package:org_flutter/org_flutter.dart';

List<String> getStartupSettings(OrgTree tree) {
  final result = <String>[];
  tree.visit<OrgMeta>((meta) {
    if (meta.key.toUpperCase() == '#+STARTUP:' && meta.value != null) {
      for (final setting in meta.value!.toMarkup().trim().split(' ')) {
        result.add(setting.toLowerCase());
      }
    }
    return true;
  });
  return result;
}
