import 'dart:async';

import 'package:fquery_core/src/query_cache.dart';
import 'package:fquery_core/src/query.dart';
import 'package:fquery_core/src/retry_resolver.dart';
import 'package:collection/collection.dart';

/// A mixin that provides observer pattern functionality.
///
/// Allows classes to manage a list of subscribers and notify them when
/// state changes occur. Subscribers are identified by unique integer IDs.
mixin Observable {
  /// Map of listener ID to listener function.
  final Map<int, Function> _listeners = {};

  /// Subscribes a listener with the given ID.
  ///
  /// The [listener] function will be called whenever [notifyObservers] is invoked.
  /// If a listener with the same ID already exists, it will be replaced.
  ///
  /// Parameters:
  /// - `listenerId`: A unique identifier for this listener
  /// - `listener`: The callback function to invoke on notifications
  void subscribe(int listenerId, Function listener) {
    _listeners[listenerId] = listener;
  }

  /// Unsubscribes a listener with the given ID.
  ///
  /// The listener will no longer receive notifications.
  /// Safe to call even if the listener doesn't exist.
  ///
  /// Parameters:
  /// - `observerId`: The ID of the listener to remove
  void unsubscribe(int observerId) {
    _listeners.remove(observerId);
  }

  /// Notifies all subscribed listeners.
  ///
  /// Calls each listener function in the [_listeners] map.
  /// This is typically used to signal that an observed state has changed.
  void notifyObservers() {
    _listeners.forEach((observerId, listener) {
      listener();
    });
  }

  /// Clears all listeners.
  ///
  /// Removes all subscribed listeners, effectively disconnecting all observers.
  /// Useful for cleanup when the observable is being disposed.
  void disposeSubscribers() {
    _listeners.clear();
  }
}

/// Base class for all observers.
///
/// Provides common functionality for observing and managing queries including
/// lifecycle management, configuration options, and refetch scheduling.
///
/// Type parameters:
/// - `TData`: The type of data being queried
/// - `TError`: The type of error that can occur
/// - `TOptions`: The type of options for configuring the observer
abstract class Observer<TData, TError extends Exception,
    TOptions extends BaseQueryOptions<TData, TError>> with Observable {
  /// The query cache this observer is connected to.
  late final QueryCache cache;

  /// Timer for scheduling periodic refetches.
  Timer? _refetchTimer;

  /// The key that uniquely identifies this query.
  final QueryKey<TData, TError> queryKey;

  /// Whether this observer is enabled.
  ///
  /// When disabled, the observer won't fetch data or refetch automatically.
  late bool enabled;

  /// Specifies when to refetch when the observer is first initialized.
  ///
  /// Options:
  /// - `RefetchOnMount.always` - Always refetch on mount
  /// - `RefetchOnMount.stale` - Refetch only if data is stale
  /// - `RefetchOnMount.never` - Never refetch on mount
  late RefetchOnMount refetchOnMount;

  /// Duration after which query data is considered stale.
  ///
  /// Used by `RefetchOnMount.stale` to determine if a refetch is needed.
  late Duration staleDuration;

  /// Duration that fetched data is kept in cache before being removed.
  late Duration cacheDuration;

  /// Interval for automatic periodic refetches.
  ///
  /// If set, the query will automatically refetch at this interval.
  /// If `null`, no automatic refetching is done.
  late Duration? refetchInterval;

  /// Number of times to retry failed queries.
  late int retryCount;

  /// Delay between retry attempts.
  late Duration retryDelay;

  /// The query being managed by this observer.
  Query<TData, TError> get query;

  /// Creates a new observer instance.
  Observer({
    required this.cache,
    required this.queryKey,
    required this.enabled,
    required this.refetchOnMount,
    required this.staleDuration,
    required this.cacheDuration,
    required this.refetchInterval,
    required this.retryCount,
    required this.retryDelay,
  });

  /// Applies options to this observer.
  ///
  /// Extracts values from [options] and applies them, using cache defaults
  /// for any options that are null.
  void _setOptions(TOptions options) {
    enabled = options.enabled ?? cache.defaultQueryOptions.enabled;
    refetchOnMount =
        options.refetchOnMount ?? cache.defaultQueryOptions.refetchOnMount;
    staleDuration =
        options.staleDuration ?? cache.defaultQueryOptions.staleDuration;
    cacheDuration =
        options.cacheDuration ?? cache.defaultQueryOptions.cacheDuration;
    refetchInterval =
        options.refetchInterval ?? cache.defaultQueryOptions.refetchInterval;
    retryCount = options.retryCount ?? cache.defaultQueryOptions.retryCount;
    retryDelay = options.retryDelay ?? cache.defaultQueryOptions.retryDelay;
  }

  /// Callback for when the query cache is updated.
  ///
  /// Called by the query cache when this observer's query is modified.
  /// Typically triggers [notifyObservers] to propagate changes to listeners.
  // ignore: unused_element
  void _onQueryCacheNotification();

  /// Schedules the next automatic refetch based on [refetchInterval].
  ///
  /// Cancels any existing scheduled refetch and schedules a new one.
  /// Does nothing if [refetchInterval] is null.
  void _scheduleRefetch() {
    if (refetchInterval == null) return;
    _refetchTimer?.cancel();
    _refetchTimer = Timer(refetchInterval as Duration, fetch);
  }

  /// Cancels any scheduled refetch.
  void _cancelRefetch() {
    _refetchTimer?.cancel();
  }

  /// Fetches the query data.
  ///
  /// This is the main method responsible for executing the query function
  /// and updating the cache with the result. Implementations should handle
  /// errors, retries, and cache updates.
  Future<void> fetch();

  /// Updates the observer with new options.
  ///
  /// Applies new configuration options and handles any necessary side effects
  /// (e.g., stopping/starting automatic refetches, re-fetching if enabled changed).
  ///
  /// Parameters:
  /// - `newOptions`: The new options to apply
  void updateOptions(TOptions newOptions);

  /// Initializes the observer.
  ///
  /// Called when the observer is first created. Determines whether to fetch
  /// based on [enabled], [refetchOnMount], and whether data is already cached.
  void initialize();

  /// Disposes the observer.
  ///
  /// Cancels any scheduled refetches and cleans up resources.
  /// Called when the observer is no longer needed.
  void dispose() {
    _refetchTimer?.cancel();
  }
}

/// A function that fetches query data.
///
/// Returns a [FutureOr] of type [TData], allowing both sync and async functions.
typedef QueryFn<TData> = FutureOr<TData> Function();

/// Manages a single query and its state.
///
/// Responsible for:
/// - Fetching query data using a provided function
/// - Managing fetch state (loading, success, error)
/// - Handling retries on error
/// - Scheduling automatic refetches at intervals
/// - Notifying subscribers of state changes
/// - Updating the shared query cache
///
/// Type parameters:
/// - `TData`: The type of data returned by the query
/// - `TError`: The type of error that can be thrown by the query
class QueryObserver<TData, TError extends Exception>
    extends Observer<TData, TError, QueryOptions<TData, TError>> {
  final _resolver = RetryResolver();

  /// The function used to fetch data for this observer's query.
  late QueryFn<TData> queryFn;

  @override
  Query<TData, TError> get query {
    return cache.build<TData, TError>(queryKey: queryKey);
  }

  /// Creates a new [QueryObserver] instance.
  QueryObserver({
    required super.cache,
    required QueryKey<TData, TError> queryKey,
    required QueryFn<TData> queryFn,
    bool? enabled,
    RefetchOnMount? refetchOnMount,
    Duration? staleDuration,
    Duration? cacheDuration,
    Duration? refetchInterval,
    int? retryCount,
    Duration? retryDelay,
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
    _setOptions(
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
    cache.subscribe(hashCode, _onQueryCacheNotification);
  }

  @override
  void _setOptions(QueryOptions<TData, TError> options) {
    queryFn = options.queryFn;
    super._setOptions(options);
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
          if (_isQueryStale) fetch();
          break;
        case RefetchOnMount.never:
          break;
      }
    } else {
      fetch();
    }
  }

  bool get _isQueryStale {
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

    _setOptions(options);

    if (isEnabledChanged) {
      if (enabled) {
        initialize();
      } else {
        _resolver.cancel();
        _cancelRefetch();
      }
    }

    if (refetchIntervalChanged) {
      // Schedules the next fetch if the [refetchInterval] is set.
      if (refetchInterval != null) {
        _scheduleRefetch();
      } else {
        _cancelRefetch();
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
      _scheduleRefetch();
    }
  }

  @override
  void _onQueryCacheNotification() {
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

/// Observer for infinite queries.
///
/// Manages a paginated query where each page is fetched with a page parameter.
/// It supports fetching forward and backward, refetching all cached pages, and
/// trimming cached pages with [maxPages].
class InfiniteQueryObserver<TData, TError extends Exception, TPageParam>
    extends Observer<InfiniteQueryData<TData, TPageParam>, TError,
        InfiniteQueryOptions<TData, TError, TPageParam>> {
  var _refetchResolvers = <RetryResolver>[];
  final _resolver = RetryResolver();

  late TPageParam _paramFlag;
  late FetchMeta _metaFlag;

  /// The function used to fetch a page for the current page parameter.
  late InfiniteQueryFn<TData, TPageParam> queryFn;

  /// The first page parameter used when the query has no cached pages.
  late TPageParam initialPageParam;

  /// Computes the next page parameter from the current page data.
  late TPageParam? Function(TData, List<TData>, TPageParam, List<TPageParam>)
      getNextPageParam;

  /// Computes the previous page parameter from the current page data.
  late TPageParam? Function(TData, List<TData>, TPageParam, List<TPageParam>)?
      getPreviousPageParam;

  /// The maximum number of pages to keep in the cache.
  late int? maxPages;

  @override
  void _onQueryCacheNotification() {
    notifyObservers();
    if (query.isInvalidated) {
      refetch();
    }
  }

  /// Creates a new instance of [InfiniteQueryObserver].
  InfiniteQueryObserver({
    required super.cache,
    required QueryKey<InfiniteQueryData<TData, TPageParam>, TError> queryKey,
    required InfiniteQueryFn<TData, TPageParam> queryFn,
    bool? enabled,
    RefetchOnMount? refetchOnMount,
    Duration? staleDuration,
    Duration? cacheDuration,
    Duration? refetchInterval,
    int? retryCount,
    Duration? retryDelay,
    required TPageParam initialPageParam,
    required TPageParam? Function(
            TData, List<TData>, TPageParam, List<TPageParam>)
        getNextPageParam,
    TPageParam? Function(TData, List<TData>, TPageParam, List<TPageParam>)?
        getPreviousPageParam,
    int? maxPages,
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
    _setOptions(
      InfiniteQueryOptions(
        queryFn: queryFn,
        queryKey: queryKey,
        enabled: enabled,
        refetchOnMount: refetchOnMount,
        staleDuration: staleDuration,
        cacheDuration: cacheDuration,
        refetchInterval: refetchInterval,
        retryCount: retryCount,
        retryDelay: retryDelay,
        initialPageParam: initialPageParam,
        getNextPageParam: getNextPageParam,
        getPreviousPageParam: getPreviousPageParam,
        maxPages: maxPages,
      ),
    );
    cache.build<InfiniteQueryData<TData, TPageParam>, TError>(
      queryKey: queryKey,
    );
    cache.subscribe(hashCode, _onQueryCacheNotification);
    _paramFlag = initialPageParam;
    _metaFlag = query.fetchMeta ?? FetchMeta(direction: FetchDirection.forward);
  }

  @override
  Query<InfiniteQueryData<TData, TPageParam>, TError> get query {
    return cache.build<InfiniteQueryData<TData, TPageParam>, TError>(
      queryKey: queryKey,
    );
  }

  @override
  void initialize() {
    // Initiate query on mount
    if (enabled == false) return;
    final isRefetching = !query.isLoading;
    final isInvalidated = query.isInvalidated;

    // [RefetchOnMount] behavior is specified here
    if (isRefetching && !isInvalidated) {
      switch (refetchOnMount) {
        case RefetchOnMount.always:
          refetch();
          break;
        case RefetchOnMount.stale:
          DateTime? staleAt = query.dataUpdatedAt?.add(staleDuration);
          final isStale = staleAt?.isBefore(DateTime.now()) ?? true;
          if (isStale) refetch();
          break;
        case RefetchOnMount.never:
          break;
      }
    } else {
      fetch();
    }
  }

  @override
  void _setOptions(InfiniteQueryOptions<TData, TError, TPageParam> options) {
    super._setOptions(options);
    queryFn = options.queryFn;
    initialPageParam = options.initialPageParam;
    getNextPageParam = options.getNextPageParam;
    getPreviousPageParam = options.getPreviousPageParam;
    maxPages = options.maxPages;
  }

  @override
  void updateOptions(InfiniteQueryOptions<TData, TError, TPageParam> options) {
    final refetchIntervalChanged = options.refetchInterval != refetchInterval;
    final isEnabledChanged = options.enabled != enabled;
    _setOptions(options);

    if (isEnabledChanged) {
      if (enabled) {
        if (query.isLoading) {
          fetch();
        }
      } else {
        _resolver.cancel();
        _cancelRefetch();
      }
    }

    if (refetchIntervalChanged) {
      // Schedules the next fetch if the [refetchInterval] is set.
      if (refetchInterval != null) {
        _scheduleRefetch();
      } else {
        _cancelRefetch();
      }
    }
  }

  /// Fetches the next page using the [getNextPageParam] function.
  void fetchNextPage() {
    final data = query.data;
    if (data == null) return;

    final pages = data.pages;
    final pageParams = data.pageParams;
    final lastPage = pages.last;
    final lastPageParam = pageParams.last;

    final nextPageParam = getNextPageParam(
      lastPage,
      pages,
      lastPageParam,
      pageParams,
    );
    if (nextPageParam == null) return;

    _paramFlag = nextPageParam;
    _metaFlag = FetchMeta(direction: FetchDirection.forward);

    fetch();
  }

  /// Fetches the previous page using the [getPreviousPageParam] function.
  void fetchPreviousPage() {
    final data = query.data;
    if (data == null) return;

    final pages = data.pages;
    final pageParams = data.pageParams;
    final firstPage = pages.first;
    final firstPageParam = pageParams.first;

    final previousParam = getPreviousPageParam?.call(
      firstPage,
      pages,
      firstPageParam,
      pageParams,
    );
    if (previousParam == null) return;

    _paramFlag = previousParam;
    _metaFlag = FetchMeta(direction: FetchDirection.backward);

    fetch();
  }

  /// Used to refetch query, it fetches all the pages sequentially.
  void refetch() {
    if (!enabled || query.isFetching) {
      return;
    }

    // Can't refetch if there's no data already
    final data = query.data;
    if (data == null) return;

    cache.dispatch(query.key, DispatchAction.fetch, null);
    final pageParams = data.pageParams;
    _refetchResolvers = [];

    pageParams.forEachIndexed((i, param) async {
      final resolver = RetryResolver();
      _refetchResolvers.add(resolver);

      await resolver.resolve<TData, TError>(
        () => queryFn(param),
        retryCount: retryCount,
        retryDelay: retryDelay,
        onResolve: (refetchedData) {
          // Make a copy of pages to replace with refetched
          // data without directly mutating the old `pages`
          final newPages = [...data.pages];
          newPages[i] = refetchedData;

          // Only dispatch success action when we're done refetching
          // i.e we've fetched the last page
          final isLastPage = i + 1 == pageParams.length;
          final action = isLastPage
              ? DispatchAction.success
              : DispatchAction.refetchSequence;

          final newData = data.copyWith(pages: [...newPages]);
          cache.dispatch(query.key, action, newData);
          _scheduleRefetch();
        },
        onError: (error) {
          cache.dispatch(query.key, DispatchAction.refetchError, error);
        },
        onCancel: () {
          cache.dispatch(query.key, DispatchAction.cancelFetch, null);
        },
      );
    });
  }

  /// This is "the" function responsible for fetching the query.
  @override
  Future<void> fetch() async {
    final pageParam = _paramFlag;
    final meta = _metaFlag;

    if (!enabled || query.isFetching) {
      return;
    }

    cache.dispatch(query.key, DispatchAction.fetch, meta);
    // Important: State change, then any other
    // function invocation in the following callbacks
    DispatchAction actionFlag = DispatchAction.fetch;
    await _resolver.resolve<TData, TError>(
      () => queryFn(pageParam),
      retryCount: retryCount,
      retryDelay: retryDelay,
      onResolve: (data) {
        final pages = [...(query.data?.pages ?? [])];
        final pageParams = [...(query.data?.pageParams ?? [])];

        // `maxPages` optionmaxPagesour is defined here
        if (pages.length == maxPages) {
          if (meta.direction == FetchDirection.forward) {
            // Remove the first page
            pages.removeAt(0);
            pageParams.removeAt(0);
          } else {
            pages.removeLast();
            pageParams.removeLast();
          }
        }
        final newData = query.data?.copyWith(
              pages: meta.direction == FetchDirection.forward
                  ? [...pages, data]
                  : [data, ...pages],
              pageParams: meta.direction == FetchDirection.forward
                  ? [...pageParams, pageParam]
                  : [pageParam, ...pageParams],
            ) ??
            InfiniteQueryData<TData, TPageParam>(
              pages: [data],
              pageParams: [pageParam],
            );

        cache.dispatch(query.key, DispatchAction.success, newData);
        actionFlag = DispatchAction.success;
      },
      onError: (error) {
        cache.dispatch(query.key, DispatchAction.error, error);
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
      _scheduleRefetch();
    }
  }

  /// Disposes the observer
  @override
  void dispose() {
    super.dispose();
    cache.unsubscribe(hashCode);
    cache.dismantle(this);
    _resolver.cancel();
    for (var resolver in _refetchResolvers) {
      resolver.cancel();
    }
  }
}
