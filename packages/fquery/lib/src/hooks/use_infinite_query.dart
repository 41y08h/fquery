// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/src/use_observable.dart';
import 'package:fquery/src/widgets/cache_provider.dart';
import 'package:fquery_core/fquery_core.dart';

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

/// Used for infinite query!. In addition to `queryKey` and `queryFn`,
/// it requires an `initialPageParam` and `getNextPageParam` option.
/// The query function receives the `pageParam` parameter
/// that can be used to fetch the current page.
///
/// Returns a [InfiniteQueryResult]
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
InfiniteQueryResult<TData, TError, TPageParam>
    useInfiniteQuery<TData, TError extends Exception, TPageParam>(
  RawQueryKey queryKey,
  InfiniteQueryFn<TData, TPageParam> queryFn, {
  required BuildContext context,
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
  final cache = CacheProvider.get(context);
  final observerRef =
      useRef<InfiniteQueryObserver<TData, TError, TPageParam>?>(null);
  useEffect(() {
    observerRef.value = InfiniteQueryObserver<TData, TError, TPageParam>(
      cache: cache,
      queryFn: queryFn,
      queryKey: QueryKey(queryKey),
      cacheDuration: cacheDuration,
      enabled: enabled,
      refetchInterval: refetchInterval,
      refetchOnMount: refetchOnMount,
      retryCount: retryCount,
      retryDelay: retryDelay,
      staleDuration: staleDuration,
      getNextPageParam: getNextPageParam,
      initialPageParam: initialPageParam,
      getPreviousPageParam: getPreviousPageParam,
      maxPages: maxPages,
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
          refetchOnMount: refetchOnMount,
          staleDuration: staleDuration,
          cacheDuration: cacheDuration,
          retryCount: retryCount,
          retryDelay: retryDelay,
        ),
      );
    });
    return null;
  }, [
    observer,
    enabled,
    queryKey,
    cacheDuration,
    refetchInterval,
    refetchOnMount,
    retryCount,
    retryDelay,
    staleDuration
  ]);

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
    final firstPageParam = pageParams.first;
    final lastPageParam = pageParams.last;

    final nextPageParam = getNextPageParam(
      lastPage,
      pages,
      lastPageParam,
      pageParams,
    );

    final previousPageParam = getPreviousPageParam?.call(
      firstPage,
      pages,
      firstPageParam,
      pageParams,
    );

    hasNextPage = nextPageParam != null;
    hasPreviousPage = previousPageParam != null;
  }

  return InfiniteQueryResult(
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
