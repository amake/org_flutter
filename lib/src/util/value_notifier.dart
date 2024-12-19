import 'dart:async';

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
  Future<U> listenOnce<U>(FutureOr<U> Function() callback) {
    final result = Completer<U>();

    void listener() {
      result.complete(callback());
      removeListener(listener);
    }

    addListener(listener);

    return result.future;
  }
}
