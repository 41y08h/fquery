import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/src/widgets/cache_provider.dart';
import '../use_observable.dart';
import '../use_observable_selector.dart';
import 'package:fquery_core/fquery_core.dart';

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
  QueryFn<TData> queryFn, {
  required BuildContext context,
  // These options must match with the `UseQueryOptions`
  bool enabled = true,
  RefetchOnMount? refetchOnMount,
  Duration? staleDuration,
  Duration? cacheDuration,
  Duration? refetchInterval,
  int? retryCount,
  Duration? retryDelay,
}) {
  final cache = CacheProvider.get(context);
  final observerRef = useRef<QueryObserver<TData, TError>?>(null);
  useEffect(() {
    observerRef.value = QueryObserver<TData, TError>(
      listenToQueryCache: false,
      cache: cache,
      queryFn: queryFn,
      queryKey: QueryKey(queryKey),
      cacheDuration: cacheDuration,
      enabled: enabled,
      refetchInterval: refetchInterval,
      refetchOnMount: refetchOnMount,
      retryCount: retryCount,
      retryDelay: retryDelay,
      staleDuration: staleDuration,
    );
    return;
  }, [QueryKey(queryKey)]);

  // Rebuild observer if the query is changed somehow,
  // typically when the query is removed from the cache.
  final query = useObservableSelector(
    cache,
    () => cache.queries[QueryKey(queryKey)],
  );
  useEffect(() {
    if (query == null) {
      observerRef.value = QueryObserver(
        cache: cache,
        queryFn: queryFn,
        queryKey: QueryKey(queryKey),
        cacheDuration: cacheDuration,
        enabled: enabled,
        listenToQueryCache: true,
        refetchInterval: refetchInterval,
        refetchOnMount: refetchOnMount,
        retryCount: retryCount,
        retryDelay: retryDelay,
        staleDuration: staleDuration,
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
        queryFn: queryFn,
        enabled: enabled,
        refetchOnMount:
            refetchOnMount ?? cache.defaultQueryOptions.refetchOnMount,
        staleDuration: staleDuration ?? cache.defaultQueryOptions.staleDuration,
        cacheDuration: cacheDuration ?? cache.defaultQueryOptions.cacheDuration,
        retryCount: retryCount ?? cache.defaultQueryOptions.retryCount,
        retryDelay: retryDelay ?? cache.defaultQueryOptions.retryDelay,
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
