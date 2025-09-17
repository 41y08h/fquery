import 'package:flutter/widgets.dart';
import 'package:fquery/src/query.dart';
import 'package:fquery/src/query_client.dart';
import 'package:fquery/src/query_key.dart';

typedef QueriesMap = Map<QueryKey, Query>;

class QueryNotFoundException implements Exception {
  final QueryKey queryKey;
  final String message;

  QueryNotFoundException(this.queryKey)
      : message = "Query with key '$queryKey' not found";

  @override
  String toString() => "QueryNotFoundException: $message";
}

class QueryCache extends ChangeNotifier {
  final QueriesMap _queries = {};
  QueriesMap get queries => _queries;

  Query<TData, TError> get<TData, TError extends Exception>(QueryKey queryKey) {
    final query = _queries[queryKey];
    if (query == null) {
      throw QueryNotFoundException(queryKey);
    }
    return query as Query<TData, TError>;
  }

  void add<TData, TError extends Exception>(
      QueryKey queryKey, Query<TData, TError> query) {
    _queries[queryKey] = query;
    onQueryUpdated();
  }

  void remove<TData, TError extends Exception>(Query<TData, TError> query) {
    _queries.removeWhere((key, value) => value == query);
    onQueryUpdated();
  }

  /// Returns a query identified by the query key.
  /// If it doesn't exist already,
  /// creates a new one and adds it to the cache.

  Query<TData, TError> build<TData, TError extends Exception>({
    required QueryKey queryKey,
    required QueryClient client,
  }) {
    late final Query<TData, TError> query;
    try {
      query = get<TData, TError>(queryKey);
      add(queryKey, query);
    } on QueryNotFoundException {
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
