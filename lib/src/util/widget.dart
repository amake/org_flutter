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
