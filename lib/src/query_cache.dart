import 'package:flutter/widgets.dart';
import 'package:fquery/src/query.dart';
import 'package:fquery/src/query_client.dart';
import 'package:fquery/src/query_key.dart';

typedef QueriesMap = Map<QueryKey, Query>;

class QueryCache extends ChangeNotifier {
  final QueriesMap _queries = {};
  QueriesMap get queries => _queries;

  Query<TData, TError> get<TData, TError>(QueryKey queryKey) {
    final query = _queries[queryKey];
    if (query == null) {
      throw ArgumentError("Query with given key doesn't exist.");
    }
    return query as Query<TData, TError>;
  }

  void add(QueryKey queryKey, Query query) {
    _queries[queryKey] = query;
    onQueryUpdated();
  }

  void remove(Query query) {
    _queries.removeWhere((key, value) => value == query);
    onQueryUpdated();
  }

  /// Returns a query identified by the query key.
  /// If it doesn't exist already,
  /// creates a new one and adds it to the cache.
  Query<TData, TError> build<TData, TError>({
    required QueryKey queryKey,
    required QueryClient client,
  }) {
    late final Query<TData, TError> query;
    try {
      query = get<TData, TError>(queryKey);
      add(queryKey, query);
    } catch (e) {
      query = Query(client: client, key: queryKey);
      add(queryKey, query);
    }
    return query;
  }

  void onQueryUpdated() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
