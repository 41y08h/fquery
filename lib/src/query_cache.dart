import 'package:flutter/widgets.dart';
import 'package:fquery/src/query.dart';
import 'package:fquery/src/query_client.dart';
import 'package:fquery/src/data_classes/query_key.dart';

/// A map of query keys to their corresponding queries.
typedef QueriesMap = Map<QueryKey, Query>;

/// Exception thrown when a query with the specified key is not found in the cache.
class QueryNotFoundException implements Exception {
  /// The query key that was not found.
  final QueryKey queryKey;

  /// The error message.
  final String message;

  /// Creates a new [QueryNotFoundException] instance.
  QueryNotFoundException(this.queryKey)
      : message = "Query with key '$queryKey' not found";

  @override
  String toString() => "QueryNotFoundException: $message";
}

/// The cache that holds all the queries.
class QueryCache extends ChangeNotifier {
  final QueriesMap _queries = {};

  /// Returns an unmodifiable view of the queries in the cache.
  QueriesMap get queries => _queries;

  /// Returns a query identified by the query key.
  Query<TData, TError> get<TData, TError extends Exception>(QueryKey queryKey) {
    final query = _queries[queryKey];
    if (query == null) {
      throw QueryNotFoundException(queryKey);
    }
    return query as Query<TData, TError>;
  }

  /// Adds a query to the cache.
  void add<TData, TError extends Exception>(
      QueryKey queryKey, Query<TData, TError> query) {
    _queries[queryKey] = query;
    onQueryUpdated();
  }

  /// Removes a query from the cache.
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

  /// Notifies listeners that the query cache has been updated.
  void onQueryUpdated() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
