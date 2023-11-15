import 'package:flutter/widgets.dart';
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

/// Builds and subscribes to a query stored in the cache.
/// Takes a query key and a fetcher function which either resolves or throws an error.
/// Returns a [UseQueryResult]
///
/// Example:
/// ```dart
/// // These are default configurations
/// final posts = useQuery(
///   ['posts'],
///   getPosts,
///   enabled: true,
///   cacheDuration: const Duration(minutes: 5),
///   refetchInterval: null // The query will not refetch by default,
///   refetchOnMount: RefetchOnMount.stale,
///   staleDuration: const Duration(seconds: 10),
/// );
/// ```
/// - `enabled` - specifies if the query fetcher function is automatically called when the widget renders, can be used for _dependant queries_
/// - `cacheDuration` - specifies the duration unused/inactive cache data remains in memory, the cached data will be garbage collected after this duration. The longest one will be used when different values are specified in multiple instances of the query.
/// - `refetchInterval` - specifies the time interval in which all queries will refetch the data, setting it to `null` (default) will turn off refetching
/// - `refetchOnMount` - specifies the behavior of the query instance when the widget is first built and the data is already available.
///   - `RefetchOnMount.always` - will always refetch when the widget is built.
///   - `RefetchOnMount.stale` - will fetch the data if it is stale (see `staleDuration`)
///   - `RefetchOnMount.never` - will never refetch
/// - `staleDuration` - specifies the duration until the data becomes stale. This value applies to each query instance individually

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
  // and rebuilds the widgets on updates.
  useListenable(observer);

  useEffect(() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      observer.updateOptions(options);
    });
    return null;
  }, [observer, options]);

  useEffect(() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      observer.initialize();
    });
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
