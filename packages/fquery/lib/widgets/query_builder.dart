import 'package:flutter/widgets.dart';
import 'package:fquery_core/models/query_options.dart';
import 'package:fquery_core/models/query_result.dart';
import 'package:fquery_core/observers/query_observer.dart';
import 'package:fquery_core/query_cache.dart';
import 'cache_provider.dart';

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
  late final QueryCache cache;
  late QueryObserver<TData, TError> observer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cache = CacheProvider.get(context);

    observer = QueryObserver(
      cache: cache,
      queryFn: widget.options.queryFn,
      queryKey: widget.options.queryKey,
      cacheDuration: widget.options.cacheDuration,
      enabled: widget.options.enabled,
      listenToQueryCache: true,
      refetchInterval: widget.options.refetchInterval,
      refetchOnMount: widget.options.refetchOnMount,
      retryCount: widget.options.retryCount,
      retryDelay: widget.options.retryDelay,
      staleDuration: widget.options.staleDuration,
    );

    observer.subscribe(hashCode, () {
      setState(() {});
    });

    observer.initialize();
  }

  @override
  void didUpdateWidget(covariant QueryBuilder<TData, TError> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget != oldWidget) observer.updateOptions(widget.options);
  }

  @override
  void dispose() {
    observer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      QueryResult<TData, TError>(
        data: observer.query.data,
        dataUpdatedAt: observer.query.dataUpdatedAt,
        error: observer.query.error,
        errorUpdatedAt: observer.query.errorUpdatedAt,
        isError: observer.query.isError,
        isLoading: observer.query.isLoading,
        isFetching: observer.query.isFetching,
        isSuccess: observer.query.isSuccess,
        status: observer.query.status,
        refetch: observer.fetch,
        isInvalidated: observer.query.isInvalidated,
        isRefetchError: observer.query.isRefetchError,
      ),
    );
  }
}
