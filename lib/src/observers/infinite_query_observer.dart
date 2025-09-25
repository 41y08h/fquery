import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/query.dart';
import 'package:fquery/src/retry_resolver.dart';

/// The result of an infinite query, including the pages, page parameters, error, status flags, and functions to fetch more pages.
class InfiniteQueryOptions<TData, TError, TPageParam>
    extends BaseQueryOptions<TData, TError> {
  /// The query function responsible for fetching the query
  final InfiniteQueryFn<TData, TPageParam> queryFn;

  /// The initial page parameter to start fetching from.
  final TPageParam initialPageParam;

  /// Function to get the next page parameter based on the last page, all pages, last page parameter, and all page parameters.
  final TPageParam? Function(
    TData,
    List<TData>,
    TPageParam,
    List<TPageParam>,
  ) getNextPageParam;

  /// Optional function to get the previous page parameter based on the first page, all pages, first page parameter, and all page parameters.
  final TPageParam? Function(
    TData,
    List<TData>,
    TPageParam,
    List<TPageParam>,
  )? getPreviousPageParam;

  /// The maximum number of pages to keep in the cache. If the number of pages exceeds this limit, the oldest page will be removed.
  int? maxPages;

  /// Creates a new instance of [InfiniteQueryOptions].
  InfiniteQueryOptions({
    required super.queryKey,
    required this.queryFn,
    required this.initialPageParam,
    required this.getNextPageParam,
    this.getPreviousPageParam,
    super.cacheDuration,
    super.enabled,
    super.refetchInterval,
    super.refetchOnMount,
    super.retryCount,
    super.retryDelay,
    super.staleDuration,
  });
}

/// The function used to fetch a page of data in an infinite query.
typedef InfiniteQueryFn<TData, TPageParam> = Future<TData> Function(TPageParam);

/// Observer for infinite queries.
class InfiniteQueryObserver<TData, TError extends Exception, TPageParam>
    extends ChangeNotifier {
  /// The query client used to manage queries.
  final QueryClient client;

  /// The query instance managed by this observer.
  late final Query<InfiniteQueryData<TData, TPageParam>, TError> query;

  /// The options used to configure this observer.
  late InfiniteQueryOptions<TData, TError, TPageParam> options;

  final _resolver = RetryResolver();
  var _refetchResolvers = <RetryResolver>[];
  Timer? _refetchTimer;

  /// Creates a new instance of [InfiniteQueryObserver].
  InfiniteQueryObserver({
    required this.client,
    required this.options,
  }) {
    query =
        client.queryCache.build<InfiniteQueryData<TData, TPageParam>, TError>(
      queryKey: options.queryKey,
      client: client,
    );
    query.setCacheDuration(this.options.cacheDuration);
  }

  void _onQueryUpdated() {
    notifyListeners();
    if (query.state.isInvalidated) {
      refetch();
    }
  }

  /// Initializes the observer
  void initialize() {
    // Subcribe to any query state changes
    query.addListener(_onQueryUpdated);

    // Initiate query on mount
    if (options.enabled == false) return;
    final isRefetching = !query.state.isLoading;
    final isInvalidated = query.state.isInvalidated;

    // [RefetchOnMount] behavior is specified here
    if (isRefetching && !isInvalidated) {
      switch (options.refetchOnMount) {
        case RefetchOnMount.always:
          refetch();
          break;
        case RefetchOnMount.stale:
          DateTime? staleAt =
              query.state.dataUpdatedAt?.add(options.staleDuration);
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

    if (isEnabledChanged) {
      if (options.enabled) {
        if (query.state.isLoading) {
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
    final data = query.state.data;
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
    final data = query.state.data;
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
    if (!options.enabled || query.state.isFetching) {
      return;
    }

    // Can't refetch if there's no data already
    final data = query.state.data;
    if (data == null) return;

    query.dispatch(DispatchAction.fetch, null);
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
          query.dispatch(action, newData);
        },
        onError: (error) {
          query.dispatch(DispatchAction.refetchError, error);
        },
        onCancel: () {
          query.dispatch(DispatchAction.cancelFetch, null);
        },
      );
    });
  }

  /// This is "the" function responsible for fetching the query.
  Future<void> fetch(TPageParam pageParam, FetchMeta meta) async {
    if (!options.enabled || query.state.isFetching) {
      return;
    }

    query.dispatch(DispatchAction.fetch, meta);
    // Important: State change, then any other
    // function invocation in the following callbacks
    DispatchAction actionFlag = DispatchAction.fetch;
    await _resolver.resolve<TData>(
      () => options.queryFn(pageParam),
      retryCount: options.retryCount,
      retryDelay: options.retryDelay,
      onResolve: (data) {
        final pages = [...(query.state.data?.pages ?? [])];
        final pageParams = [...(query.state.data?.pageParams ?? [])];

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
        final newData = query.state.data?.copyWith(
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

        query.dispatch(DispatchAction.success, newData);
        actionFlag = DispatchAction.success;
      },
      onError: (error) {
        query.dispatch(DispatchAction.error, error);
        actionFlag = DispatchAction.error;
      },
      onCancel: () {
        query.dispatch(DispatchAction.cancelFetch, null);
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
  @override
  void dispose() {
    super.dispose();
    query.removeListener(_onQueryUpdated);
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
