// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:fquery/fquery.dart';
import 'package:fquery/src/infinite_query_observer.dart';
import 'package:fquery/src/query.dart';

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

class UseInfiniteQueryOptions<TData, TError, TPageParam>
    extends UseQueryOptions {
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
  UseInfiniteQueryOptions({
    required this.initialPageParam,
    required this.getNextPageParam,
    this.getPreviousPageParam,
    this.maxPages,
    super.enabled = true,
    super.cacheDuration,
    super.refetchInterval,
    super.refetchOnMount,
    super.retryCount,
    super.retryDelay,
    super.staleDuration,
  });
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
  final bool isFetchingNextPage;
  final bool isFetchingPreviousPage;
  final void Function() fetchNextPage;
  final void Function() fetchPreviousPage;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final bool isRefetching;

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
    required this.isFetchingNextPage,
    required this.isFetchingPreviousPage,
    required this.fetchNextPage,
    required this.fetchPreviousPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.isRefetching,
  });
}

UseInfiniteQueryResult<TData, TError, TPageParam>
    useInfiniteQuery<TData, TError, TPageParam>(
  QueryKey queryKey,
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
  int retryCount = 3,
  Duration retryDelay = const Duration(seconds: 1, milliseconds: 500),
}) {
  final options = useMemoized(
    () => UseInfiniteQueryOptions<TData, TError, TPageParam>(
      initialPageParam: initialPageParam,
      getNextPageParam: getNextPageParam,
      getPreviousPageParam: getPreviousPageParam,
      maxPages: maxPages,
      enabled: enabled,
      refetchOnMount: refetchOnMount,
      staleDuration: staleDuration,
      cacheDuration: cacheDuration,
      refetchInterval: refetchInterval,
      retryCount: retryCount,
      retryDelay: retryDelay,
    ),
    [
      initialPageParam,
      getNextPageParam,
      getPreviousPageParam,
      maxPages,
      enabled,
      refetchOnMount,
      staleDuration,
      cacheDuration,
      refetchInterval,
      retryCount,
      retryDelay,
    ],
  );
  final client = useQueryClient();
  final observer = useMemoized(
    () => InfiniteQueryObserver<TData, TError, TPageParam>(
      queryKey,
      queryFn,
      client: client,
      options: options,
    ),
    [queryKey.lock],
  );

  // This subscribes to the observer
  // and rebuilds the widgets on updates.
  useListenable(observer);

  useEffect(() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      observer.updateOptions(options);
    });
    return null;
  }, [observer, options]);

  useEffect(() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      observer.initialize();
    });
    return () {
      observer.destroy();
    };
  }, [observer]);

  final isFetchingNextPage = observer.query.state.isFetching &&
      observer.query.state.fetchMeta?.direction == FetchDirection.forward;
  final isFetchingPreviousPage = observer.query.state.isFetching &&
      observer.query.state.fetchMeta?.direction == FetchDirection.backward;

  // ************hasNextPage********************
  final pages = observer.query.state.data?.pages;
  final lastPage = pages?.last;

  final pageParams = observer.query.state.data?.pageParams;
  final lastPageParam = pageParams?.last;

  late final bool hasNextPage;
  if (lastPage == null ||
      pages == null ||
      lastPageParam == null ||
      pageParams == null) {
    hasNextPage = false;
  } else {
    final nextPageParam = options.getNextPageParam(
      lastPage,
      pages,
      lastPageParam,
      pageParams,
    );
    hasNextPage = nextPageParam != null;
  }
  // ******************************

  // ************hasPreviousPage********************
  final firstPage = pages?.first;
  final firstPageParam = pageParams?.last;

  late final bool hasPreviousPage;
  if (firstPage == null ||
      pages == null ||
      firstPageParam == null ||
      pageParams == null) {
    hasPreviousPage = false;
  } else {
    final previousPageParam = options.getNextPageParam(
      firstPage,
      pages,
      firstPageParam,
      pageParams,
    );
    hasPreviousPage = previousPageParam != null;
  }
  // ******************************

  return UseInfiniteQueryResult(
    fetchNextPage: observer.fetchNextPage,
    fetchPreviousPage: observer.fetchPreviousPage,
    isFetchingNextPage: isFetchingNextPage,
    isFetchingPreviousPage: isFetchingPreviousPage,
    hasNextPage: hasNextPage,
    hasPreviousPage: hasPreviousPage,
    isRefetching: observer.query.state.isFetching &&
        !isFetchingNextPage &&
        !isFetchingPreviousPage,
    data: observer.query.state.data,
    dataUpdatedAt: observer.query.state.dataUpdatedAt,
    error: observer.query.state.error,
    errorUpdatedAt: observer.query.state.errorUpdatedAt,
    isError: observer.query.state.isError,
    isLoading: observer.query.state.isLoading,
    isFetching: observer.query.state.isFetching,
    isSuccess: observer.query.state.isSuccess,
    status: observer.query.state.status,
  );
}
