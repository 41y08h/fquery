import 'package:flutter/foundation.dart';

class Subscribable extends Listenable {
  final listeners = <Function>[];
  bool get hasListeners => listeners.isNotEmpty;

  @override
  void addListener(Function listener) {
    listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listeners.remove(listener);
  }
}
