class Subscribable<TListener extends Function> {
  final List<TListener> listeners = [];

  Subscribable();

  void Function() subscribe(TListener listener) {
    listeners.add(listener);

    onSubscribe();

    return () => {listeners.remove(listener), onUnsubscribe()};
  }

  bool hasListeners() {
    return listeners.isNotEmpty;
  }

  onSubscribe() {}
  onUnsubscribe() {}
}
