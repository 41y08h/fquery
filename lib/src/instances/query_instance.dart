import 'package:flutter/widgets.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/data_classes/query_result.dart';
import 'package:fquery/src/observers/observer.dart';

class QueryInstance {
  static QueryResult<TData, TError> of<TData, TError extends Exception>(
      BuildContext context, QueryOptions<TData, TError> options) {
    final client = QueryClient.of(context);
    final observer = Observer<TData, TError>(
      client: client,
      options: options,
    );
    return QueryResult<TData, TError>(
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
  }
}
