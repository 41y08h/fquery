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

enum QueryStatus {
  loading,
  success,
  error,
}

enum RefetchOnMount {
  stale,
  always,
  never,
}

class QueryOptions {
  bool enabled;
  RefetchOnMount refetchOnMount;
  Duration staleDuration;
  Duration cacheDuration;

  QueryOptions({
    this.enabled = true,
    this.refetchOnMount = RefetchOnMount.stale,
    this.staleDuration = const Duration(seconds: 0),
    this.cacheDuration = const Duration(minutes: 5),
  });
}

class QueryState<TData, TError> {
  TData? data;
  TError? error;
  DateTime? dataUpdatedAt;
  DateTime? errorUpdatedAt;
  bool isFetching;
  QueryStatus status;

  bool get isLoading => status == QueryStatus.loading;
  bool get isSuccess => status == QueryStatus.success;
  bool get isError => status == QueryStatus.error;

  QueryState({
    this.data,
    this.error,
    this.dataUpdatedAt,
    this.errorUpdatedAt,
    this.isFetching = false,
    this.status = QueryStatus.loading,
  });

  QueryState<TData, TError> _copyWith({
    dynamic data,
    dynamic error,
    DateTime? dataUpdatedAt,
    DateTime? errorUpdatedAt,
    bool? isFetching,
    QueryStatus? status,
  }) {
    return QueryState(
      data: data ?? this.data,
      error: error ?? this.error,
      dataUpdatedAt: dataUpdatedAt ?? this.dataUpdatedAt,
      errorUpdatedAt: errorUpdatedAt ?? this.errorUpdatedAt,
      isFetching: isFetching ?? this.isFetching,
      status: status ?? this.status,
    );
  }
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
        return state._copyWith(
          isFetching: true,
        );
      case DispatchAction.cancelFetch:
        return state._copyWith(
          isFetching: false,
        );
      case DispatchAction.error:
        return state._copyWith(
          status: QueryStatus.error,
          error: data,
          errorUpdatedAt: DateTime.now(),
          isFetching: false,
        );
      case DispatchAction.success:
        return state._copyWith(
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
