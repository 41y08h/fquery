import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/observer.dart';
import 'package:fquery/src/query.dart';

class UseQueryResult<TData, TError> {
  final TData? data;
  final DateTime? dataUpdatedAt;
  final TError? error;
  final DateTime? errorUpdatedAt;
  final bool isError;
  final bool isLoading;
  final bool isFetching;
  final bool isSuccess;
  final QueryStatus status;
  final void Function() refetch;

  UseQueryResult({
    required this.data,
    required this.dataUpdatedAt,
    required this.error,
    required this.errorUpdatedAt,
    required this.isError,
    required this.isLoading,
    required this.isFetching,
    required this.isSuccess,
    required this.status,
    required this.refetch,
  });
}

UseQueryResult<TData, TError> useQuery<TData, TError>(
  QueryKey queryKey,
  Future<TData> Function() fetcher, {
  QueryOptions? options,
}) {
  final client = useQueryClient();

  final queryOptions = useMemoized(
    () => options,
    [
      options?.enabled,
      options?.refetchOnMount,
      options?.cacheDuration,
      options?.staleDuration,
      options?.refetchInterval,
    ],
  );
  final observer = useMemoized(
    () => Observer<TData, TError>(
      queryKey,
      fetcher,
      client: client,
    ),
    [queryKey],
  );
  // This subscribes to the observer
  useListenable(observer);

  // Propagate the options changes to the observer
  useEffect(() {
    if (queryOptions == null) return;
    observer.setOptions(queryOptions);
    return null;
  }, [queryOptions]);

  useEffect(() {
    observer.initialize();

    return () {
      observer.destroy();
    };
  }, []);

  return UseQueryResult(
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
  );
}
