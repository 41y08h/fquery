import 'package:flutter/widgets.dart';
import 'cache_provider.dart';
import 'package:fquery_core/fquery_core.dart';

/// Builder widget for multiple queries
class QueriesBuilder<TData, TError extends Exception> extends StatefulWidget {
  /// The builder function which recevies the [QueryResult] along with the [BuildContext]
  final Widget Function(BuildContext, List<QueryResult<TData, TError>>) builder;

  /// The list of options for each query.
  final List<QueryOptions<TData, TError>> options;

  /// Creates a new [QueriesBuilder] instance.
  const QueriesBuilder({
    required this.options,
    required this.builder,
  });

  @override
  State<QueriesBuilder<TData, TError>> createState() =>
      _QueriesBuilderState<TData, TError>();
}

class _QueriesBuilderState<TData, TError extends Exception>
    extends State<QueriesBuilder<TData, TError>> {
  late final QueryCache cache;
  late QueriesObserver<TData, TError> observer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cache = CacheProvider.get(context);

    observer = QueriesObserver<TData, TError>(cache: cache);
    observer.setOptions(widget.options);
    observer.subscribe(hashCode, () {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant QueriesBuilder<TData, TError> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget != oldWidget) observer.setOptions(widget.options);
  }

  @override
  void dispose() {
    observer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always build intermediate value inside builder
    // to update on every change
    final queries = observer.observers
        .map(
          (observer) => QueryResult(
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
        )
        .toList();

    return widget.builder(context, queries);
  }
}
