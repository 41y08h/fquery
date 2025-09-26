import 'package:flutter/widgets.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/models/query_result.dart';
import 'package:fquery/src/observers/query_observer.dart';

class QueryInstance {
  static QueryResult<TData, TError> of<TData, TError extends Exception>(
      BuildContext context, QueryOptions<TData, TError> options) {
    final client = QueryClient.of(context);
    final observer = QueryObserver<TData, TError>(
      client: client,
      options: options,
    );
    return QueryResult<TData, TError>(
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
    );
  }
}
