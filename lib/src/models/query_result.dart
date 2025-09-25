import 'package:fquery/src/models/query.dart';

/// The result of a query, including the data, error, status flags, and a refetch function.
class QueryResult<TData, TError> {
  /// The latest data returned by the query, or null if the query has not been successful yet.
  final TData? data;

  /// The time the data was last updated.
  final DateTime? dataUpdatedAt;

  /// The latest error returned by the query, or null if the query has not resulted in an error.
  final TError? error;

  /// The time the error was last updated.
  final DateTime? errorUpdatedAt;

  /// Tells if the query resulted in an error.
  final bool isError;

  /// Tells if the query is currently loading for the first time (no data yet).
  final bool isLoading;

  /// Tells if the query is currently fetching, including background refetches.
  final bool isFetching;

  /// Tells if the query was successful.
  final bool isSuccess;

  /// The current status of the query.
  final QueryStatus status;

  /// The function to manually refetch the query.
  final Future<void> Function() refetch;

  /// Tells if the query has been invalidated and needs to be refetched.
  final bool isInvalidated;

  /// Tells if the last fetch resulted in an error.
  final bool isRefetchError;

  /// Creates a new [QueryResult] instance.
  QueryResult({
    required this.data,
    required this.dataUpdatedAt,
    required this.error,
    required this.errorUpdatedAt,
    required this.isError,
    required this.isLoading,
    required this.isFetching,
    required this.isSuccess,
    required this.status,
    required this.refetch,
    required this.isInvalidated,
    required this.isRefetchError,
  });
}
