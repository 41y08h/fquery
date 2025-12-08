import 'dart:async';
import 'dart:math';

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

/// The cache that holds all the queries.
class QueryCache with Observable {
  final QueriesMap _queries = {};
  final Map<QueryKey, List<Observer>> _observers = {};
  final Map<QueryKey, Timer> _gcTimers = {};
  final Map<QueryKey, Duration> _maxCacheDurations = {};
  final DefaultQueryOptions defaultQueryOptions;

  /// Returns an unmodifiable view of the queries in the cache.
  QueriesMap get queries => _queries;

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
  Query<TData, TError> get<TData, TError extends Exception>(QueryKey queryKey) {
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
    _queries.removeWhere((key, value) => value == query);
  }

  /// Returns a query identified by the query key.
  /// If it doesn't exist already,
  /// creates a new one and adds it to the cache.
  Query<TData, TError> build<TData, TError extends Exception>({
    required QueryKey queryKey,
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
    _observers.putIfAbsent(observer.queryKey, () => []).add(observer);
    _gcRoutine();
  }

  /// This is called when an observer is disposed
  void dismantle(Observer observer) {
    // Set max cache duration before removing the observer
    final queryKey = observer.queryKey;
    final currentMaxCacheDuration =
        _maxCacheDurations[queryKey] ?? Duration.zero;

    _maxCacheDurations[queryKey] = Duration(
      milliseconds: max(
        observer.cacheDuration.inMilliseconds,
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
    try {
      queries[queryKey] = _reducer<TData, TError>(
        get<TData, TError>(queryKey),
        action,
        data,
      );
      notifyObservers();
    } on QueryNotFoundException {
      return;
    }
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

  /// Sets the query cache idendifiable by the given query key.
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
    final query = build<TData, TError>(queryKey: QueryKey(queryKey));
    dispatch(query.key, DispatchAction.success, updater(query.data));
  }

  /// Retrieves the query data for the given query key.
  TData? getQueryData<TData, TError extends Exception>(RawQueryKey queryKey) {
    try {
      final query = get<TData, TError>(QueryKey(queryKey));
      return query.data;
    } on QueryNotFoundException {
      return null as TData?;
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
    // No concurrent modification error is probable
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

  /// Returns the number of queries that are currently fetching.
  get isFetching {
    return queries.entries
        .where((queryMap) => queryMap.value.isFetching)
        .length;
  }
}
