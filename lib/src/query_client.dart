import 'types.dart';
import 'query.dart';

class QueryClient {
  final Map<String, Query> queries = {};
  late QueryOptions defaultQueryOptions;

  QueryClient({QueryOptions? defaultQueryOptions}) {
    this.defaultQueryOptions = defaultQueryOptions ?? QueryOptions();
  }

  Query<TData, TError>? getQuery<TData, TError>(String queryKey) {
    return queries[queryKey] as Query<TData, TError>?;
  }

  void addQuery(String queryKey, Query query) {
    queries[queryKey] = query;
  }

  void removeQuery(Query query) {
    queries.removeWhere((key, value) => value == query);
  }

  Query<TData, TError> buildQuery<TData, TError>(String queryKey) {
    var query = getQuery<TData, TError>(queryKey);
    query ??= Query(client: this);
    addQuery(queryKey, query);
    return query;
  }

  void setQueryData<TData>(
      String queryKey, TData Function(TData previous) updater) {
    final query = getQuery(queryKey);
    query?.dispatch(DispatchAction.success, updater(query.state.data));
  }
}
