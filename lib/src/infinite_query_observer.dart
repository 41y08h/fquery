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

  final firstPageResolver = RetryResolver();
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

  // This is called from the [useQuery] hook
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
      fetchFirstPage(
        options.initialPageParam,
        FetchMeta(direction: FetchDirection.forward),
      );
    }
  }

  /// Takes a [UseQueryOptions] and sets the [options] field.
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
          fetchFirstPage(
            options.initialPageParam,
            FetchMeta(direction: FetchDirection.forward),
          );
        }
      } else {
        firstPageResolver.cancel();
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
    final pages = query.state.data?.pages;
    final lastPage = pages?.last;

    final pageParams = query.state.data?.pageParams;
    final lastPageParam = pageParams?.last;

    if (lastPage == null || pages == null) return;
    if (lastPageParam == null || pageParams == null) return;

    final nextPageParam = options.getNextPageParam(
      lastPage,
      pages,
      lastPageParam,
      pageParams,
    );
    if (nextPageParam == null) return;

    fetchFirstPage(
      nextPageParam,
      FetchMeta(direction: FetchDirection.forward),
    );
  }

  void fetchPreviousPage() {
    final pages = query.state.data?.pages;
    final firstPage = pages?.first;

    final pageParams = query.state.data?.pageParams;
    final firstPageParam = pageParams?.first;

    if (firstPage == null || pages == null) return;
    if (firstPageParam == null || pageParams == null) return;

    final previousParam = options.getPreviousPageParam?.call(
      firstPage,
      pages,
      firstPageParam,
      pageParams,
    );
    if (previousParam == null) return;

    fetchFirstPage(
      previousParam,
      FetchMeta(direction: FetchDirection.backward),
    );
  }

  void refetch() {
    final pageParams = query.state.data?.pageParams;

    query.dispatch(DispatchAction.fetch, null);
    refetchResolvers = [];
    pageParams?.forEachIndexed((i, param) async {
      final resolver = RetryResolver();
      refetchResolvers.add(resolver);

      await resolver.resolve<TData>(() => fetcher(param), onResolve: (data) {
        final isLastPage = i + 1 == pageParams.length;
        final newPages = [...(query.state.data?.pages ?? [])];
        newPages[i] = data;

        final newData = query.state.data?.copyWith(pages: [...newPages]);
        final action = isLastPage
            ? DispatchAction.success
            : DispatchAction.refetchSequence;

        query.dispatch(action, newData);
      }, onError: (error) {
        query.dispatch(DispatchAction.refetchError, error);
      }, onCancel: () {
        query.dispatch(DispatchAction.cancelFetch, null);
      });
    });
  }

  /// This is "the" function responsible for fetching the query.
  Future<void> fetchFirstPage(TPageParam pageParam, FetchMeta meta) async {
    query.dispatch(DispatchAction.fetch, meta);
    // Important: State change, then any other
    // function invocation in the following callbacks
    await firstPageResolver.resolve<TData>(() => fetcher(pageParam),
        onResolve: (data) {
      final pages = query.state.data?.pages ?? [];
      final pageParams = query.state.data?.pageParams ?? [];

      final newData = query.state.data?.copyWith(
        pages: meta.direction == FetchDirection.forward
            ? [...pages, data]
            : [data, ...pages],
        pageParams: meta.direction == FetchDirection.forward
            ? [...pageParams, pageParam]
            : [pageParam, ...pageParams],
      );

      query.dispatch(
        DispatchAction.success,
        newData ??
            InfiniteQueryData<TData, TPageParam>(
              pages: [data],
              pageParams: [pageParam],
            ),
      );
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
    firstPageResolver.cancel();
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
