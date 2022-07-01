import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/observer.dart';
import 'package:fquery/src/query.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

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

class UseQueryOptions {
  final bool enabled;
  final RefetchOnMount? refetchOnMount;
  final Duration? staleDuration;
  final Duration? cacheDuration;
  final Duration? refetchInterval;

  UseQueryOptions({
    required this.enabled,
    this.refetchOnMount,
    this.staleDuration,
    this.cacheDuration,
    this.refetchInterval,
  });
}

UseQueryResult<TData, TError> useQuery<TData, TError>(
  QueryKey queryKey,
  Future<TData> Function() fetcher, {
  // These options must match with the `UseQueryOptions`
  bool enabled = true,
  RefetchOnMount? refetchOnMount,
  Duration? staleDuration,
  Duration? cacheDuration,
  Duration? refetchInterval,
}) {
  final options = useMemoized(
    () => UseQueryOptions(
      enabled: enabled,
      refetchOnMount: refetchOnMount,
      staleDuration: staleDuration,
      cacheDuration: cacheDuration,
      refetchInterval: refetchInterval,
    ),
    [
      enabled,
      refetchOnMount,
      staleDuration,
      cacheDuration,
      refetchInterval,
    ],
  );
  final client = useQueryClient();
  final observer = useMemoized(
    () => Observer<TData, TError>(
      queryKey,
      fetcher,
      client: client,
      options: options,
    ),
    [queryKey.lock],
  );

  // This subscribes to the observer
  useListenable(observer);

  // Propagate the options changes to the observer
  useEffect(() {
    observer.updateOptions(options);
    return null;
  }, [observer, options]);

  useEffect(() {
    observer.initialize();
    return () {
      observer.destroy();
    };
  }, [observer]);

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
