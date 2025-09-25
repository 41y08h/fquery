import 'package:flutter/widgets.dart';
import 'package:fquery/src/hooks/use_infinite_query.dart';
import 'package:fquery/src/observers/infinite_query_observer.dart';
import 'package:fquery/src/query.dart';
import 'package:fquery/src/query_client.dart';

class InfiniteQueryInstance<TData, TError extends Exception, TPageParam> {
  final BuildContext context;
  final InfiniteQueryOptions<TData, TError, TPageParam> config;

  late final client;
  late InfiniteQueryObserver<TData, TError, TPageParam> observer;

  /// Creates a new [InfiniteQueryInstance] instance.
  InfiniteQueryInstance(this.context, this.config) {
    client = QueryClient.of(context);
    observer = InfiniteQueryObserver<TData, TError, TPageParam>(
      client: client,
      options: config,
    );
  }

  UseInfiniteQueryResult<TData, TError, TPageParam> get result {
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

      final nextPageParam = config.getNextPageParam(
        lastPage,
        pages,
        lastPageParam,
        pageParams,
      );

      final previousPageParam = config.getNextPageParam(
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
