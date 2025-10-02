mixin Observable {
  Map<int, Function> listeners = {};
  void addListener(int observerId, Function listener) {
    listeners[observerId] = listener;
  }

  void removeListener(int observerId) {
    listeners.remove(observerId);
  }

  void notifyListeners() {
    listeners.forEach((observerId, listener) {
      listener();
    });
  }

  void clearListeners() {
    listeners.clear();
  }
}
