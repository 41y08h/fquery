import 'package:flutter/widgets.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/queries_observer.dart';

/// Builder widget for multiple queries
class QueriesBuilder<TData, TError extends Exception> extends StatefulWidget {
  /// The builder function which recevies the [UseQueryResult] along with the [BuildContext]
  final Widget Function(BuildContext, List<UseQueryResult<TData, TError>>)
      builder;

  /// The list of options for each query.
  final List<UseQueriesOptions<TData, TError>> options;

  /// Creates a new [QueriesBuilder] instance.
  const QueriesBuilder(
    this.options, {
    super.key,
    required this.builder,
  });

  @override
  State<QueriesBuilder<TData, TError>> createState() =>
      _QueriesBuilderState<TData, TError>();
}

class _QueriesBuilderState<TData, TError extends Exception>
    extends State<QueriesBuilder<TData, TError>> {
  late final client = QueryClient.of(context);
  late QueriesObserver<TData, TError> observer;

  // Initialization of the observer
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    setState(() {
      observer = QueriesObserver<TData, TError>(client: client);
      observer.setOptions(widget.options);
    });
  }

  @override
  void didUpdateWidget(covariant QueriesBuilder<TData, TError> oldWidget) {
    super.didUpdateWidget(oldWidget);
    observer.setOptions(widget.options);
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
        // Always build intermediate value inside builder
        // to update on every change
        final queries = observer.observers
            .map(
              (observer) => UseQueryResult(
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
              ),
            )
            .toList();

        return widget.builder(context, queries);
      },
    );
  }
}
