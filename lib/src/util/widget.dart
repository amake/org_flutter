import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

mixin OpenCloseable<T extends StatefulWidget> on State<T> {
  ValueNotifier<bool> _openListenable;
  ValueNotifier<bool> get openListenable => _openListenable;

  @override
  void initState() {
    super.initState();
    _openListenable = ValueNotifier<bool>(false);
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
