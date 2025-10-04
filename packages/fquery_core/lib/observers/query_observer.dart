import 'dart:async';
import 'package:fquery_core/fquery_core.dart';
import 'package:fquery_core/models/query.dart';
import 'package:fquery_core/observers/observer.dart';
import 'package:fquery_core/retry_resolver.dart';

/// A function that fetches data for a query.
typedef QueryFn<TData> = Future<TData> Function();

/// An observer is a class which subscribes to a query and updates its state when the query changes.
/// It is responsible for fetching the query and updating the cache.
/// There can be multiple observers for the same query and hence
/// sharing the same piece of data throughout the whole application.
class QueryObserver<TData, TError extends Exception>
    extends Observer<TData, TError, QueryOptions<TData, TError>> {
  final _resolver = RetryResolver();

  late QueryFn<TData> queryFn;

  @override
  Query<TData, TError> get query {
    return cache.build<TData, TError>(queryKey: queryKey);
  }

  /// Creates a new [QueryObserver] instance.
  QueryObserver({
    required super.cache,
    required QueryKey queryKey,
    required QueryFn<TData> queryFn,
    bool? enabled,
    RefetchOnMount? refetchOnMount,
    Duration? staleDuration,
    Duration? cacheDuration,
    Duration? refetchInterval,
    int? retryCount,
    Duration? retryDelay,
    super.listenToQueryCache = true,
  }) : super(
          queryKey: queryKey,
          enabled: enabled ?? cache.defaultQueryOptions.enabled,
          refetchOnMount:
              refetchOnMount ?? cache.defaultQueryOptions.refetchOnMount,
          staleDuration:
              staleDuration ?? cache.defaultQueryOptions.staleDuration,
          cacheDuration:
              cacheDuration ?? cache.defaultQueryOptions.cacheDuration,
          refetchInterval:
              refetchInterval ?? cache.defaultQueryOptions.refetchInterval,
          retryCount: retryCount ?? cache.defaultQueryOptions.retryCount,
          retryDelay: retryDelay ?? cache.defaultQueryOptions.retryDelay,
        ) {
    setOptions(
      QueryOptions(
        queryFn: queryFn,
        queryKey: queryKey,
        enabled: enabled,
        refetchOnMount: refetchOnMount,
        staleDuration: staleDuration,
        cacheDuration: cacheDuration,
        refetchInterval: refetchInterval,
        retryCount: retryCount,
        retryDelay: retryDelay,
      ),
    );
    cache.build<TData, TError>(queryKey: queryKey);
    if (listenToQueryCache) {
      cache.subscribe(hashCode, onQueryCacheNotification);
    }
  }

  @override
  void setOptions(QueryOptions<TData, TError> options) {
    queryFn = options.queryFn;
    super.setOptions(options);
  }

  @override
  void initialize() {
    // Initiate query on mount
    if (enabled == false) return;
    final isRefetching = !query.isLoading;
    final isInvalidated = query.isInvalidated;

    // [RefetchOnMount] behaviour is specified here
    if (isRefetching && !isInvalidated) {
      switch (refetchOnMount) {
        case RefetchOnMount.always:
          fetch();
          break;
        case RefetchOnMount.stale:
          if (isQueryStale) fetch();
          break;
        case RefetchOnMount.never:
          break;
      }
    } else {
      fetch();
    }
  }

  bool get isQueryStale {
    DateTime? staleAt = query.dataUpdatedAt?.add(staleDuration);
    return staleAt?.isBefore(DateTime.now()) ?? true;
  }

  @override
  void updateOptions(QueryOptions<TData, TError> options) {
    // Changes for side effects:
    // [enabled]
    // [refetchInterval]

    final refetchIntervalChanged = options.refetchInterval != refetchInterval;
    final isEnabledChanged = options.enabled != enabled;

    setOptions(options);

    if (isEnabledChanged) {
      if (enabled) {
        if (isQueryStale) fetch();
      } else {
        _resolver.cancel();
        cancelRefetch();
      }
    }

    if (refetchIntervalChanged) {
      // Schedules the next fetch if the [refetchInterval] is set.
      if (refetchInterval != null) {
        scheduleRefetch();
      } else {
        cancelRefetch();
      }
    }
  }

  @override
  Future<void> fetch() async {
    if (!enabled || query.isFetching) {
      return;
    }

    final isRefetching = !query.isLoading;

    cache.dispatch(query.key, DispatchAction.fetch, null);
    // Important: State change, then any other
    // function invocation in the following callbacks
    DispatchAction actionFlag = DispatchAction.fetch;

    await _resolver.resolve<TData, TError>(
      queryFn,
      retryCount: retryCount,
      retryDelay: retryDelay,
      onResolve: (data) {
        cache.dispatch(query.key, DispatchAction.success, data);
        actionFlag = DispatchAction.success;
      },
      onError: (error) {
        final action =
            isRefetching ? DispatchAction.refetchError : DispatchAction.error;
        cache.dispatch(query.key, action, error);
        actionFlag = DispatchAction.error;
      },
      onCancel: () {
        cache.dispatch(query.key, DispatchAction.cancelFetch, null);
        actionFlag = DispatchAction.cancelFetch;
      },
    );

    // Refetching is scheduled here after success or error
    final scheduleRefetchActions = [
      DispatchAction.success,
      DispatchAction.error,
    ];
    if (scheduleRefetchActions.contains(actionFlag)) {
      scheduleRefetch();
    }
  }

  @override
  void onQueryCacheNotification() {
    notifyObservers();
    if (query.isInvalidated) {
      fetch();
    }
  }

  @override
  void dispose() {
    super.dispose();
    cache.unsubscribe(hashCode);
    cache.dismantle(this);
    _resolver.cancel();
  }
}
