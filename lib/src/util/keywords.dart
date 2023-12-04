import 'package:org_flutter/org_flutter.dart';

List<String> getStartupSettings(OrgTree tree) {
  final result = <String>[];
  tree.visit<OrgMeta>((meta) {
    if (meta.keyword.toUpperCase() == '#+STARTUP:') {
      for (final setting in meta.trailing.trim().split(' ')) {
        result.add(setting.toLowerCase());
      }
    }
    return true;
  });
  return result;
}
