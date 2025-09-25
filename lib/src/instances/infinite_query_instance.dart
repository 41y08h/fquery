import 'package:flutter/widgets.dart';
import 'package:fquery/src/data_classes/infinite_query_options.dart';
import 'package:fquery/src/hooks/use_infinite_query.dart';
import 'package:fquery/src/observers/infinite_query_observer.dart';
import 'package:fquery/src/query.dart';
import 'package:fquery/src/query_client.dart';

class InfiniteQueryInstance {
  static UseInfiniteQueryResult<TData, TError, TPageParam>
      of<TData, TError extends Exception, TPageParam>(BuildContext context,
          InfiniteQueryOptions<TData, TError, TPageParam> options) {
    final client = QueryClient.of(context);
    final observer = InfiniteQueryObserver<TData, TError, TPageParam>(
      client: client,
      options: options,
    );

    final isFetchingNextPage = observer.query.state.isFetching &&
        observer.query.state.fetchMeta?.direction == FetchDirection.forward;
    final isFetchingPreviousPage = observer.query.state.isFetching &&
        observer.query.state.fetchMeta?.direction == FetchDirection.backward;

    final isFetchNextPageError = observer.query.state.isError &&
        observer.query.state.fetchMeta?.direction == FetchDirection.forward;
    final isFetchPreviousPageError = observer.query.state.isError &&
        observer.query.state.fetchMeta?.direction == FetchDirection.backward;

    late final bool hasNextPage;
    late final bool hasPreviousPage;
    final data = observer.query.state.data;

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

    final infiniteQuery = UseInfiniteQueryResult<TData, TError, TPageParam>(
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
      refetch: observer.refetch,
      isFetchNextPageError: isFetchNextPageError,
      isFetchPreviousPageError: isFetchPreviousPageError,
      isInvalidated: observer.query.state.isInvalidated,
      isRefetchError: observer.query.state.isRefetchError,
    );

    return infiniteQuery;
  }
}
