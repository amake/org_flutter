import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class OrgNumData extends InheritedWidget {
  static OrgNumData? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OrgNumData>();

  const OrgNumData({
    required this.nums,
    required super.child,
    super.key,
  });

  /// A map of Org Num section numbers
  ///
  /// Keys: The section level (1-indexed). Missing levels are presented
  /// with a value of 0 in [numString].
  ///
  /// Values: The number for that level (also 1-indexed)
  ///
  /// TODO(aaron): Give an example document and show what the map would look like
  final Map<int, int> nums;

  /// The string for presentation, e.g. "1.2.0.3"
  String get numString {
    final maxLevel = nums.keys.reduce((a, b) => a > b ? a : b);
    return Iterable<int>.generate(maxLevel)
        .map((level) => nums[level + 1] ?? 0)
        .join('.');
  }

  @override
  bool updateShouldNotify(OrgNumData oldWidget) =>
      !mapEquals(nums, oldWidget.nums);
}
