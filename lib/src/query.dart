import 'dart:async';
import 'dart:math';

import 'package:fquery/fquery.dart';
import 'package:fquery/src/constants.dart';
import 'package:fquery/src/observer.dart';

enum DispatchAction {
  fetch,
  error,
  success,
  cancelFetch,
}

class Query<TData, TError> {
  QueryState<TData, TError> _state = QueryState();
  QueryState<TData, TError> get state => _state;
  List<Observer> observers = [];

  Duration? cacheDuration;
  Timer? garbageCollectionTimer;
  final QueryClient client;

  Query({required this.client});

  QueryState<TData, TError> _reducer(
      QueryState<TData, TError> state, DispatchAction action, dynamic data) {
    switch (action) {
      case DispatchAction.fetch:
        return state.copyWith(
          isFetching: true,
        );
      case DispatchAction.cancelFetch:
        return state.copyWith(
          isFetching: false,
        );
      case DispatchAction.error:
        return state.copyWith(
          status: QueryStatus.error,
          error: data,
          errorUpdatedAt: DateTime.now(),
          isFetching: false,
        );
      case DispatchAction.success:
        return state.copyWith(
          status: QueryStatus.success,
          error: null,
          data: data,
          dataUpdatedAt: DateTime.now(),
          isFetching: false,
        );

      default:
        return state;
    }
  }

  // Sets the cache duration
  // Max cacheDuration given by any observer is used
  // Reschedules the garbage collection timer
  void setCacheDuration(Duration cacheDuration) {
    this.cacheDuration = Duration(
        milliseconds: max(
      (this.cacheDuration ?? Duration.zero).inMilliseconds,
      cacheDuration.inMilliseconds,
    ));
    scheduleGarbageCollection();
  }

  void notifyObservers() {
    for (var observer in observers) {
      observer.onQueryUpdated();
    }
  }

  void subscribe(Observer observer) {
    observers.add(observer);

    // At least we have one observer
    // So no need to garbage collect
    cancelGarbageCollection();
  }

  void unsubscribe(Observer observer) {
    observers.remove(observer);

    if (observers.isEmpty) {
      scheduleGarbageCollection();
    }
  }

  void dispatch(DispatchAction action, dynamic data) {
    _state = _reducer(state, action, data);
    notifyObservers();
  }

  // This is called when garbage collection timer fires
  void onGarbageCollection() {
    client.removeQuery(this);
  }

  void scheduleGarbageCollection() {
    if (observers.isNotEmpty) return;

    garbageCollectionTimer?.cancel();
    final duration = cacheDuration ?? kDefaultCacheDuration;
    garbageCollectionTimer = Timer(duration, onGarbageCollection);
  }

  void cancelGarbageCollection() {
    garbageCollectionTimer?.cancel();
    garbageCollectionTimer = null;
  }
}
