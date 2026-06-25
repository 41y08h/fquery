import 'dart:async';
import 'dart:collection';

import 'package:fquery_core/src/observer.dart';
import 'package:fquery_core/src/query.dart';

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

/// Stores query state and coordinates notifications to query observers.
///
/// The cache is the central state container for queries. It can build, read,
/// update, invalidate, and remove cached query entries, and it garbage-collects
/// unused entries after their configured cache duration.
class QueryCache with Observable {
  final QueriesMap _queries = {};
  final Map<QueryKey, Set<Observer>> _observers = {};
  final Map<QueryKey, Timer> _gcTimers = {};

  /// Defaults applied to query observers when an option is omitted.
  final DefaultQueryOptions defaultQueryOptions;

  /// The queries currently stored in the cache.
  QueriesMap get queries => UnmodifiableMapView(_queries);

  /// Creates a query cache with optional [defaultQueryOptions].
  QueryCache({DefaultQueryOptions? defaultQueryOptions})
      : defaultQueryOptions = defaultQueryOptions ??
            DefaultQueryOptions(
              enabled: true,
              refetchOnMount: RefetchOnMount.stale,
              staleDuration: Duration.zero,
              cacheDuration: const Duration(minutes: 5),
              refetchInterval: null,
              retryCount: 3,
              retryDelay: const Duration(seconds: 1, milliseconds: 500),
            );

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
        return state.copyWith(isFetching: false, fetchMeta: null);
      case DispatchAction.error:
        return state.copyWith(
          status: QueryStatus.error,
          error: data as TError,
          errorUpdatedAt: DateTime.now(),
          isFetching: false,
          isInvalidated: false,
          fetchMeta: null,
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
        return state.copyWith(isInvalidated: true);
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
  Query<TData, TError> get<TData, TError extends Exception>(
      QueryKey<TData, TError> queryKey) {
    final query = _queries[queryKey];
    if (query == null) {
      throw QueryNotFoundException(queryKey);
    }
    return query as Query<TData, TError>;
  }

  void _add<TData, TError extends Exception>(
    QueryKey queryKey,
    Query<TData, TError> query,
  ) {
    _queries[queryKey] = query;
  }

  /// Removes a query from the cache.
  void _remove<TData, TError extends Exception>(Query<TData, TError> query) {
    _queries.remove(query.key);
  }

  /// Returns a query identified by the query key.
  /// If it doesn't exist already,
  /// creates a new one and adds it to the cache.
  Query<TData, TError> build<TData, TError extends Exception>({
    required QueryKey<TData, TError> queryKey,
    Observer? observer,
  }) {
    late final Query<TData, TError> query;
    try {
      query = get(queryKey);
    } on QueryNotFoundException {
      query = Query(queryKey);
    }

    _add(queryKey, query);
    if (observer != null) {
      _addObserver(observer);
    }

    return query;
  }

  void _addObserver(Observer observer) {
    _observers.putIfAbsent(observer.queryKey, () => {}).add(observer);
    _gcRoutine(observer.queryKey);
  }

  /// Detaches [observer] and schedules garbage collection if it was the last one.
  void dismantle(Observer observer) {
    // Call before removing to preserv cacheDuration
    _gcRoutine(observer.queryKey, isDisposed: true);

    final observers = _observers[observer.queryKey];
    observers?.remove(observer);
  }

  /// Dispatches an action to the reducer and notifies observers.
  void dispatch<TData, TError extends Exception>(
    QueryKey<TData, TError> queryKey,
    DispatchAction action,
    Object? data,
  ) {
    try {
      _queries[queryKey] = _reducer<TData, TError>(
        get<TData, TError>(queryKey),
        action,
        data,
      );
      notifyObservers();
    } on QueryNotFoundException {
      return;
    }
  }

  void _gcRoutine<TData, TError extends Exception>(
      QueryKey<TData, TError> queryKey,
      {bool isDisposed = false}) {
    final observers = _observers[queryKey] ?? {};

    final cacheDuration = observers.isEmpty
        ? Duration.zero
        : observers.map((o) => o.cacheDuration).reduce((a, b) => a > b ? a : b);

    if (observers.isEmpty || isDisposed) {
      _scheduleGc(queryKey, cacheDuration);
    } else {
      _cancelGc(queryKey);
    }
  }

  void _cancelGc(QueryKey queryKey) {
    _gcTimers[queryKey]?.cancel();
    _gcTimers.remove(queryKey);
  }

  void _scheduleGc(QueryKey queryKey, Duration cacheDuration) {
    _cancelGc(queryKey);
    final query = _queries[queryKey];

    void onGc() {
      if (query != null) {
        _remove(query);
      }
      _observers.remove(queryKey);
      _gcTimers.remove(queryKey);
    }

    _gcTimers[queryKey] = Timer(cacheDuration, onGc);
  }

  /// Sets cached query data identified by the given query key.
  /// If the query data doesn't exist already in the cache (that's why `previous` is nullable),
  /// it'll be created.
  /// The type of returned data from the updater function
  /// must match the type of data stored in the cache,
  /// otherwise an error will be thrown.
  ///
  /// Example:
  /// ```dart
  /// queryClient.setQueryData<List<Post>>(['posts'], (previous) {
  ///   return previous?.map((post) {
  ///     return post.copyWith(
  ///       title: "lorem ipsum"
  ///     );
  ///   }).toList() ?? <Post>[]
  /// })
  /// ```
  void setQueryData<TData, TError extends Exception>(
    RawQueryKey queryKey,
    TData Function(TData? previous) updater,
  ) {
    final query =
        build<TData, TError>(queryKey: QueryKey<TData, TError>(queryKey));
    dispatch(query.key, DispatchAction.success, updater(query.data));
  }

  /// Retrieves the query data for the given query key.
  TData? getQueryData<TData, TError extends Exception>(RawQueryKey queryKey) {
    try {
      final query = get<TData, TError>(QueryKey(queryKey));
      return query.data;
    } on QueryNotFoundException {
      return null;
    }
  }

  /// Marks the query as stale.
  /// If the query is being used in a widget, it will be refetched,
  /// otherwise it will be refetched when it is used by a widget at a later point in time.
  /// Supports partial matching, take a look at the exact option.
  ///
  /// Example:
  /// ```dart
  /// final queryClient = useQueryClient();
  ///
  /// // Invalidate every query with a key that starts with `post`
  /// queryClient.invalidateQueries(['posts']);
  ///
  /// // Both queries will be invalidated
  /// final posts = useQuery(['posts'], getPosts);
  /// final post = useQuery(['posts', 1], getPosts);
  ///
  /// // Use `exact: true` to exactly match the query
  /// queryClient.invalidateQueries(['posts'], exact: true);
  ///
  /// // Only this will invalidate
  /// final posts = useQuery(['posts'], getPosts);
  /// ```
  void invalidateQueries<TData, TError extends Exception>(
    RawQueryKey key, {
    bool exact = false,
  }) {
    // "No concurrent modification" error is probable
    // because we are not removing from the map
    // but just consistency with `removeQueries`
    final toInvalidate = <Query<TData, TError>>[];

    queries.forEach((queryKey, query) {
      if (exact) {
        if (queryKey.serialized == QueryKey(key).serialized &&
            query is Query<TData, TError>) {
          toInvalidate.add(query);
        }
      } else {
        final isPartialMatch = queryKey.raw.length >= key.length &&
            QueryKey(queryKey.raw.sublist(0, key.length)) == QueryKey(key);

        if (isPartialMatch && query is Query<TData, TError>) {
          toInvalidate.add(query);
        }
      }
    });

    for (final query in toInvalidate) {
      dispatch(query.key, DispatchAction.invalidate, null);
    }
  }

  /// Removes queries from the cache.
  void removeQueries<TData, TError extends Exception>(
    RawQueryKey key, {
    bool exact = false,
  }) {
    // Concurrent modification error if we try to remove while iterating
    // so, collect first, remove once iteration is done
    final toRemove = <Query<TData, TError>>[]; // or correct type of queryKey

    queries.forEach((queryKey, query) {
      if (exact) {
        if (queryKey.serialized == QueryKey(key).serialized &&
            query is Query<TData, TError>) {
          toRemove.add(query);
        }
      } else {
        final isPartialMatch = queryKey.raw.length >= key.length &&
            QueryKey(queryKey.raw.sublist(0, key.length)) == QueryKey(key);

        if (isPartialMatch && query is Query<TData, TError>) {
          toRemove.add(query);
        }
      }
    });

    for (final query in toRemove) {
      _remove(query);
    }
    _observers.remove(QueryKey(key));
    _gcTimers.remove(QueryKey(key));
  }

  /// The number of queries that are currently fetching.
  int get isFetching {
    return queries.entries
        .where((queryMap) => queryMap.value.isFetching)
        .length;
  }
}
