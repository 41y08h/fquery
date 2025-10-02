import 'package:flutter/widgets.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/core/models/query_result.dart';
import 'package:fquery/src/core/observers/queries_observer.dart';

class QueriesInstance {
  static List<QueryResult<TData, TError>> of<TData, TError extends Exception>(
      BuildContext context, List<QueryOptions<TData, TError>> options) {
    final client = QueryClient.of(context);
    final observer = QueriesObserver<TData, TError>(
      client: client,
    );
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

    return queries;
  }
}
