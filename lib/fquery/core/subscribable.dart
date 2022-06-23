import 'package:flutter/foundation.dart';

class Subscribable extends Listenable {
  final List<Function> listeners = [];
  bool get hasListeners => listeners.isNotEmpty;

  @override
  void Function() addListener(Function listener) {
    listeners.add(listener);
    return () {
      listeners.remove(listener);
    };
  }

  @override
  void removeListener(Function listener) {
    listeners.remove(listener);
  }
}
