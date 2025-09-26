import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/hooks/use_observable.dart';
import 'package:fquery/src/hooks/use_observable_selector.dart';
import 'package:fquery/src/models/query_result.dart';
import 'package:fquery/src/observers/query_observer.dart';

/// Builds and subscribes to a query stored in the cache.
/// Takes a query key and a fetcher function which either resolves or throws an error.
/// Returns a [QueryResult]
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

QueryResult<TData, TError> useQuery<TData, TError extends Exception>(
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
  final observerRef = useRef<QueryObserver<TData, TError>?>(null);
  useEffect(() {
    observerRef.value = QueryObserver(
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
  final query = useObservableSelector(
    client.queryCache,
    () => client.queryCache.queries[QueryKey(queryKey)],
  );
  useEffect(() {
    if (query == null) {
      observerRef.value = QueryObserver(
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

  final observer = observerRef.value as QueryObserver<TData, TError>;

  // This subscribes to the observer
  // and rebuilds the widgets on updates.
  useObservable(observer);

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
