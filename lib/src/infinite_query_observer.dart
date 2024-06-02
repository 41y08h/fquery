import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/query.dart';
import 'package:fquery/src/retry_resolver.dart';
import 'package:fquery/src/query_listener.dart';

class InfiniteQueryOptions<TData, TError, TPageParam>
    extends QueryOptions<TData, TError> {
  final TPageParam initialPageParam;
  final TPageParam? Function(
    TData,
    List<TData>,
    TPageParam,
    List<TPageParam>,
  ) getNextPageParam;
  final TPageParam? Function(
    TData,
    List<TData>,
    TPageParam,
    List<TPageParam>,
  )? getPreviousPageParam;
  int? maxPages;

  InfiniteQueryOptions({
    required this.initialPageParam,
    required this.getNextPageParam,
    this.getPreviousPageParam,
    this.maxPages,
    required super.enabled,
    required super.refetchOnMount,
    required super.staleDuration,
    required super.cacheDuration,
    super.refetchInterval,
    super.retryCount,
    super.retryDelay,
  });
}

typedef InfiniteQueryFn<TData, TPageParam> = Future<TData> Function(TPageParam);

class InfiniteQueryObserver<TData, TError, TPageParam> extends ChangeNotifier
    with QueryListener {
  final QueryKey queryKey;
  final QueryClient client;
  final InfiniteQueryFn<TData, TPageParam> fetcher;
  late final Query<InfiniteQueryData<TData, TPageParam>, TError> query;

  late InfiniteQueryOptions<TData, TError, TPageParam> options;

  final resolver = RetryResolver();
  var refetchResolvers = <RetryResolver>[];
  Timer? refetchTimer;

  InfiniteQueryObserver(
    this.queryKey,
    this.fetcher, {
    required this.client,
    required UseInfiniteQueryOptions<TData, TError, TPageParam> options,
  }) {
    query =
        client.queryCache.build<InfiniteQueryData<TData, TPageParam>, TError>(
      queryKey: queryKey,
      client: client,
    );
    _setOptions(options);
    query.setCacheDuration(this.options.cacheDuration);
  }

  // This is called from the [useInfiniteQuery] hook
  // whenever the first widget build is done
  void initialize() {
    // Subcribe to any query state changes
    query.subscribe(this);

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

  /// Takes a [UseInfiniteQueryOptions] and sets the [options] field.
  /// The [DefaultQueryOptions] from the [QueryClient]
  /// is used if a field is not specified.
  void _setOptions(UseInfiniteQueryOptions<TData, TError, TPageParam> options) {
    this.options = InfiniteQueryOptions<TData, TError, TPageParam>(
      enabled: options.enabled,
      refetchOnMount:
          options.refetchOnMount ?? client.defaultQueryOptions.refetchOnMount,
      staleDuration:
          options.staleDuration ?? client.defaultQueryOptions.staleDuration,
      cacheDuration:
          options.cacheDuration ?? client.defaultQueryOptions.cacheDuration,
      refetchInterval: options.refetchInterval,
      retryCount: options.retryCount,
      retryDelay: options.retryDelay,
      initialPageParam: options.initialPageParam,
      getNextPageParam: options.getNextPageParam,
      getPreviousPageParam: options.getPreviousPageParam,
      maxPages: options.maxPages,
    );
  }

  /// This is usually called from the [useQuery] hook
  /// whenever there is any change in the options
  void updateOptions(
      UseInfiniteQueryOptions<TData, TError, TPageParam> options) {
    // Compare variable changes before calling `_setOptions`
    final refetchIntervalChanged =
        this.options.refetchInterval != options.refetchInterval;
    final isEnabledChanged = this.options.enabled != options.enabled;

    _setOptions(options);

    if (isEnabledChanged) {
      if (options.enabled) {
        if (query.state.isLoading) {
          fetch(
            options.initialPageParam,
            FetchMeta(direction: FetchDirection.forward),
          );
        }
      } else {
        resolver.cancel();
        refetchTimer?.cancel();
      }
    }

    if (options.cacheDuration != null) {
      query.setCacheDuration(options.cacheDuration as Duration);
    }

    if (refetchIntervalChanged) {
      // Schedules the next fetch if the [options.refetchInterval] is set.
      if (options.refetchInterval != null) {
        scheduleRefetch();
      } else {
        refetchTimer?.cancel();
        refetchTimer = null;
      }
    }
  }

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
    refetchResolvers = [];

    pageParams.forEachIndexed((i, param) async {
      final resolver = RetryResolver();
      refetchResolvers.add(resolver);

      await resolver.resolve<TData>(() => fetcher(param),
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
      }, onError: (error) {
        query.dispatch(DispatchAction.refetchError, error);
      }, onCancel: () {
        query.dispatch(DispatchAction.cancelFetch, null);
      });
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
    await resolver.resolve<TData>(() => fetcher(pageParam), onResolve: (data) {
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
    }, onError: (error) {
      query.dispatch(DispatchAction.error, error);
    }, onCancel: () {
      query.dispatch(DispatchAction.cancelFetch, null);
    });
  }

  /// This is called from the [Query] class whenever the query state changes.
  /// It notifies the observers about the change and it also nofities the [useQuery] hook.
  @override
  void onQueryUpdated() {
    notifyListeners();
    if (query.state.isInvalidated) {
      refetch();
    }
  }

  /// This is called from the [useQuery] hook when the widget is unmounted.
  void destroy() {
    query.unsubscribe(this);
    resolver.cancel();
    for (var resolver in refetchResolvers) {
      resolver.cancel();
    }
    refetchTimer?.cancel();
  }

  /// Schedules the next fetch if the [options.refetchInterval] is set.
  @override
  void scheduleRefetch() {
    if (options.refetchInterval == null) return;
    refetchTimer?.cancel();
    refetchTimer = Timer(options.refetchInterval as Duration, refetch);
  }
}
