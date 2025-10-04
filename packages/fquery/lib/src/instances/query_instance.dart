import 'package:flutter/widgets.dart';
import '../../fquery.dart';
import 'package:fquery_core/fquery_core.dart';

class QueryInstance {
  static QueryResult<TData, TError> of<TData, TError extends Exception>(
      BuildContext context, QueryOptions<TData, TError> options) {
    final cache = CacheProvider.get(context);
    final observer = QueryObserver<TData, TError>(
      listenToQueryCache: false,
      cache: cache,
      queryFn: options.queryFn,
      queryKey: options.queryKey,
      cacheDuration: options.cacheDuration,
      enabled: options.enabled,
      refetchInterval: options.refetchInterval,
      refetchOnMount: options.refetchOnMount,
      retryCount: options.retryCount,
      retryDelay: options.retryDelay,
      staleDuration: options.staleDuration,
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
