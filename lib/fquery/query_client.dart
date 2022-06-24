import 'package:fquery/fquery/query.dart';
import 'package:fquery/fquery/types.dart';

class QueryClient {
  final Map<String, Query> queries = {};
  final QueryClientDefaultOptions? defaultOptions;
  QueryClient({this.defaultOptions});

  Query? getQuery<TData, TError>(String queryKey) {
    return queries[queryKey];
  }

  Query addQuery<TData, TError>(String queryKey, Query query) {
    if (queries[queryKey] != null) {
      return queries[queryKey] as Query;
    }
    return queries[queryKey] = query;
  }

  Query buildQuery(
    String queryKey, {
    QueryFn? queryFn,
    Duration staleDuration = Duration.zero,
    Duration? refetchInterval,
    RefetchOnReconnect refetchOnReconnect = RefetchOnReconnect.ifStale,
    dynamic Function(dynamic data)? select,
    dynamic Function(dynamic data)? transform,
    bool enabled = true,
  }) {
    final isQueryFnMissing = (queryFn ?? defaultOptions?.queryFn) == null;
    if (isQueryFnMissing) {
      throw Exception('QueryFn is missing, please provide one');
    }
    var query = getQuery(queryKey);
    query ??= Query(
      client: this,
      queryKey: queryKey,
      queryFn: queryFn,
      transform: transform,
      state: QueryState(
        status: enabled ? QueryStatus.loading : QueryStatus.idle,
      ),
    );

    // Add query to the cache
    return addQuery(queryKey, query);
  }

  void invalidateQueries(List<String> queryKeys) {
    for (var queryKey in queryKeys) {
      final query = getQuery(queryKey);
      query?.invalidate();
    }
  }

  void setQueryData<TData>(
      String queryKey, TData Function(TData previous) updater) {
    final query = getQuery(queryKey);
    query?.setData(updater);
  }
}
