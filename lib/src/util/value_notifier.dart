import 'package:flutter/foundation.dart';

class SafeValueNotifier<T> extends ValueNotifier<T> {
  bool _disposed = false;

  SafeValueNotifier(super.value);

  bool get disposed => _disposed;

  @override
  void dispose() {
    super.dispose();
    _disposed = true;
  }
}

extension ValueNotifierUtil<T> on ValueNotifier<T> {
  void listenOnce(VoidCallback callback) {
    void listener() {
      callback();
      removeListener(listener);
    }

    addListener(listener);
  }
}
