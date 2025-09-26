import 'dart:async';
import 'dart:math';

import 'package:fquery/src/models/query.dart';
import 'package:fquery/src/observable.dart';
import 'package:fquery/src/observers/observer.dart';
import 'package:fquery/src/query_client.dart';
import 'package:fquery/src/models/query_key.dart';

/// A map of query keys to their corresponding queries.
typedef QueriesMap = Map<QueryKey, Query>;

/// Exception thrown when a query with the specified key is not found in the cache.
class QueryNotFoundException implements Exception {
  /// The query key that was not found.
  final QueryKey queryKey;

  /// The error message.
  final String message;

  /// Creates a new [QueryNotFoundException] instance.
  QueryNotFoundException(this.queryKey)
      : message = "Query with key '$queryKey' not found";

  @override
  String toString() => "QueryNotFoundException: $message";
}

/// The cache that holds all the queries.
class QueryCache with Observable {
  final QueriesMap _queries = {};
  final Map<QueryKey, List<Observer>> _observers = {};
  final Map<QueryKey, Timer> _gcTimers = {};
  final Map<QueryKey, Duration> _maxCacheDurations = {};

  /// Returns an unmodifiable view of the queries in the cache.
  QueriesMap get queries => _queries;

  /// The single source of truth for how the cache data changes.
  Query<TData, TError> _reducer<TData, TError extends Exception>(
    Query<TData, TError> state,
    DispatchAction action,
    Object? data,
  ) {
    switch (action) {
      case DispatchAction.fetch:
        return state.copyWith(
          isFetching: true,
          status:
              state.dataUpdatedAt == null ? QueryStatus.loading : state.status,
          fetchMeta: data as FetchMeta?,
        );
      case DispatchAction.cancelFetch:
        return state.copyWith(
          isFetching: false,
          fetchMeta: null,
        );
      case DispatchAction.error:
        return state.copyWith(
          status: QueryStatus.error,
          error: data as TError,
          errorUpdatedAt: DateTime.now(),
          isFetching: false,
          isInvalidated: false,
          fetchMeta: state.fetchMeta,
        );
      case DispatchAction.success:
        return state.copyWith(
          status: QueryStatus.success,
          error: null,
          data: data as TData,
          dataUpdatedAt: DateTime.now(),
          isFetching: false,
          isInvalidated: false,
          fetchMeta: null,
        );
      case DispatchAction.invalidate:
        return state.copyWith(
          isInvalidated: true,
        );
      case DispatchAction.refetchSequence:
        return state.copyWith(
          error: null,
          data: data as TData,
          dataUpdatedAt: DateTime.now(),
          isInvalidated: false,
          fetchMeta: null,
        );
      case DispatchAction.refetchError:
        return state.copyWith(
          isRefetchError: true,
          status: QueryStatus.error,
          error: data as TError,
          errorUpdatedAt: DateTime.now(),
          isFetching: false,
          isInvalidated: false,
          fetchMeta: null,
        );
    }
  }

  /// Returns a query identified by the query key.
  Query<TData, TError> get<TData, TError extends Exception>(QueryKey queryKey) {
    final query = _queries[queryKey];
    if (query == null) {
      throw QueryNotFoundException(queryKey);
    }
    return query as Query<TData, TError>;
  }

  void _add<TData, TError extends Exception>(
      QueryKey queryKey, Query<TData, TError> query) {
    _queries[queryKey] = query;
  }

  /// Removes a query from the cache.
  void remove<TData, TError extends Exception>(Query<TData, TError> query) {
    _queries.removeWhere((key, value) => value == query);
  }

  /// Returns a query identified by the query key.
  /// If it doesn't exist already,
  /// creates a new one and adds it to the cache.
  Query<TData, TError> build<TData, TError extends Exception>({
    required QueryKey queryKey,
    required QueryClient client,
    Observer? observer,
  }) {
    late final Query<TData, TError> query;
    try {
      query = get<TData, TError>(queryKey);
    } on QueryNotFoundException {
      query = Query(queryKey);
    }

    _add(queryKey, query);
    if (observer != null) _addObserver(observer);

    return query;
  }

  void _addObserver(Observer observer) {
    _observers.putIfAbsent(observer.options.queryKey, () => []).add(observer);
    _gcRoutine();
  }

  /// This is called when an observer is disposed
  void dismantle(Observer observer) {
    // Set max cache duration before removing the observer
    final queryKey = observer.options.queryKey;
    final currentMaxCacheDuration =
        _maxCacheDurations[queryKey] ?? Duration.zero;

    _maxCacheDurations[queryKey] = Duration(
      milliseconds: max(
        observer.options.cacheDuration.inMilliseconds,
        currentMaxCacheDuration.inMilliseconds,
      ),
    );

    final observers = _observers[queryKey];
    observers?.remove(observer);

    _gcRoutine();
  }

  /// Dispatches an action to the reducer and notifies observers
  void dispatch<TData, TError extends Exception>(
    QueryKey queryKey,
    DispatchAction action,
    Object? data,
  ) {
    queries[queryKey] = _reducer<TData, TError>(
      get<TData, TError>(queryKey),
      action,
      data,
    );
    notifyListeners();
  }

  void _gcRoutine() {
    _maxCacheDurations.forEach((queryKey, cacheDuration) {
      final observers = _observers[queryKey] ?? [];
      if (observers.isEmpty) {
        _scheduleGc(queryKey, cacheDuration);
      } else {
        _cancleGc(queryKey);
      }
    });
  }

  void _cancleGc(QueryKey queryKey) {
    _gcTimers[queryKey]?.cancel();
    _gcTimers.remove(queryKey);
  }

  void _scheduleGc(QueryKey queryKey, Duration cacheDuration) {
    _cancleGc(queryKey);

    void onGc() {
      _queries.removeWhere((key, value) => key == queryKey);
      _observers.remove(queryKey);
      _maxCacheDurations.remove(queryKey);
      _gcTimers.remove(queryKey);
    }

    _gcTimers[queryKey] = Timer(cacheDuration, onGc);
  }
}
