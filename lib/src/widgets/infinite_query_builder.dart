import 'package:flutter/widgets.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/infinite_query_observer.dart';
import 'package:fquery/src/query.dart';

/// Builder widget for infinite queries
class InfiniteQueryBuilder<TData, TError extends Exception, TPageParam>
    extends StatefulWidget {
  /// The builder function which recevies the [UseInfiniteQueryResult] along with the [BuildContext]
  final Widget Function(
      BuildContext, UseInfiniteQueryResult<TData, TError, TPageParam>) builder;

  final InfiniteQueryOptions<TData, TError, TPageParam> config;

  /// Creates a new [InfiniteQueryBuilder] instance.
  const InfiniteQueryBuilder(this.config, {required this.builder});

  @override
  State<InfiniteQueryBuilder<TData, TError, TPageParam>> createState() =>
      _InfiniteQueryBuilderState<TData, TError, TPageParam>();
}

class _InfiniteQueryBuilderState<TData, TError extends Exception, TPageParam>
    extends State<InfiniteQueryBuilder<TData, TError, TPageParam>> {
  late final client = QueryClient.of(context);
  late InfiniteQueryObserver<TData, TError, TPageParam> observer;

  InfiniteQueryObserver<TData, TError, TPageParam> buildObserver() {
    return InfiniteQueryObserver<TData, TError, TPageParam>(
      client: client,
      options: widget.config,
    );
  }

  // Initialization of the observer
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    setState(() {
      observer = buildObserver();
      observer.initialize();
    });
  }

  @override
  void didUpdateWidget(
      covariant InfiniteQueryBuilder<TData, TError, TPageParam> oldWidget) {
    super.didUpdateWidget(oldWidget);

    observer.updateOptions(
      InfiniteQueryOptions(
        queryKey: widget.config.queryKey,
        queryFn: widget.config.queryFn,
        initialPageParam: widget.config.initialPageParam,
        getNextPageParam: widget.config.getNextPageParam,
        enabled: widget.config.enabled,
        refetchOnMount: widget.config.refetchOnMount,
        staleDuration: widget.config.staleDuration,
        cacheDuration: widget.config.cacheDuration,
        retryCount: widget.config.retryCount,
        retryDelay: widget.config.retryDelay,
      ),
    );
  }

  @override
  void dispose() {
    observer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: observer,
      builder: (context, _) {
        final isFetchingNextPage = observer.query.state.isFetching &&
            observer.query.state.fetchMeta?.direction == FetchDirection.forward;
        final isFetchingPreviousPage = observer.query.state.isFetching &&
            observer.query.state.fetchMeta?.direction ==
                FetchDirection.backward;

        final isFetchNextPageError = observer.query.state.isError &&
            observer.query.state.fetchMeta?.direction == FetchDirection.forward;
        final isFetchPreviousPageError = observer.query.state.isError &&
            observer.query.state.fetchMeta?.direction ==
                FetchDirection.backward;

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

          final nextPageParam = widget.config.getNextPageParam(
            lastPage,
            pages,
            lastPageParam,
            pageParams,
          );

          final previousPageParam = widget.config.getNextPageParam(
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

        return widget.builder(
          context,
          infiniteQuery,
        );
      },
    );
  }
}
