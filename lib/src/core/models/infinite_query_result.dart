import 'package:fquery/fquery.dart';
import 'package:fquery/src/core/models/query_result.dart';

/// The result of an infinite query, including the data, error, status flags, and a refetch function.
class InfiniteQueryResult<TData, TError extends Exception, TPageParam>
    extends QueryResult<InfiniteQueryData<TData, TPageParam>, TError> {
  /// Tells if the query is currently fetching the next page.
  final bool isFetchingNextPage;

  /// Tells if the query is currently fetching the previous page.
  final bool isFetchingPreviousPage;

  /// Fetches the next page of data.
  final void Function() fetchNextPage;

  /// Fetches the previous page of data.
  final void Function() fetchPreviousPage;

  /// Tells if there is a next page available.
  final bool hasNextPage;

  /// Tells if there is a previous page available.
  final bool hasPreviousPage;

  /// Tells if the query is currently refetching (not counting page fetches).
  final bool isRefetching;

  /// Tells if the last `fetchNextPage` resulted in an error.
  final bool isFetchNextPageError;

  /// Tells if the last `fetchPreviousPage` resulted in an error.
  final bool isFetchPreviousPageError;

  @override
  final bool isRefetchError;

  InfiniteQueryResult({
    required InfiniteQueryData<TData, TPageParam>? data,
    required DateTime? dataUpdatedAt,
    required TError? error,
    required DateTime? errorUpdatedAt,
    required bool isError,
    required bool isLoading,
    required bool isFetching,
    required bool isSuccess,
    required QueryStatus status,
    required void Function() refetch,
    required bool isInvalidated,
    required this.isFetchingNextPage,
    required this.isFetchingPreviousPage,
    required this.fetchNextPage,
    required this.fetchPreviousPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.isRefetching,
    required this.isFetchNextPageError,
    required this.isFetchPreviousPageError,
    required this.isRefetchError,
  }) : super(
          data: data,
          dataUpdatedAt: dataUpdatedAt,
          error: error,
          errorUpdatedAt: errorUpdatedAt,
          isError: isError,
          isLoading: isLoading,
          isFetching: isFetching,
          isSuccess: isSuccess,
          status: status,
          refetch: refetch,
          isInvalidated: isInvalidated,
          isRefetchError: isRefetchError,
        );
}
