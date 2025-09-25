import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/observers/observer.dart';
import 'package:fquery/src/data_classes/query_options.dart';

/// The result of a query, including the data, error, status flags, and a refetch function.
class UseQueryResult<TData, TError> {
  /// The latest data returned by the query, or null if the query has not been successful yet.
  final TData? data;

  /// The time the data was last updated.
  final DateTime? dataUpdatedAt;

  /// The latest error returned by the query, or null if the query has not resulted in an error.
  final TError? error;

  /// The time the error was last updated.
  final DateTime? errorUpdatedAt;

  /// Tells if the query resulted in an error.
  final bool isError;

  /// Tells if the query is currently loading for the first time (no data yet).
  final bool isLoading;

  /// Tells if the query is currently fetching, including background refetches.
  final bool isFetching;

  /// Tells if the query was successful.
  final bool isSuccess;

  /// The current status of the query.
  final QueryStatus status;

  /// The function to manually refetch the query.
  final Future<void> Function() refetch;

  /// Tells if the query has been invalidated and needs to be refetched.
  final bool isInvalidated;

  /// Tells if the last fetch resulted in an error.
  final bool isRefetchError;

  /// Creates a new [UseQueryResult] instance.
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
    required this.isInvalidated,
    required this.isRefetchError,
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
/// - `enabled` - specifies if the query fetcher function is automatically called when the widget renders, can be used for _dependent queries_.
/// - `cacheDuration` - specifies the duration unused/inactive cache data remains in memory; the cached data will be garbage collected after this duration. The longest duration will be used when different values are specified in multiple instances of the query.
/// - `refetchInterval` - specifies the time interval in which all queries will refetch the data, setting it to `null` (default) will turn off refetching
/// - `refetchOnMount` - specifies the behavior of the query instance when the widget is first built and the data is already available.
///   - `RefetchOnMount.always` - will always refetch when the widget is built.
///   - `RefetchOnMount.stale` - will fetch the data if it is stale (see `staleDuration`).
///   - `RefetchOnMount.never` - will never refetch.
/// - `staleDuration` - specifies the duration until the data becomes stale. This value applies to each query instance individually.

UseQueryResult<TData, TError> useQuery<TData, TError extends Exception>(
  RawQueryKey queryKey,
  QueryFn<TData> fetcher, {
  // These options must match with the `UseQueryOptions`
  bool enabled = true,
  RefetchOnMount? refetchOnMount,
  Duration? staleDuration,
  Duration? cacheDuration,
  Duration? refetchInterval,
  int? retryCount,
  Duration? retryDelay,
}) {
  final client = useQueryClient();
  final observerRef = useRef<Observer<TData, TError>?>(null);
  useEffect(() {
    observerRef.value = Observer(
      client: client,
      options: QueryOptions(
        queryKey: QueryKey(queryKey),
        queryFn: fetcher,
        enabled: enabled,
        refetchOnMount:
            refetchOnMount ?? client.defaultQueryOptions.refetchOnMount,
        staleDuration:
            staleDuration ?? client.defaultQueryOptions.staleDuration,
        cacheDuration:
            cacheDuration ?? client.defaultQueryOptions.cacheDuration,
        retryCount: retryCount ?? client.defaultQueryOptions.retryCount,
        retryDelay: retryDelay ?? client.defaultQueryOptions.retryDelay,
      ),
    );
    return;
  }, [QueryKey(queryKey)]);

  // Rebuild observer if the query is changed somehow,
  // typically when the query is removed from the cache.
  final query = useListenableSelector(
    client.queryCache,
    () => client.queryCache.queries[QueryKey(queryKey)],
  );
  useEffect(() {
    if (query == null) {
      observerRef.value = Observer(
        client: client,
        options: QueryOptions(
          queryKey: QueryKey(queryKey),
          queryFn: fetcher,
          enabled: enabled,
          refetchOnMount:
              refetchOnMount ?? client.defaultQueryOptions.refetchOnMount,
          staleDuration:
              staleDuration ?? client.defaultQueryOptions.staleDuration,
          cacheDuration:
              cacheDuration ?? client.defaultQueryOptions.cacheDuration,
          retryCount: retryCount ?? client.defaultQueryOptions.retryCount,
          retryDelay: retryDelay ?? client.defaultQueryOptions.retryDelay,
        ),
      );
    }
    return;
  }, [query]);

  final observer = observerRef.value as Observer<TData, TError>;

  // This subscribes to the observer
  // and rebuilds the widgets on updates.
  useListenable<Observer<TData, TError>>(observer);

  useEffect(() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      observer.updateOptions(QueryOptions(
        queryKey: QueryKey(queryKey),
        queryFn: fetcher,
        enabled: enabled,
        refetchOnMount:
            refetchOnMount ?? client.defaultQueryOptions.refetchOnMount,
        staleDuration:
            staleDuration ?? client.defaultQueryOptions.staleDuration,
        cacheDuration:
            cacheDuration ?? client.defaultQueryOptions.cacheDuration,
        retryCount: retryCount ?? client.defaultQueryOptions.retryCount,
        retryDelay: retryDelay ?? client.defaultQueryOptions.retryDelay,
      ));
    });
    return;
  }, [observer]);

  useEffect(() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      observer.initialize();
    });
    return () {
      observer.dispose();
    };
  }, [observer]);

  return UseQueryResult<TData, TError>(
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
