import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:fquery_core/src/cache_map.dart';
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

typedef QueriesCacheMap = Map<QueryKey, CacheMap>;

/// Stores query state and coordinates notifications to query observers.
///
/// The cache is the central state container for queries. It can build, read,
/// update, invalidate, and remove cached query entries, and it garbage-collects
/// unused entries after their configured cache duration.
class QueryCache with Observable<QueryKey> {
  final QueriesCacheMap _queriesCacheMap = {};

  /// Defaults applied to query observers when an option is omitted.
  final DefaultQueryOptions defaultQueryOptions;

  /// The queries currently stored in the cache.
  QueriesMap get queries => UnmodifiableMapView(
        Map.fromEntries(
          _queriesCacheMap.entries.map(
            (entry) => MapEntry(entry.key, entry.value.query),
          ),
        ),
      );

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
          isRefetchError: false,
        );
      case DispatchAction.invalidate:
        return state.copyWith(isInvalidated: true);
      case DispatchAction.refetchSequence:
        return state.copyWith(
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
    final cacheMap = _queriesCacheMap[queryKey];
    if (cacheMap == null) {
      throw QueryNotFoundException(queryKey);
    }
    return cacheMap.query as Query<TData, TError>;
  }

  /// Removes a query from the cache.
  void _remove<TData, TError extends Exception>(Query<TData, TError> query) {
    _cancelGc(query.key);
    _queriesCacheMap.remove(query.key);
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
      final cacheMap = _queriesCacheMap[queryKey];
      if (cacheMap == null) throw QueryNotFoundException(queryKey);

      // if (cacheMap.query.data.runtimeType != TData) {
      //   print(cacheMap);
      //   throw Exception('hell, ${cacheMap.query.data.runtimeType}');
      // }
      query = cacheMap.query as Query<TData, TError>;

      _queriesCacheMap[queryKey] = cacheMap.copyWith(
        observers: (observer == null)
            ? cacheMap.observers
            : {...cacheMap.observers, observer},
        cacheDuration: Duration(
          milliseconds: max(
            cacheMap.cacheDuration.inMilliseconds,
            observer?.cacheDuration.inMilliseconds ?? 0,
          ),
        ),
        query: cacheMap.query,
      );
    } on QueryNotFoundException {
      query = Query(queryKey);
      _queriesCacheMap[queryKey] = CacheMap(
        observers: (observer == null) ? {} : {observer},
        cacheDuration:
            observer?.cacheDuration ?? defaultQueryOptions.cacheDuration,
        query: query,
      );
    }
    _gcRoutine(queryKey);

    return query;
  }

  void _gcRoutine(QueryKey queryKey) {
    final cacheMap = _queriesCacheMap[queryKey];
    if (cacheMap == null) return;
    if (cacheMap.observers.isEmpty) {
      _scheduleGc(queryKey, cacheMap.cacheDuration);
    } else {
      _cancelGc(queryKey);
    }
  }

  /// Detaches [observer] and schedules garbage collection if it was the last one.
  void dismantle(Observer observer) {
    final cacheMap = _queriesCacheMap[observer.queryKey];
    if (cacheMap == null) return;

    final observers = Set<Observer>.from(cacheMap.observers);
    observers.remove(observer);

    _queriesCacheMap[observer.queryKey] = cacheMap.copyWith(
      observers: observers,
    );

    _gcRoutine(observer.queryKey);
  }

  /// Dispatches an action to the reducer and notifies observers.
  void dispatch<TData, TError extends Exception>(
    QueryKey<TData, TError> queryKey,
    DispatchAction action,
    Object? data,
  ) {
    final cacheMap = _queriesCacheMap[queryKey];
    if (cacheMap == null) return;
    try {
      final query = _reducer(
        cacheMap.query,
        action,
        data,
      );
      _queriesCacheMap[queryKey] = cacheMap.copyWith(query: query);
      notifyObservers(scope: queryKey);
    } on QueryNotFoundException {
      return;
    }
  }

  void _cancelGc(QueryKey queryKey) {
    final cacheMap = _queriesCacheMap[queryKey];
    if (cacheMap == null) return;
    var timer = cacheMap.gcTimer;
    timer?.cancel();

    _queriesCacheMap[queryKey] = cacheMap.copyWith(gcTimer: null);
  }

  void _scheduleGc(QueryKey queryKey, Duration cacheDuration) {
    final cacheMap = _queriesCacheMap[queryKey];
    if (cacheMap == null) return;
    final timer = cacheMap.gcTimer;
    if (timer != null && timer.isActive) return;

    void onGc() {
      final cacheMap = _queriesCacheMap[queryKey];
      if (cacheMap == null) return;
      _remove(cacheMap.query);
    }

    _queriesCacheMap[queryKey] = cacheMap.copyWith(
      gcTimer: Timer(cacheDuration, onGc),
    );
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
  }

  /// The number of queries that are currently fetching.
  int get isFetching {
    return queries.entries
        .where((queryMap) => queryMap.value.isFetching)
        .length;
  }
}
