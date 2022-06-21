class Subscribable<TListener extends Function> {
  final List<TListener> _listeners = [];

  Subscribable();

  void Function() subscribe(TListener listener) {
    _listeners.add(listener);

    onSubscribe();

    return () => {_listeners.remove(listener), onUnsubscribe()};
  }

  bool hasListeners() {
    return _listeners.isNotEmpty;
  }

  onSubscribe() {}
  onUnsubscribe() {}
}
