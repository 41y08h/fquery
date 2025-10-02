mixin Observable {
  Map<int, Function> listeners = {};
  void subscribe(int listenerId, Function listener) {
    listeners[listenerId] = listener;
  }

  void unsubscribe(int observerId) {
    listeners.remove(observerId);
  }

  void notifyObservers() {
    listeners.forEach((observerId, listener) {
      listener();
    });
  }

  void clearListeners() {
    listeners.clear();
  }
}
