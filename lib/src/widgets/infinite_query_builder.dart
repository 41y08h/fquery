import 'package:flutter/widgets.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/infinite_query_observer.dart';
import 'package:fquery/src/query.dart';
import 'package:fquery/src/query_key.dart';

/// Builder widget for infinite queries
class InfiniteQueryBuilder<TData, TError extends Exception, TPageParam>
    extends StatefulWidget {
  /// The builder function which recevies the [UseInfiniteQueryResult] along with the [BuildContext]
  final Widget Function(
      BuildContext, UseInfiniteQueryResult<TData, TError, TPageParam>) builder;

  /// The query key used to identify the query.
  final RawQueryKey queryKey;

  /// The function that fetches the data for the query.
  final InfiniteQueryFn<TData, TPageParam> queryFn;

  /// The initial page param to be used for the first page
  final TPageParam initialPageParam;

  /// Function to get the next page param
  final TPageParam? Function(
    TData,
    List<TData>,
    TPageParam,
    List<TPageParam>,
  ) getNextPageParam;

  /// Function to get the previous page param
  final TPageParam? Function(
    TData,
    List<TData>,
    TPageParam,
    List<TPageParam>,
  )? getPreviousPageParam;

  /// Maximum number of pages to keep in the cache
  final int? maxPages;

  /// Whether the query is enabled or not
  final bool enabled;

  /// Refetch behavior when the widget is mounted
  final RefetchOnMount? refetchOnMount;

  /// The duration until the data becomes stale.
  final Duration? staleDuration;

  /// The duration until the data is removed from the cache.
  final Duration? cacheDuration;

  /// The interval at which the query will be refetched.
  final Duration? refetchInterval;

  /// The number of retry attempts if the query fails.
  final int? retryCount;

  /// The delay between retry attempts if the query fails.
  final Duration? retryDelay;

  /// Creates a new [InfiniteQueryBuilder] instance.
  const InfiniteQueryBuilder(
    this.queryKey,
    this.queryFn, {
    super.key,
    required this.builder,
    required this.initialPageParam,
    required this.getNextPageParam,
    this.getPreviousPageParam,
    this.maxPages,
    this.enabled = true,
    this.refetchOnMount,
    this.staleDuration,
    this.cacheDuration,
    this.refetchInterval,
    this.retryCount,
    this.retryDelay,
  });

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
      QueryKey(widget.queryKey),
      widget.queryFn,
      client: client,
      options: UseInfiniteQueryOptions<TData, TError, TPageParam>(
        initialPageParam: widget.initialPageParam,
        getNextPageParam: widget.getNextPageParam,
        getPreviousPageParam: widget.getPreviousPageParam,
        maxPages: widget.maxPages,
        enabled: widget.enabled,
        refetchOnMount: widget.refetchOnMount,
        staleDuration: widget.staleDuration,
        cacheDuration: widget.cacheDuration,
        refetchInterval: widget.refetchInterval,
        retryCount: widget.retryCount,
        retryDelay: widget.retryDelay,
      ),
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
      UseInfiniteQueryOptions<TData, TError, TPageParam>(
        initialPageParam: widget.initialPageParam,
        getNextPageParam: widget.getNextPageParam,
        getPreviousPageParam: widget.getPreviousPageParam,
        maxPages: widget.maxPages,
        enabled: widget.enabled,
        refetchOnMount: widget.refetchOnMount,
        staleDuration: widget.staleDuration,
        cacheDuration: widget.cacheDuration,
        refetchInterval: widget.refetchInterval,
        retryCount: widget.retryCount,
        retryDelay: widget.retryDelay,
      ),
    );
  }

  @override
  void dispose() {
    observer.destroy();
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

          final nextPageParam = widget.getNextPageParam(
            lastPage,
            pages,
            lastPageParam,
            pageParams,
          );

          final previousPageParam = widget.getNextPageParam(
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
