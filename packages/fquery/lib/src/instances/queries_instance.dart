import 'package:flutter/widgets.dart';
import '../../fquery.dart';
import 'package:fquery_core/fquery_core.dart';

class QueriesInstance {
  static List<QueryResult<TData, TError>> of<TData, TError extends Exception>(
      BuildContext context, List<QueryOptions<TData, TError>> options) {
    final cache = CacheProvider.get(context);
    final observer = QueriesObserver<TData, TError>(
      cache: cache,
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
