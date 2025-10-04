import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fquery_core/fquery_core.dart';
import 'package:fquery_core/models/query.dart';
import 'package:fquery_core/observers/observer.dart';
import 'package:fquery_core/retry_resolver.dart';

/// The function used to fetch a page of data in an infinite query.
typedef InfiniteQueryFn<TData, TPageParam> = Future<TData> Function(TPageParam);

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
    super.listenToQueryCache = true,
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
    setOptions(
      InfiniteQueryOptions(
        queryFn: queryFn,
        queryKey: queryKey,
        enabled: enabled ?? cache.defaultQueryOptions.enabled,
        refetchOnMount:
            refetchOnMount ?? cache.defaultQueryOptions.refetchOnMount,
        staleDuration: staleDuration ?? cache.defaultQueryOptions.staleDuration,
        cacheDuration: cacheDuration ?? cache.defaultQueryOptions.cacheDuration,
        refetchInterval:
            refetchInterval ?? cache.defaultQueryOptions.refetchInterval,
        retryCount: retryCount ?? cache.defaultQueryOptions.retryCount,
        retryDelay: retryDelay ?? cache.defaultQueryOptions.retryDelay,
        initialPageParam: initialPageParam,
        getNextPageParam: getNextPageParam,
        getPreviousPageParam: getPreviousPageParam,
      ),
    );
    cache.build<InfiniteQueryData<TData, TPageParam>, TError>(
      queryKey: queryKey,
    );
    if (listenToQueryCache) {
      cache.subscribe(hashCode, onQueryCacheNotification);
    }
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
  void onQueryCacheNotification() {
    notifyObservers();
    if (query.isInvalidated) {
      refetch();
    }
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
  void setOptions(InfiniteQueryOptions<TData, TError, TPageParam> options) {
    super.setOptions(options);
    queryFn = options.queryFn;
    initialPageParam = options.initialPageParam;
    getNextPageParam = options.getNextPageParam;
    getPreviousPageParam = options.getPreviousPageParam;
  }

  @override
  void updateOptions(InfiniteQueryOptions<TData, TError, TPageParam> options) {
    final refetchIntervalChanged = options.refetchInterval != refetchInterval;
    final isEnabledChanged = options.enabled != enabled;
    setOptions(options);

    if (isEnabledChanged) {
      if (enabled) {
        if (query.isLoading) {
          fetch();
        }
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
          scheduleRefetch();
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
      scheduleRefetch();
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
