import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/observable.dart';
import 'package:fquery/src/observers/observer.dart';
import 'package:fquery/src/retry_resolver.dart';

/// The function used to fetch a page of data in an infinite query.
typedef InfiniteQueryFn<TData, TPageParam> = Future<TData> Function(TPageParam);

/// Observer for infinite queries.
class InfiniteQueryObserver<TData, TError extends Exception, TPageParam>
    with
        Observable,
        Observer<TData, TError,
            InfiniteQueryOptions<TData, TError, TPageParam>> {
  final _resolver = RetryResolver();
  var _refetchResolvers = <RetryResolver>[];
  Timer? _refetchTimer;

  /// Creates a new instance of [InfiniteQueryObserver].
  InfiniteQueryObserver({
    required client,
    required options,
  }) {
    this.client = client;
    this.options = options;
    client.queryCache.build<InfiniteQueryData<TData, TPageParam>, TError>(
      queryKey: options.queryKey,
      client: client,
    );
    client.queryCache.addListener(hashCode, _onQueryUpdated);
  }

  Query<InfiniteQueryData<TData, TPageParam>, TError> get query {
    return client.queryCache.get(options.queryKey);
  }

  void _onQueryUpdated() {
    notifyListeners();
    if (query.isInvalidated) {
      refetch();
    }
  }

  /// Initializes the observer
  void initialize() {
    // Initiate query on mount
    if (options.enabled == false) return;
    final isRefetching = !query.isLoading;
    final isInvalidated = query.isInvalidated;

    // [RefetchOnMount] behavior is specified here
    if (isRefetching && !isInvalidated) {
      switch (options.refetchOnMount) {
        case RefetchOnMount.always:
          refetch();
          break;
        case RefetchOnMount.stale:
          DateTime? staleAt = query.dataUpdatedAt?.add(options.staleDuration);
          final isStale = staleAt?.isBefore(DateTime.now()) ?? true;
          if (isStale) refetch();
          break;
        case RefetchOnMount.never:
          break;
      }
    } else {
      fetch(
        options.initialPageParam,
        FetchMeta(direction: FetchDirection.forward),
      );
    }
  }

  /// Updates the options and produces any side effects required
  void updateOptions(InfiniteQueryOptions<TData, TError, TPageParam> options) {
    final refetchIntervalChanged =
        this.options.refetchInterval != options.refetchInterval;
    final isEnabledChanged = this.options.enabled != options.enabled;
    this.options = options;

    if (isEnabledChanged) {
      if (options.enabled) {
        if (query.isLoading) {
          fetch(
            options.initialPageParam,
            FetchMeta(direction: FetchDirection.forward),
          );
        }
      } else {
        _resolver.cancel();
        _refetchTimer?.cancel();
      }
    }

    if (refetchIntervalChanged) {
      // Schedules the next fetch if the [options.refetchInterval] is set.
      if (options.refetchInterval != null) {
        scheduleRefetch();
      } else {
        _refetchTimer?.cancel();
        _refetchTimer = null;
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

    final nextPageParam = options.getNextPageParam(
      lastPage,
      pages,
      lastPageParam,
      pageParams,
    );
    if (nextPageParam == null) return;

    fetch(
      nextPageParam,
      FetchMeta(direction: FetchDirection.forward),
    );
  }

  /// Fetches the previous page using the [getPreviousPageParam] function.
  void fetchPreviousPage() {
    final data = query.data;
    if (data == null) return;

    final pages = data.pages;
    final pageParams = data.pageParams;
    final firstPage = pages.first;
    final firstPageParam = pageParams.first;

    final previousParam = options.getPreviousPageParam?.call(
      firstPage,
      pages,
      firstPageParam,
      pageParams,
    );
    if (previousParam == null) return;

    fetch(
      previousParam,
      FetchMeta(direction: FetchDirection.backward),
    );
  }

  /// Used to refetch query, it fetches all the pages sequentially.
  void refetch() {
    if (!options.enabled || query.isFetching) {
      return;
    }

    // Can't refetch if there's no data already
    final data = query.data;
    if (data == null) return;

    client.queryCache.dispatch(query.key, DispatchAction.fetch, null);
    final pageParams = data.pageParams;
    _refetchResolvers = [];

    pageParams.forEachIndexed((i, param) async {
      final resolver = RetryResolver();
      _refetchResolvers.add(resolver);

      await resolver.resolve<TData>(
        () => options.queryFn(param),
        retryCount: options.retryCount,
        retryDelay: options.retryDelay,
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
          client.queryCache.dispatch(query.key, action, newData);
        },
        onError: (error) {
          client.queryCache
              .dispatch(query.key, DispatchAction.refetchError, error);
        },
        onCancel: () {
          client.queryCache
              .dispatch(query.key, DispatchAction.cancelFetch, null);
        },
      );
    });
  }

  /// This is "the" function responsible for fetching the query.
  Future<void> fetch(TPageParam pageParam, FetchMeta meta) async {
    if (!options.enabled || query.isFetching) {
      return;
    }

    client.queryCache.dispatch(query.key, DispatchAction.fetch, meta);
    // Important: State change, then any other
    // function invocation in the following callbacks
    DispatchAction actionFlag = DispatchAction.fetch;
    await _resolver.resolve<TData>(
      () => options.queryFn(pageParam),
      retryCount: options.retryCount,
      retryDelay: options.retryDelay,
      onResolve: (data) {
        final pages = [...(query.data?.pages ?? [])];
        final pageParams = [...(query.data?.pageParams ?? [])];

        // `maxPages` option's behaviour is defined here
        if (pages.length == options.maxPages) {
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

        client.queryCache.dispatch(query.key, DispatchAction.success, newData);
        actionFlag = DispatchAction.success;
      },
      onError: (error) {
        client.queryCache.dispatch(query.key, DispatchAction.error, error);
        actionFlag = DispatchAction.error;
      },
      onCancel: () {
        client.queryCache.dispatch(query.key, DispatchAction.cancelFetch, null);
        actionFlag = DispatchAction.cancelFetch;
      },
    );

    // Refetching is scheduled here after success or error
    final scheduleRefetchActions = [
      DispatchAction.success,
      DispatchAction.error
    ];
    if (scheduleRefetchActions.contains(actionFlag)) {
      scheduleRefetch();
    }
  }

  /// Disposes the observer
  void dispose() {
    client.queryCache.removeListener(hashCode);
    client.queryCache.dismantle(this);
    _resolver.cancel();
    for (var resolver in _refetchResolvers) {
      resolver.cancel();
    }
    _refetchTimer?.cancel();
  }

  /// Schedules the next fetch if the [options.refetchInterval] is set.
  void scheduleRefetch() {
    if (options.refetchInterval == null) return;
    _refetchTimer?.cancel();
    _refetchTimer = Timer(options.refetchInterval as Duration, refetch);
  }
}
