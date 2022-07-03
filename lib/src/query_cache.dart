import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fquery/src/query.dart';
import 'package:fquery/src/query_client.dart';

class QueryCache {
  final Map<IList<dynamic>, Query> _queries = {};
  Map<IList<dynamic>, Query> get queries => _queries;

  Query<TData, TError>? get<TData, TError>(QueryKey queryKey) {
    return _queries[queryKey.lock] as Query<TData, TError>?;
  }

  void add(QueryKey queryKey, Query query) {
    _queries[queryKey.lock] = query;
  }

  void remove(Query query) {
    _queries.removeWhere((key, value) => value == query);
  }

  /// Returns a query identified by the query key.
  /// If it doesn't exist already,
  /// creates a new one and adds it to the cache.
  Query<TData, TError> build<TData, TError>(
      {required QueryKey queryKey, required QueryClient client}) {
    var query = get<TData, TError>(queryKey);
    query ??= Query(client: client, key: queryKey);
    add(queryKey, query);
    return query;
  }
}
