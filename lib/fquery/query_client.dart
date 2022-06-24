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

  Query buildQuery(String queryKey,
      {QueryFn? queryFn, dynamic Function(dynamic data)? transform}) {
    final queryFunction = queryFn ?? defaultOptions?.queryFn;
    if (queryFunction == null) {
      throw Exception('QueryFn is missing, please provide one');
    }
    final existingQuery = getQuery(queryKey);

    return existingQuery ??
        addQuery(
          queryKey,
          Query(
            queryKey: queryKey,
            queryFn: () => queryFunction == defaultOptions?.queryFn
                ? queryFunction(queryKey)
                : queryFunction(),
            transform: transform,
            state: QueryState(),
          ),
        );
  }

  void invalidateQueries(List<String> queryKeys) {
    for (var queryKey in queryKeys) {
      final query = getQuery(queryKey);
      if (query != null) {
        query.invalidate();
      }
    }
  }

  void setQueryData<TData>(
      String queryKey, TData Function(TData previous) updater) {
    final query = getQuery(queryKey);
    query?.setData(updater);
  }
}
