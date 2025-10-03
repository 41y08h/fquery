import 'package:flutter/widgets.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery_core/fquery_core.dart';
import 'package:fquery_core/models/query.dart';

class InfiniteQueryInstance {
  static InfiniteQueryResult<TData, TError, TPageParam>
      of<TData, TError extends Exception, TPageParam>(BuildContext context,
          InfiniteQueryOptions<TData, TError, TPageParam> options) {
    final cache = CacheProvider.get(context);
    final observer = InfiniteQueryObserver<TData, TError, TPageParam>(
      cache: cache,
      options: options,
      listenToQueryCache: false,
    );

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

      final nextPageParam = options.getNextPageParam(
        lastPage,
        pages,
        lastPageParam,
        pageParams,
      );

      final previousPageParam = options.getNextPageParam(
        firstPage,
        pages,
        firstPageParam,
        pageParams,
      );

      hasNextPage = nextPageParam != null;
      hasPreviousPage = previousPageParam != null;
    }

    final infiniteQuery = InfiniteQueryResult<TData, TError, TPageParam>(
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

    return infiniteQuery;
  }
}
