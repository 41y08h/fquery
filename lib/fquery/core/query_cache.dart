import 'package:fquery/fquery/core/query.dart';
import 'package:fquery/fquery/core/query_client.dart';
import 'package:fquery/fquery/core/types.dart';

class QueryCache {
  Map<QueryKey, Query> queriesMap = {};
  List<Query> queries = [];

  Query<TData, TError, TQueryKey>? get<TData, TError, TQueryKey>(
      TQueryKey queryKey) {
    return queriesMap[queryKey] as Query<TData, TError, TQueryKey>?;
  }

  void add(Query query) {
    if (queriesMap.containsKey(query.queryKey)) {
      return;
    }

    queriesMap[query.queryKey] = query;
    queries.add(query);
  }

  Query<TData, TError, TQueryKey> build<TData, TError, TQueryKey>(
      QueryClient client,
      TQueryKey queryKey,
      Future<TData> Function() queryFn) {
    late Query<TData, TError, TQueryKey> query;
    Query? existingQuery = queriesMap[queryKey];
    if (existingQuery != null) {
      query = existingQuery as Query<TData, TError, TQueryKey>;
    } else {
      query = Query<TData, TError, TQueryKey>(
        queryFn: queryFn,
        queryKey: queryKey,
      );
    }

    add(query);
    return query;
  }
}
