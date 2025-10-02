import 'package:fquery/src/core/models/query.dart';
import 'package:fquery/src/core/observers/infinite_query_observer.dart';

/// The result of an infinite query, including the pages, page parameters, error, status flags, and functions to fetch more pages.
class InfiniteQueryOptions<TData, TError, TPageParam>
    extends BaseQueryOptions<TData, TError> {
  /// The query function responsible for fetching the query
  final InfiniteQueryFn<TData, TPageParam> queryFn;

  /// The initial page parameter to start fetching from.
  final TPageParam initialPageParam;

  /// Function to get the next page parameter based on the last page, all pages, last page parameter, and all page parameters.
  final TPageParam? Function(
    TData,
    List<TData>,
    TPageParam,
    List<TPageParam>,
  ) getNextPageParam;

  /// Optional function to get the previous page parameter based on the first page, all pages, first page parameter, and all page parameters.
  final TPageParam? Function(
    TData,
    List<TData>,
    TPageParam,
    List<TPageParam>,
  )? getPreviousPageParam;

  /// The maximum number of pages to keep in the cache. If the number of pages exceeds this limit, the oldest page will be removed.
  int? maxPages;

  /// Creates a new instance of [InfiniteQueryOptions].
  InfiniteQueryOptions({
    required super.queryKey,
    required this.queryFn,
    required this.initialPageParam,
    required this.getNextPageParam,
    this.getPreviousPageParam,
    super.cacheDuration,
    super.enabled,
    super.refetchInterval,
    super.refetchOnMount,
    super.retryCount,
    super.retryDelay,
    super.staleDuration,
  });
}
