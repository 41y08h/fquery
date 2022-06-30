import 'query.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

class QueryClient {
  final Map<IList<dynamic>, Query> queries = {};
  late QueryOptions defaultQueryOptions;

  QueryClient({QueryOptions? defaultQueryOptions}) {
    this.defaultQueryOptions = defaultQueryOptions ?? QueryOptions();
  }

  Query<TData, TError>? getQuery<TData, TError>(QueryKey queryKey) {
    return queries[queryKey.lock] as Query<TData, TError>?;
  }

  void addQuery(QueryKey queryKey, Query query) {
    queries[queryKey.lock] = query;
  }

  void removeQuery(Query query) {
    queries.removeWhere((key, value) => value == query);
  }

  Query<TData, TError> buildQuery<TData, TError>(QueryKey queryKey) {
    var query = getQuery<TData, TError>(queryKey);
    query ??= Query(client: this, key: queryKey);
    addQuery(queryKey, query);
    return query;
  }

  void setQueryData<TData>(
      QueryKey queryKey, TData Function(TData previous) updater) {
    final query = getQuery(queryKey);
    query?.dispatch(DispatchAction.success, updater(query.state.data));
  }

  void invalidateQueries(QueryKey key) {
    queries.forEach((queryKey, query) {
      // If every element in the [key] matches with
      // the starting elements in the [queryKey],
      // then invalidate the query.
      if (queryKey.length < key.length) {
        return;
      }

      if (queryKey.sublist(0, key.length) == key.lock) {
        query.dispatch(DispatchAction.invalidate, null);
      }
    });
  }
}
