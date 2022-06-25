import 'package:fquery/fquery/query.dart';
import 'package:fquery/fquery/types.dart';

class QueryClient {
  final Map<String, Query> queries = {};
  final QueryClientDefaultOptions? defaultOptions;
  QueryClient({this.defaultOptions});

  Query<TData, TError>? getQuery<TData, TError>(String queryKey) {
    return queries[queryKey] as Query<TData, TError>?;
  }

  void setQuery(String queryKey, Query query) {
    queries[queryKey] = query;
  }

  Query<TData, TError> buildQuery<TData, TError>(String queryKey) {
    var query = getQuery<TData, TError>(queryKey);
    query ??= Query();
    setQuery(queryKey, query);
    return query;
  }

  void setQueryData<TData>(
      String queryKey, TData Function(TData previous) updater) {
    final query = getQuery(queryKey);
    query?.setData(updater);
  }
}
