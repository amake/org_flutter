import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

mixin OpenCloseable<T extends StatefulWidget> on State<T> {
  late ValueNotifier<bool> _openListenable;
  ValueNotifier<bool> get openListenable => _openListenable;

  bool get defaultOpen => true;

  @override
  void initState() {
    super.initState();
    _openListenable = ValueNotifier<bool>(defaultOpen);
  }

  @override
  void dispose() {
    _openListenable.dispose();
    super.dispose();
  }
}

typedef RecognizerHandler = Function(GestureRecognizer);

mixin RecognizerManager<T extends StatefulWidget> on State<T> {
  final _recognizers = <GestureRecognizer>[];

  @override
  void dispose() {
    for (final item in _recognizers) {
      item.dispose();
    }
    super.dispose();
  }

  void registerRecognizer(GestureRecognizer recognizer) =>
      _recognizers.add(recognizer);
}

Widget listBottomSafeArea() => const SafeArea(
      top: false,
      left: false,
      right: false,
      child: SizedBox.shrink(),
    );

const _kReducedOpacity = 0.6;

Widget reduceOpacity(Widget child, {bool enabled = true}) =>
    enabled ? Opacity(opacity: _kReducedOpacity, child: child) : child;
