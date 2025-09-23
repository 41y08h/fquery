import 'package:flutter/widgets.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/observer.dart';
import 'package:fquery/src/query_key.dart';

/// Builder widget for queries
class QueryBuilder<TData, TError extends Exception> extends StatefulWidget {
  /// The builder function which recevies the [UseQueryResult] along with the [BuildContext]
  final Widget Function(BuildContext, UseQueryResult<TData, TError>) builder;

  /// The query key used to identify the query.
  final RawQueryKey queryKey;

  /// The function that fetches the data for the query.
  final QueryFn<TData> queryFn;

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

  /// Creates a new [QueryBuilder] instance.
  const QueryBuilder(
    this.queryKey,
    this.queryFn, {
    super.key,
    required this.builder,
    this.enabled = true,
    this.refetchOnMount,
    this.staleDuration,
    this.cacheDuration,
    this.refetchInterval,
    this.retryCount,
    this.retryDelay,
  });

  @override
  State<QueryBuilder<TData, TError>> createState() =>
      _QueryBuilderState<TData, TError>();
}

class _QueryBuilderState<TData, TError extends Exception>
    extends State<QueryBuilder<TData, TError>> {
  late final client = QueryClient.of(context);
  late Observer<TData, TError> observer;

  Observer<TData, TError> buildObserver() {
    return Observer<TData, TError>(
      QueryKey(widget.queryKey),
      widget.queryFn,
      client: client,
      options: UseQueryOptions(
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
  void didUpdateWidget(covariant QueryBuilder<TData, TError> oldWidget) {
    super.didUpdateWidget(oldWidget);

    observer.updateOptions(
      UseQueryOptions(
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
        final result = UseQueryResult<TData, TError>(
          data: observer.query.state.data,
          dataUpdatedAt: observer.query.state.dataUpdatedAt,
          error: observer.query.state.error,
          errorUpdatedAt: observer.query.state.errorUpdatedAt,
          isError: observer.query.state.isError,
          isLoading: observer.query.state.isLoading,
          isFetching: observer.query.state.isFetching,
          isSuccess: observer.query.state.isSuccess,
          status: observer.query.state.status,
          refetch: observer.fetch,
          isInvalidated: observer.query.state.isInvalidated,
          isRefetchError: observer.query.state.isRefetchError,
        );
        return widget.builder(context, result);
      },
    );
  }
}
