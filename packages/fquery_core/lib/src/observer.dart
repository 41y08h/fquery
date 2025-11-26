import 'dart:async';

import 'package:fquery_core/src/query_cache.dart';
import 'package:fquery_core/src/query.dart';
import 'package:fquery_core/src/retry_resolver.dart';
import 'package:collection/collection.dart';

mixin Observable {
  final Map<int, Function> _listeners = {};
  void subscribe(int listenerId, Function listener) {
    _listeners[listenerId] = listener;
  }

  void unsubscribe(int observerId) {
    _listeners.remove(observerId);
  }

  void notifyObservers() {
    _listeners.forEach((observerId, listener) {
      listener();
    });
  }

  void disposeSubscribers() {
    _listeners.clear();
  }
}

abstract class Observer<TData, TError extends Exception,
    TOptions extends BaseQueryOptions> with Observable {
  late final QueryCache cache;
  Timer? _refetchTimer;

  final QueryKey queryKey;
  // Tells whether the query is enabled
  late bool enabled;

  /// Specifies the behavior of the query instance when the widget is first built and the data is already available.
  /// - `RefetchOnMount.always` - will always re-fetch when the widget is built.
  /// - `RefetchOnMount.stale` - will fetch the data if it is stale (see `staleDuration`).
  /// - `RefetchOnMount.never` - will never re-fetch.
  late RefetchOnMount refetchOnMount;
  late Duration staleDuration;
  late Duration cacheDuration;
  late Duration? refetchInterval;
  late int retryCount;
  late Duration retryDelay;

  /// Query to which the observer is subscribed to
  Query get query;

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

  /// Callback function for receiving notifications
  /// from the query cache, typically when query is updated
  // ignore: unused_element
  void _onQueryCacheNotification();

  /// Schedules the next fetch if the [refetchInterval] is set.
  void _scheduleRefetch() {
    if (refetchInterval == null) return;
    _refetchTimer?.cancel();
    _refetchTimer = Timer(refetchInterval as Duration, fetch);
  }

  /// Cancels any scheduled refetch
  void _cancelRefetch() {
    _refetchTimer?.cancel();
  }

  /// The function responsible for fetching the data
  Future<void> fetch();

  /// Updates the options and produces any side effects required
  void updateOptions(TOptions newOptions);

  /// Starts the initial fetch routine
  void initialize();

  /// Disposes the observer
  void dispose() {
    _refetchTimer?.cancel();
  }
}

/// A function that fetches data for a query.
typedef QueryFn<TData> = FutureOr<TData> Function();

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
class InfiniteQueryObserver<TData, TError extends Exception, TPageParam>
    extends Observer<TData, TError,
        InfiniteQueryOptions<TData, TError, TPageParam>> {
  var _refetchResolvers = <RetryResolver>[];
  final _resolver = RetryResolver();

  late TPageParam _paramFlag;
  late FetchMeta _metaFlag;

  late InfiniteQueryFn<TData, TPageParam> queryFn;
  late TPageParam initialPageParam;
  late TPageParam? Function(TData, List<TData>, TPageParam, List<TPageParam>)
      getNextPageParam;
  late TPageParam? Function(TData, List<TData>, TPageParam, List<TPageParam>)?
      getPreviousPageParam;
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
    required QueryKey queryKey,
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
          // data without directly mutataing the old `pages`
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

        // `maxPages` option's behaviour is defined here
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
