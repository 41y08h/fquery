import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/observer.dart';

typedef QueryKey = List<dynamic>;

enum DispatchAction {
  fetch,
  error,
  success,
  cancelFetch,
  invalidate,
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

class QueryOptions<TData, TError> {
  bool enabled;
  RefetchOnMount refetchOnMount;
  Duration staleDuration;
  Duration cacheDuration;
  Duration? refetchInterval;
  final ValueChanged<TData>? onData;
  final ValueChanged<TError>? onError;

  QueryOptions({
    required this.enabled,
    required this.refetchOnMount,
    required this.staleDuration,
    required this.cacheDuration,
    this.refetchInterval,
    this.onData,
    this.onError,
  });
}

class QueryState<TData, TError> {
  TData? data;
  TError? error;
  DateTime? dataUpdatedAt;
  DateTime? errorUpdatedAt;
  bool isFetching;
  QueryStatus status;
  bool isInvalidated;

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
    this.isInvalidated = false,
  });

  QueryState<TData, TError> _copyWith({
    dynamic data,
    dynamic error,
    DateTime? dataUpdatedAt,
    DateTime? errorUpdatedAt,
    bool? isFetching,
    QueryStatus? status,
    bool? isInvalidated,
  }) {
    return QueryState(
      data: data ?? this.data,
      error: error ?? this.error,
      dataUpdatedAt: dataUpdatedAt ?? this.dataUpdatedAt,
      errorUpdatedAt: errorUpdatedAt ?? this.errorUpdatedAt,
      isFetching: isFetching ?? this.isFetching,
      status: status ?? this.status,
      isInvalidated: isInvalidated ?? this.isInvalidated,
    );
  }
}

class Query<TData, TError> {
  final QueryClient client;
  final QueryKey key;

  QueryState<TData, TError> _state = QueryState<TData, TError>();
  QueryState<TData, TError> get state => _state;
  final List<Observer> _observers = [];

  Duration? _cacheDuration;
  Timer? _garbageCollectionTimer;

  Query({required this.client, required this.key});

  /// The single source of truth for how the cache data changes.
  QueryState<TData, TError> _reducer(
      QueryState<TData, TError> state, DispatchAction action, dynamic data) {
    switch (action) {
      case DispatchAction.fetch:
        return state._copyWith(
          isFetching: true,
          status:
              state.dataUpdatedAt == null ? QueryStatus.loading : state.status,
        );
      case DispatchAction.cancelFetch:
        return state._copyWith(
          isFetching: false,
        );
      case DispatchAction.error:
        return state._copyWith(
          status: QueryStatus.error,
          error: data as TError,
          errorUpdatedAt: DateTime.now(),
          isFetching: false,
        );
      case DispatchAction.success:
        return state._copyWith(
          status: QueryStatus.success,
          error: null,
          data: data as TData,
          dataUpdatedAt: DateTime.now(),
          isFetching: false,
          isInvalidated: false,
        );
      case DispatchAction.invalidate:
        return state._copyWith(
          isInvalidated: true,
        );
      default:
        return state;
    }
  }

  /// Sets the cache duration
  /// Max cacheDuration given by any observer is used
  /// Reschedules the garbage collection timer
  void setCacheDuration(Duration cacheDuration) {
    _cacheDuration = Duration(
        milliseconds: max(
      (_cacheDuration ?? Duration.zero).inMilliseconds,
      cacheDuration.inMilliseconds,
    ));
    _scheduleGarbageCollection();
  }

  void _notifyObservers() {
    for (var observer in _observers) {
      observer.onQueryUpdated();
    }
  }

  /// This is called from the [Observer]
  /// to subscribe to the query
  void subscribe(Observer observer) {
    _observers.add(observer);

    // At least we have one observer
    // So no need to garbage collect
    _cancelGarbageCollection();
  }

  void unsubscribe(Observer observer) {
    _observers.remove(observer);

    if (_observers.isEmpty) {
      _scheduleGarbageCollection();
    }
  }

  /// Dispatches an action to the reducer and notifies observers
  void dispatch(DispatchAction action, dynamic data) {
    _state = _reducer(state, action, data);
    _notifyObservers();
  }

  /// This is called when garbage collection timer fires
  void onGarbageCollection() {
    client.queryCache.remove(this);
  }

  void _scheduleGarbageCollection() {
    if (_observers.isNotEmpty) return;

    _garbageCollectionTimer?.cancel();
    final duration = _cacheDuration ?? client.defaultQueryOptions.cacheDuration;
    _garbageCollectionTimer = Timer(duration, onGarbageCollection);
  }

  void _cancelGarbageCollection() {
    _garbageCollectionTimer?.cancel();
    _garbageCollectionTimer = null;
  }
}
