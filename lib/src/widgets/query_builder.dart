import 'package:flutter/widgets.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/data_classes/query_result.dart';
import 'package:fquery/src/observers/observer.dart';

/// Builder widget for queries
class QueryBuilder<TData, TError extends Exception> extends StatefulWidget {
  /// The builder function which recevies the [QueryResult] along with the [BuildContext]
  final Widget Function(BuildContext, QueryResult<TData, TError>) builder;

  final QueryOptions<TData, TError> options;

  /// Creates a new [QueryBuilder] instance.
  const QueryBuilder({required this.options, required this.builder});

  @override
  State<QueryBuilder<TData, TError>> createState() =>
      _QueryBuilderState<TData, TError>();
}

class _QueryBuilderState<TData, TError extends Exception>
    extends State<QueryBuilder<TData, TError>> {
  late final client = QueryClient.of(context);
  late Observer<TData, TError> observer;

  Observer<TData, TError> buildObserver() {
    return Observer(
      client: client,
      options: QueryOptions(
        queryKey: widget.options.queryKey,
        queryFn: widget.options.queryFn,
        enabled: widget.options.enabled,
        refetchOnMount: widget.options.refetchOnMount,
        staleDuration: widget.options.staleDuration,
        cacheDuration: widget.options.cacheDuration,
        retryCount: widget.options.retryCount,
        retryDelay: widget.options.retryDelay,
        refetchInterval: widget.options.refetchInterval,
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
      QueryOptions(
        queryKey: widget.options.queryKey,
        queryFn: widget.options.queryFn,
        enabled: widget.options.enabled,
        refetchOnMount: widget.options.refetchOnMount,
        staleDuration: widget.options.staleDuration,
        cacheDuration: widget.options.cacheDuration,
        retryCount: widget.options.retryCount,
        retryDelay: widget.options.retryDelay,
        refetchInterval: widget.options.refetchInterval,
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
        final result = QueryResult<TData, TError>(
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
