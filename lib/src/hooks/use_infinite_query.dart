// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:fquery/fquery.dart';
import 'package:fquery/src/hooks/use_observable.dart';
import 'package:fquery/src/models/query.dart';

class InfiniteQueryData<TPage, TPageParam> {
  List<TPage> pages;
  List<TPageParam> pageParams;
  InfiniteQueryData({
    this.pages = const [],
    this.pageParams = const [],
  });

  InfiniteQueryData<TPage, TPageParam> copyWith({
    List<TPage>? pages,
    List<TPageParam>? pageParams,
  }) {
    return InfiniteQueryData<TPage, TPageParam>(
      pages: pages ?? this.pages,
      pageParams: pageParams ?? this.pageParams,
    );
  }
}

class UseInfiniteQueryResult<TData, TError, TPageParam> {
  final InfiniteQueryData<TData, TPageParam>? data;
  final DateTime? dataUpdatedAt;
  final TError? error;
  final DateTime? errorUpdatedAt;
  final bool isError;
  final bool isLoading;
  final bool isFetching;
  final bool isSuccess;
  final QueryStatus status;
  final Function() refetch;
  final bool isFetchingNextPage;
  final bool isFetchingPreviousPage;
  final void Function() fetchNextPage;
  final void Function() fetchPreviousPage;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final bool isRefetching;
  final bool isFetchNextPageError;
  final bool isFetchPreviousPageError;
  final bool isInvalidated;
  final bool isRefetchError;

  UseInfiniteQueryResult({
    this.data,
    this.dataUpdatedAt,
    this.error,
    this.errorUpdatedAt,
    required this.isError,
    required this.isLoading,
    required this.isFetching,
    required this.isSuccess,
    required this.status,
    required this.refetch,
    required this.isFetchingNextPage,
    required this.isFetchingPreviousPage,
    required this.fetchNextPage,
    required this.fetchPreviousPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.isRefetching,
    required this.isFetchNextPageError,
    required this.isFetchPreviousPageError,
    required this.isInvalidated,
    required this.isRefetchError,
  });
}

/// Used for infinite query. In addition to `queryKey` and `queryFn`,
/// it requires an `initialPageParam` and `getNextPageParam` option.
/// The query function receives the `pageParam` parameter
/// that can be used to fetch the current page.
///
/// Returns a [UseInfiniteQueryResult]
///
/// Example:
/// ```dart
/// final items = useInfiniteQuery<PageResult, Error, int>(
///   ['infinity'],
///   (page) => infinityAPI.get(page),
///   initialPageParam: 1,
///   getNextPageParam: ((lastPage, allPages, lastPageParam, allPageParam) {
///     return lastPage.hasMore ? lastPage.page + 1 : null;
///   }),
/// );
/// ```
UseInfiniteQueryResult<TData, TError, TPageParam>
    useInfiniteQuery<TData, TError extends Exception, TPageParam>(
  RawQueryKey queryKey,
  InfiniteQueryFn<TData, TPageParam> queryFn, {
  required TPageParam initialPageParam,
  required TPageParam? Function(
    TData,
    List<TData>,
    TPageParam,
    List<TPageParam>,
  ) getNextPageParam,
  TPageParam? Function(
    TData,
    List<TData>,
    TPageParam,
    List<TPageParam>,
  )? getPreviousPageParam,
  int? maxPages,
  bool enabled = true,
  RefetchOnMount? refetchOnMount,
  Duration? staleDuration,
  Duration? cacheDuration,
  Duration? refetchInterval,
  int? retryCount,
  Duration? retryDelay,
}) {
  final client = useQueryClient();
  final observerRef =
      useRef<InfiniteQueryObserver<TData, TError, TPageParam>?>(null);
  useEffect(() {
    observerRef.value = InfiniteQueryObserver(
      client: client,
      options: InfiniteQueryOptions(
        queryKey: QueryKey(queryKey),
        queryFn: queryFn,
        enabled: enabled,
        getNextPageParam: getNextPageParam,
        initialPageParam: initialPageParam,
        getPreviousPageParam: getPreviousPageParam,
        refetchInterval: refetchInterval,
        refetchOnMount:
            refetchOnMount ?? client.defaultQueryOptions.refetchOnMount,
        staleDuration:
            staleDuration ?? client.defaultQueryOptions.staleDuration,
        cacheDuration:
            cacheDuration ?? client.defaultQueryOptions.cacheDuration,
        retryCount: retryCount ?? client.defaultQueryOptions.retryCount,
        retryDelay: retryDelay ?? client.defaultQueryOptions.retryDelay,
      ),
    );
    return;
  }, [QueryKey(queryKey)]);

  final observer =
      observerRef.value as InfiniteQueryObserver<TData, TError, TPageParam>;

  // This subscribes to the observer
  // and rebuilds the widgets on updates.
  useObservable(observer);

  useEffect(() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      observer.updateOptions(
        InfiniteQueryOptions(
          queryKey: QueryKey(queryKey),
          queryFn: queryFn,
          enabled: enabled,
          getNextPageParam: getNextPageParam,
          initialPageParam: initialPageParam,
          getPreviousPageParam: getPreviousPageParam,
          refetchInterval: refetchInterval,
          refetchOnMount:
              refetchOnMount ?? client.defaultQueryOptions.refetchOnMount,
          staleDuration:
              staleDuration ?? client.defaultQueryOptions.staleDuration,
          cacheDuration:
              cacheDuration ?? client.defaultQueryOptions.cacheDuration,
          retryCount: retryCount ?? client.defaultQueryOptions.retryCount,
          retryDelay: retryDelay ?? client.defaultQueryOptions.retryDelay,
        ),
      );
    });
    return null;
  }, [observer]);

  useEffect(() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      observer.initialize();
    });
    return () {
      observer.dispose();
    };
  }, [observer]);

  final isFetchingNextPage = observer.query.isFetching &&
      observer.query.fetchMeta?.direction == FetchDirection.forward;
  final isFetchingPreviousPage = observer.query.isFetching &&
      observer.query.fetchMeta?.direction == FetchDirection.backward;

  final isFetchNextPageError = observer.query.isError &&
      observer.query.fetchMeta?.direction == FetchDirection.forward;
  final isFetchPreviousPageError = observer.query.isError &&
      observer.query.fetchMeta?.direction == FetchDirection.backward;

  late final bool hasNextPage;
  late final bool hasPreviousPage;
  final data = observer.query.data;

  if (data == null) {
    hasNextPage = false;
    hasPreviousPage = false;
  } else {
    final pages = data.pages;
    final firstPage = pages.first;
    final lastPage = pages.last;
    final pageParams = data.pageParams;
    final firstPageParam = pageParams.last;
    final lastPageParam = pageParams.last;

    final nextPageParam = getNextPageParam(
      lastPage,
      pages,
      lastPageParam,
      pageParams,
    );

    final previousPageParam = getNextPageParam(
      firstPage,
      pages,
      firstPageParam,
      pageParams,
    );

    hasNextPage = nextPageParam != null;
    hasPreviousPage = previousPageParam != null;
  }

  return UseInfiniteQueryResult(
    fetchNextPage: observer.fetchNextPage,
    fetchPreviousPage: observer.fetchPreviousPage,
    isFetchingNextPage: isFetchingNextPage,
    isFetchingPreviousPage: isFetchingPreviousPage,
    hasNextPage: hasNextPage,
    hasPreviousPage: hasPreviousPage,
    isRefetching: observer.query.isFetching &&
        !isFetchingNextPage &&
        !isFetchingPreviousPage,
    data: observer.query.data,
    dataUpdatedAt: observer.query.dataUpdatedAt,
    error: observer.query.error,
    errorUpdatedAt: observer.query.errorUpdatedAt,
    isError: observer.query.isError,
    isLoading: observer.query.isLoading,
    isFetching: observer.query.isFetching,
    isSuccess: observer.query.isSuccess,
    status: observer.query.status,
    refetch: observer.refetch,
    isFetchNextPageError: isFetchNextPageError,
    isFetchPreviousPageError: isFetchPreviousPageError,
    isInvalidated: observer.query.isInvalidated,
    isRefetchError: observer.query.isRefetchError,
  );
}
