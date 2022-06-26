import 'dart:async';
import 'dart:math';

import 'package:fquery/fquery.dart';
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
    cancelGarbageCollection();
  }

  void unsubscribe(Observer observer) {
    observers.remove(observer);

    print("an observer unsubscribed");
    print("current length is");
    print(observers.length);
    // Start garbage collection timer if there are no observers
    if (observers.isNotEmpty) return;

    scheduleGarbageCollection();
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
    print("garbage collection scheduled");
    print("cache duration is");
    print(cacheDuration);
    garbageCollectionTimer?.cancel();
    garbageCollectionTimer =
        Timer(cacheDuration ?? Duration(minutes: 5), onGarbageCollection);
  }

  void cancelGarbageCollection() {
    garbageCollectionTimer?.cancel();
    garbageCollectionTimer = null;
  }
}
